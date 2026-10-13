(require :asdf)
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(let ((root (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
  (asdf:initialize-source-registry `(:source-registry (:directory ,root) :inherit-configuration))
  (asdf:load-system "trivial-simd"))

(defvar *mask-reducer-benchmark-result* nil)

(defun mask-reducer-benchmark-time (function)
  (funcall function)
  (labels ((batch (iterations)
             (let ((start (get-internal-real-time)))
               (dotimes (i iterations) (setf *mask-reducer-benchmark-result* (funcall function)))
               (- (get-internal-real-time) start))))
    (let ((iterations 1))
      (loop while (< (batch iterations) (max 1 (ceiling (* 0.002 internal-time-units-per-second))))
            do (setf iterations (* 2 iterations)))
      (second (sort (loop repeat 3 collect
                         (/ (* 1d6 (batch iterations)) internal-time-units-per-second iterations)) #'<)))))

(macrolet ((kernels ()
             (labels ((balanced (depth)
                        (if (zerop depth) 'a `(+ ,(balanced (1- depth)) ,(balanced (1- depth))))))
               `(progn
                  ,@(loop for class in '(:selection :arithmetic :spill) append
                      (loop for reducer in (if (eq class :spill)
                                              '(trivial-simd:sum trivial-simd:minimum)
                                              '(trivial-simd:sum trivial-simd:asum trivial-simd:nrm2
                                                trivial-simd:minimum trivial-simd:maximum trivial-simd:argmin
                                                trivial-simd:argmax trivial-simd:prod))
                            collect `(trivial-simd:define-kernel
                                      ,(intern (format nil "PROFILE-~A-~A" class reducer)) (a b)
                                      (,reducer ,(ecase class
                                                   (:selection '(trivial-simd:select (> a b) a b))
                                                   (:arithmetic '(trivial-simd:select (> a b) (+ a b) (- a b)))
                                                   (:spill `(trivial-simd:select (> a b) ,(balanced 9) b)))))))))))
  (kernels))

(format t "~&implementation,architecture,class,type,reducer,access,elements,scalar_us,native_us,speedup~%")
(let ((trivial-simd::*native-mask-reducer-minimum-count*
        (unless (uiop:getenv "MASK_REDUCER_GATED") 0))
      (trivial-simd::*inline-small-arrays* nil))
  (dolist (entry trivial-simd::*numeric-types*)
    (destructuring-bind (type element foreign &rest ignored) entry
      (declare (ignore ignored))
      (dolist (n '(32 256 1024 4096 16384 65536))
        (let ((a (make-array n :element-type element
                              :initial-contents (loop for i below n collect (coerce (if (zerop (mod i 7)) 0 1) element))))
              (b (make-array n :element-type element
                              :initial-contents (loop for i below n collect (coerce (if (zerop (mod i 3)) 1 0) element)))))
          (cffi:with-foreign-objects ((pa foreign n) (pb foreign n))
            (dotimes (i n)
              (setf (cffi:mem-aref pa foreign i) (aref a i)
                    (cffi:mem-aref pb foreign i) (aref b i)))
            (let ((va (trivial-simd:make-vector-view pa type n))
                  (vb (trivial-simd:make-vector-view pb type n)))
              (dolist (class '(:selection :arithmetic :spill))
                (dotimes (i n)
                  (setf (aref b i) (coerce (if (or (eq class :spill) (not (zerop (mod i 3)))) 0 1) element)
                        (cffi:mem-aref pb foreign i) (aref b i)))
                (dolist (reducer '(sum asum nrm2 minimum maximum argmin argmax prod))
                  (unless (or (and (trivial-simd::integer-type-p type) (eq reducer 'nrm2))
                              (and (eq class :spill)
                                   (not (and (member type '(:f32 :u64))
                                             (member reducer '(sum minimum))
                                             (member n '(1024 65536))))))
                    (let* ((fn (symbol-function (intern (format nil "PROFILE-~A-~A" class reducer))))
                           (expected (let ((trivial-simd::*backend* :lisp)) (funcall fn a b)))
                           (scalar (let ((trivial-simd::*backend* :lisp))
                                     (mask-reducer-benchmark-time (lambda () (funcall fn a b))))))
                      (dolist (access '(:pointer :copy :view))
                        (let* ((trivial-simd::*backend* :native)
                               (trivial-simd::*native-array-access* (if (eq access :copy) :copy :pointer))
                               (left (if (eq access :view) va a))
                               (right (if (eq access :view) vb b))
                               (actual (funcall fn left right)))
                          (assert (if (floatp expected)
                                      (or (= expected actual)
                                          (< (abs (- actual expected)) (* (if (eq type :f32) 1f-5 1d-12)
                                                                           (max 1 (abs expected)))))
                                      (eql expected actual)) ()
                                  "~A ~A ~A ~A n=~D: expected ~S, actual ~S"
                                  class type reducer access n expected actual)
                          (let ((native (mask-reducer-benchmark-time (lambda () (funcall fn left right)))))
                            (format t "~&~A,~A,~A,~A,~A,~A,~D,~,6F,~,6F,~,4F~%"
                                    (lisp-implementation-type) (machine-type) class type reducer access n
                                    scalar native (/ scalar native))
                            (finish-output)))))))))))))))
