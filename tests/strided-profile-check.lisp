(require :asdf)
(unless (find-package :ql)
  (dolist (candidate '("quicklisp/setup.lisp" ".roswell/lisp/quicklisp/setup.lisp"))
    (let ((path (merge-pathnames candidate (user-homedir-pathname))))
      (when (probe-file path) (load path) (return)))))
(let ((root (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
  (asdf:initialize-source-registry `(:source-registry (:directory ,root) :inherit-configuration)))
(asdf:load-system :trivial-simd/tests)
(load (merge-pathnames "strided-memory-profile.lisp" *load-truename*))

(let ((old (and (fboundp 'benchmark-batch) (symbol-function 'benchmark-batch)))
      (calls 0)
      (minimum (max 1 (ceiling (* 0.005d0 internal-time-units-per-second)))))
  (unwind-protect
       (progn
         (setf (symbol-function 'benchmark-batch)
               (lambda (function iterations)
                 (declare (ignore function))
                 (incf calls)
                 (if (or (= calls 1) (> iterations 1)) minimum 0)))
         (assert (plusp (strided-profile-time (constantly nil))))
         (assert (= calls 6)))
    (if old (setf (symbol-function 'benchmark-batch) old)
        (fmakunbound 'benchmark-batch))))

(dolist (variant '("general" "candidate" "dispatch"))
  (format t "~&Strided correctness: ~A~%" variant)
  (strided-profile-bindings variant
    (lambda ()
      (dolist (name '(trivial-simd/tests::native-float-specialization-layouts
                      trivial-simd/tests::native-float-disjoint-interleaved-updates))
        (unless (fiveam:run! name) (error "Strided ~A check failed" variant))))))
