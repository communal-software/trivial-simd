(require :asdf)
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(defparameter *sharing-root*
  (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:initialize-source-registry `(:source-registry (:directory ,*sharing-root*) :inherit-configuration))
(asdf:load-system "trivial-simd")
(load (merge-pathnames "tests/benchmark-timing.lisp" *sharing-root*))
(defvar *sharing-profile-function*)

(defun sharing-selection-tree (depth)
  (if (zerop depth) 'a
      `(trivial-simd:select (> a b)
                            ,(sharing-selection-tree (1- depth))
                            ,(if (= depth 1) 'b (sharing-selection-tree (1- depth))))))

(defparameter *sharing-workloads*
  (list (list "repeated" `(trivial-simd:count (> ,(sharing-selection-tree 7) b)) nil)
        (list "nonrepeated" '(trivial-simd:count (> (trivial-simd:select (> a b) a b) b)) nil)
        (list "arithmetic-control" '(trivial-simd:count
                                      (> (trivial-simd:select (> (+ a b) (- a b)) (* a b) (- b a)) b)) nil)
        (list "lazy-repeated" '(trivial-simd:sum
                                 (trivial-simd:select (> a b) (+ (* a b) (* a b)) (+ (+ a b) (+ a b)))) t)
        (list "lazy-control" '(trivial-simd:sum (trivial-simd:select (> a b) a b)) t)))

(defun sharing-traffic (expression lazy type a b share-p)
  (multiple-value-bind (code constants slots)
      (trivial-simd::lower-kernel
       (trivial-simd::mask-kernel-tree (second expression) '(a b))
       :lazy-select-p lazy :share-p share-p)
    (let ((program (trivial-simd::make-native-program
                    (trivial-simd::kernel-bytes code) constants slots type)))
      (trivial-simd::with-vector-pointer (pa a)
        (trivial-simd::with-vector-pointer (pb b)
          (cffi:with-foreign-objects ((inputs :pointer 2) (allocations :size) (reads :size) (writes :size))
            (setf (cffi:mem-aref inputs :pointer 0) pa (cffi:mem-aref inputs :pointer 1) pb)
            (let ((status (cffi:foreign-funcall-pointer
                           *sharing-profile-function* ()
                           :pointer (trivial-simd::native-program-code program)
                           :size (trivial-simd::native-program-code-length program)
                           :pointer (trivial-simd::native-program-constants program)
                           :pointer inputs :size (length a) :size slots
                           :uint (position type trivial-simd::*numeric-types* :key #'first)
                           :int (if lazy 1 0)
                           :pointer allocations :pointer reads :pointer writes :int)))
              (assert (zerop status))
              (assert (= (cffi:mem-ref allocations :size)
                         (if (and (plusp slots) (plusp (length a))) 1 0)))
              (format t ",~D,~D,~D,~D,~D,~D,~D"
                      (length code) (count :spill code :key #'first) (count :reload code :key #'first)
                      (* slots 256 (/ (fourth (trivial-simd::numeric-type type)) 8))
                      (cffi:mem-ref allocations :size) (cffi:mem-ref reads :size) (cffi:mem-ref writes :size))))))
      (trivial-simd::keep-native-program-alive program))))

(defparameter *sharing-profile-library*
  (cffi:load-foreign-library
   (or (uiop:getenv "TRIVIAL_SIMD_SHARING_PROFILE_LIBRARY")
       (merge-pathnames "build/libnative_kernel_sharing_profile.dylib" *sharing-root*))))
(defparameter *sharing-profile-function*
  (cffi:foreign-symbol-pointer "ts_sharing_profile" :library *sharing-profile-library*))

(let ((trivial-simd::*inline-small-arrays* nil)
      (trivial-simd::*native-mask-reducer-minimum-count* 0)
      (trial (parse-integer (or (uiop:getenv "SHARING_PROFILE_TRIAL") "0"))))
  (format t "~A ~A ~A~%" (lisp-implementation-type) (lisp-implementation-version) (machine-type))
  (format t "workload,type,elements,access,method,us,instructions,spills,reloads,scratch_bytes,allocations,scratch_copy_read_bytes,scratch_copy_write_bytes~%")
  (dolist (workload *sharing-workloads*)
    (destructuring-bind (label expression lazy) workload
      (dolist (sharing '(nil t))
        (let ((trivial-simd::*native-mask-sharing-p* sharing))
          (eval `(trivial-simd:define-kernel ,(if sharing 'sharing-candidate 'sharing-baseline)
                   (a b) ,expression))))
      (dolist (type '(:f32 :s8 :u64))
        (let ((element (second (trivial-simd::numeric-type type))))
          (dolist (n '(32 1024 65536))
            (let* ((a (make-array n :element-type element :initial-element (coerce 2 element)))
                   (b (make-array n :element-type element :initial-element (coerce 1 element)))
                   (reference (let ((trivial-simd::*backend* :lisp)) (sharing-candidate a b))))
              (dolist (access (if (uiop:getenv "SHARING_PROFILE_COPY") '(:pointer :copy) '(:pointer)))
                (let ((trivial-simd::*native-array-access* access))
                  (dolist (method (if (evenp trial) '(:old :shared :lisp) '(:lisp :shared :old)))
                    (let* ((trivial-simd::*backend* (if (eq method :lisp) :lisp :native))
                           (function (if (eq method :old) #'sharing-baseline #'sharing-candidate)))
                      (assert (eql reference (funcall function a b)))
                      (format t "~A,~A,~D,~A,~A,~,6F" label type n access method
                              (benchmark-time (lambda () (funcall function a b))))
                      (if (eq method :lisp) (format t ",0,0,0,0,0,0,0")
                          (sharing-traffic expression lazy type a b (eq method :shared)))
                      (terpri)
                      (finish-output))))))))))))
