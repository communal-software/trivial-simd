(in-package #:cl-user)

;; CFFI compiler macros otherwise bypass the profiling function bindings.
(dolist (name '(trivial-simd::%native-strided-execute trivial-simd::%native-strided-reduce))
  (setf (compiler-macro-function name) nil))
(declaim (notinline trivial-simd::%native-strided-execute trivial-simd::%native-strided-reduce))
(let ((source (merge-pathnames "../strided-execution.lisp"
                              (uiop:pathname-directory-pathname *load-truename*))))
  (uiop:with-temporary-file (:pathname fasl :type "fasl")
    (load (compile-file source :output-file fasl))))

(defun strided-profile-bindings (variant function)
  (if (member variant '("dispatch" "gathered") :test #'string=)
      (if (string= variant "gathered")
          (let ((old (symbol-function 'trivial-simd::direct-strided-p)))
            (unwind-protect
                 (progn (setf (symbol-function 'trivial-simd::direct-strided-p) (constantly nil))
                        (funcall function))
              (setf (symbol-function 'trivial-simd::direct-strided-p) old)))
          (funcall function))
      (let* ((name (case (uiop:operating-system)
                     (:macosx (format nil "build/libnative_strided_~A.dylib" variant))
                     (:linux (format nil "build/libnative_strided_~A.so" variant))
                     ((:windows :win) (format nil "build/native_strided_~A.dll" variant))))
             (path (merge-pathnames name (asdf:system-source-directory :trivial-simd)))
             (library (cffi:load-foreign-library path))
             (execute (cffi:foreign-symbol-pointer (format nil "ts_strided_~A_execute" variant) :library library))
             (reduce (cffi:foreign-symbol-pointer (format nil "ts_strided_~A_reduce" variant) :library library))
             (old-execute (symbol-function 'trivial-simd::%native-strided-execute))
             (old-reduce (symbol-function 'trivial-simd::%native-strided-reduce)))
        (assert (not (cffi:pointer-eq execute (cffi:foreign-symbol-pointer "ts_strided_execute"))))
        (unwind-protect
             (progn
               (setf (symbol-function 'trivial-simd::%native-strided-execute)
                     (lambda (op type destination input comparison rounding count steps pointers)
                       (cffi:foreign-funcall-pointer execute ()
                         :uint op :uint type :uint destination :uint input :uint comparison
                         :int rounding :size count :pointer steps :pointer pointers :int))
                     (symbol-function 'trivial-simd::%native-strided-reduce)
                     (lambda (op type count left right ls rs wide result wide-result index)
                       (cffi:foreign-funcall-pointer reduce ()
                         :uint op :uint type :size count :pointer left :pointer right
                         :int64 ls :int64 rs :int wide :pointer result :pointer wide-result :pointer index :int)))
               (funcall function))
          (setf (symbol-function 'trivial-simd::%native-strided-execute) old-execute
                (symbol-function 'trivial-simd::%native-strided-reduce) old-reduce)
          (cffi:close-foreign-library library)))))

(defun strided-profile-time (function)
  (funcall function)
  (let ((iterations 1)
        (minimum (max 1 (ceiling (* 0.005d0 internal-time-units-per-second)))))
    (loop while (< (benchmark-batch function iterations) minimum)
          do (setf iterations (* iterations 2)))
    (second (sort (loop repeat 3 collect
                   (/ (* 1000000d0 (benchmark-batch function iterations))
                      internal-time-units-per-second iterations)) #'<))))

(defun strided-profile-call (operation out a b count starts steps)
  (destructuring-bind (ds ls rs cs) starts
    (destructuring-bind (d l r c) steps
      (let ((simd (find-package :trivial-simd))
            (one (if (eq (trivial-simd::vector-type out) :f64) 1d0 1f0))
            (zero (if (eq (trivial-simd::vector-type out) :f64) 0d0 0f0)))
        (case operation
          ((:sum :sum-wide)
           (lambda () (trivial-simd:sum a :end count :input-start ls :stride l
                                      :accumulate (if (eq operation :sum-wide) :f64 nil))))
          ((:dot :dot-wide)
           (lambda () (trivial-simd:dot a b :end count :left-start ls :right-start rs
                                      :left-stride l :right-stride r
                                      :accumulate (if (eq operation :dot-wide) :f64 nil))))
          (:scale (lambda () (trivial-simd:scale! out one :end (+ ds count) :start ds :stride d)))
          (:axpy (lambda () (trivial-simd:axpy! out zero a :end count :y-start ds :x-start rs
                                              :y-stride d :x-stride r)))
          (:fma (lambda () (trivial-simd:fma! out a b a :end count :destination-start ds
                                           :x-start ls :y-start rs :z-start cs
                                           :destination-stride d :x-stride l :y-stride r :z-stride c)))
          (otherwise
           (let ((function (symbol-function (find-symbol (format nil "~A!" (if (eq operation :add-scalar) :add operation)) simd))))
             (if (member operation '(:negate :abs))
                 (lambda () (funcall function out a :end count :destination-start ds :input-start ls
                                                   :destination-stride d :input-stride l))
                 (lambda () (funcall function out a (if (eq operation :add-scalar) one b) :end count :destination-start ds
                                                     :left-start ls :right-start (unless (eq operation :add-scalar) rs)
                                                     :destination-stride d :left-stride l
                                                     :right-stride (unless (eq operation :add-scalar) r)))))))))))

(defun strided-profile-steps (operation layout)
  (let ((steps (copy-list layout)))
    (case operation
      ((:sum :sum-wide) (setf (first steps) 1 (third steps) 1 (fourth steps) 1))
      ((:dot :dot-wide) (setf (first steps) 1 (fourth steps) 1))
      (:add-scalar (setf (third steps) 0 (fourth steps) 1))
      ((:negate :abs) (setf (third steps) 1 (fourth steps) 1))
      (:scale (setf (second steps) 0 (third steps) 1 (fourth steps) 1))
      (:axpy (setf (second steps) 0 (fourth steps) 1))
      (:fma)
      (otherwise (setf (fourth steps) 1)))
    steps))

(defun strided-profile-selected-p (gates code operation steps)
  (or (null gates)
      (find-if (lambda (entry) (and (eq code (first entry)) (eq operation (second entry))
                                    (equal steps (third entry)))) gates)
      (and (some (lambda (entry) (and (eq code (first entry)) (eq operation (second entry)))) gates)
           (or (every (lambda (step) (<= 0 step 1)) steps)
               (some (lambda (step) (> (abs step) 2)) steps)))))

(defun strided-profile-run ()
  (let ((variant (or (uiop:getenv "TRIVIAL_SIMD_STRIDED_VARIANT") "dispatch"))
        (trial (or (uiop:getenv "TRIVIAL_SIMD_STRIDED_TRIAL") "0"))
        (output (uiop:getenv "TRIVIAL_SIMD_STRIDED_OUTPUT"))
        (quick (uiop:getenv "TRIVIAL_SIMD_STRIDED_QUICK"))
        (gates (when (uiop:getenv "TRIVIAL_SIMD_STRIDED_GATES")
                 (let ((*read-eval* nil))
                   (read-from-string (uiop:read-file-string (uiop:getenv "TRIVIAL_SIMD_STRIDED_GATES"))))))
        (trivial-simd::*backend* :native))
    (assert output () "Set TRIVIAL_SIMD_STRIDED_OUTPUT to a CSV path")
    (format t "~&Strided ~A trial ~A: ~A ~A, ~A~%" variant trial
            (lisp-implementation-type) (lisp-implementation-version) (machine-type))
    (with-open-file (stream output :direction :output :if-exists :supersede)
      (format stream "variant,trial,type,operation,count,d,left,right,c,mode,offset,time_us,bytes~%")
      (strided-profile-bindings variant
        (lambda ()
          (dolist (type '(single-float double-float))
            (dolist (count (if quick '(1024 65536) '(16 64 256 1024 4096 16384 65536)))
              (let ((size (+ 4 (* 3 count))))
                (dolist (mode (cond (gates '(:pointer :copy :view :alias))
                                     ((or quick (member count '(1024 65536))) '(:pointer :copy :view))
                                     (t '(:pointer))))
                  (let ((trivial-simd::*native-array-access* (if (eq mode :copy) :copy :pointer)))
                    (cffi:with-foreign-objects ((ap (if (eq type 'single-float) :float :double) size)
                                                (bp (if (eq type 'single-float) :float :double) size)
                                                (op (if (eq type 'single-float) :float :double) size))
                      (let* ((code (if (eq type 'single-float) :f32 :f64))
                             (a (if (eq mode :view) (trivial-simd:make-vector-view ap code size)
                                    (make-array size :element-type type)))
                             (b (if (eq mode :view) (trivial-simd:make-vector-view bp code size)
                                    (make-array size :element-type type)))
                             (out (cond ((eq mode :alias) a)
                                        ((eq mode :view) (trivial-simd:make-vector-view op code size))
                                        (t (make-array size :element-type type)))))
                        (dotimes (i size)
                          (setf (trivial-simd::vector-ref a i) (coerce (+ 1 (* 0.125 (mod i 7))) type)
                                (trivial-simd::vector-ref b i) (coerce (if (eq mode :alias) 1 2) type)
                                (trivial-simd::vector-ref out i) (coerce 0 type)))
                        (dolist (offset '(0 1))
                          (dolist (operation (if quick '(:add :sum :dot :axpy)
                                                '(:add :add-scalar :subtract :multiply :divide :negate :abs :min :max
                                                  :scale :axpy :fma :sum :dot :sum-wide :dot-wide)))
                            (unless (and (eq type 'double-float) (member operation '(:sum-wide :dot-wide)))
                              (let ((seen nil))
                                (dolist (layout '((-1 -1 -1 -1) (2 2 2 2) (-2 -2 -2 -2)
                                                  (1 -1 2 -2) (2 -1 1 2) (1 1 1 1) (3 -3 3 -3)))
                                  (let ((steps (strided-profile-steps operation layout)))
                                    (unless (or (member steps seen :test #'equal)
                                                (not (strided-profile-selected-p gates code operation steps)))
                                      (push steps seen)
                                      (when (eq mode :alias) (fill a (coerce 0 type)))
                                      (let* ((starts (mapcar (lambda (s) (+ offset (if (minusp s) (* (1- count) (- s)) 0))) steps))
                                             (function (strided-profile-call operation out a b count starts steps))
                                             (time (strided-profile-time function))
                                             (before #+sbcl (sb-ext:get-bytes-consed) #-sbcl 0))
                                        (dotimes (i 32) (funcall function))
                                        (format stream "~A,~A,~(~A~),~(~A~),~D,~{~D,~}~(~A~),~D,~,6F,~,1F~%"
                                                variant trial code operation count steps mode offset time
                                                #+sbcl (/ (- (sb-ext:get-bytes-consed) before) 32d0) #-sbcl 0))))))))))))))
              (finish-output stream)
              (format t "~&~A ~D complete~%" type count))))))))

(when (uiop:getenv "TRIVIAL_SIMD_STRIDED_PROFILE") (strided-profile-run))
