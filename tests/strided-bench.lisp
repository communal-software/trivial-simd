(require :asdf)
(unless (find-package :ql)
  (dolist (candidate '("quicklisp/setup.lisp" ".roswell/lisp/quicklisp/setup.lisp"))
    (let ((path (merge-pathnames candidate (user-homedir-pathname))))
      (when (probe-file path) (load path) (return)))))
(let ((root (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
  (asdf:initialize-source-registry `(:source-registry (:directory ,root) :inherit-configuration)))
(asdf:load-system "trivial-simd")
(load (merge-pathnames "benchmark-timing.lisp" *load-truename*))

(defun strided-benchmark (function baseline)
  (let ((dispatch (symbol-function 'trivial-simd::direct-strided-p)))
    (unwind-protect
         (progn
           (when baseline (setf (symbol-function 'trivial-simd::direct-strided-p) (constantly nil)))
           (let ((time (benchmark-time function))
                 #+sbcl (before (sb-ext:get-bytes-consed)))
             (dotimes (i 1000) (funcall function))
             (values time #+sbcl (/ (- (sb-ext:get-bytes-consed) before) 1000d0) #-sbcl nil)))
      (setf (symbol-function 'trivial-simd::direct-strided-p) dispatch))))

(when (uiop:getenv "TRIVIAL_SIMD_STRIDED_PROFILE")
  (load (merge-pathnames "strided-memory-profile.lisp" *load-truename*))
  (uiop:quit))

(format t "mode,operation,count,stride,baseline_us,direct_us,speedup,baseline_bytes,direct_bytes~%")
(let ((trivial-simd::*backend* :native))
  (dolist (mode '(:pointer :copy))
    (let ((trivial-simd::*native-array-access* mode))
      (dolist (count '(1024 65536))
        (let ((a (make-array (* count 3) :element-type 'single-float :initial-element 1f0))
              (b (make-array (* count 3) :element-type 'single-float :initial-element 2f0))
              (out (make-array (* count 3) :element-type 'single-float :initial-element 0f0))
              (mask (make-array (* count 3) :element-type '(unsigned-byte 8) :initial-element 255))
              (double (make-array (* count 3) :element-type 'double-float :initial-element 0d0)))
          (dolist (stride (if (uiop:getenv "TRIVIAL_SIMD_STRIDED_QUICK") '(2) '(1 -1 2 -2 3 -3)))
            (let ((offset (if (minusp stride) (* (1- count) (- stride)) 0)))
              (dolist (operation (if (uiop:getenv "TRIVIAL_SIMD_STRIDED_QUICK") '(:sum :add) '(:sum :add :dot :axpy :copy :mask :convert)))
                (let ((function
                        (case operation
                          (:sum (lambda () (trivial-simd:sum a :end count :input-start offset :stride stride)))
                          (:add (lambda () (trivial-simd:add! out a b :end count :destination-start offset
                                                            :left-start offset :right-start offset :stride stride)))
                          (:dot (lambda () (trivial-simd:dot a b :end count :left-start offset :right-start offset :stride stride)))
                          (:axpy (lambda () (trivial-simd:axpy! out 0.5f0 a :end count :y-start offset :x-start offset :stride stride)))
                          (:copy (lambda () (trivial-simd:copy! out a :end count :destination-start offset
                                                              :source-start offset :stride stride)))
                          (:mask (lambda () (trivial-simd:count mask :end count :mask-start offset :stride stride)))
                          (:convert (lambda () (trivial-simd:convert! double a :end count :destination-start offset
                                                                    :input-start offset :stride stride))))))
                  (multiple-value-bind (baseline baseline-bytes) (strided-benchmark function t)
                    (multiple-value-bind (direct direct-bytes) (strided-benchmark function nil)
                      (format t "~(~A~),~(~A~),~D,~D,~,3F,~,3F,~,3F,~,1F,~,1F~%"
                              mode operation count stride baseline direct (/ baseline (max 0.001d0 direct))
                              baseline-bytes direct-bytes)
                      (finish-output))))))))))))
