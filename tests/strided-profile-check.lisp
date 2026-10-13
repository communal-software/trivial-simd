(require :asdf)
(unless (find-package :ql)
  (dolist (candidate '("quicklisp/setup.lisp" ".roswell/lisp/quicklisp/setup.lisp"))
    (let ((path (merge-pathnames candidate (user-homedir-pathname))))
      (when (probe-file path) (load path) (return)))))
(let ((root (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
  (asdf:initialize-source-registry `(:source-registry (:directory ,root) :inherit-configuration)))
(asdf:load-system :trivial-simd/tests)
(load (merge-pathnames "strided-memory-profile.lisp" *load-truename*))

(dolist (variant '("general" "candidate" "dispatch"))
  (format t "~&Strided correctness: ~A~%" variant)
  (strided-profile-bindings variant
    (lambda ()
      (dolist (name '(trivial-simd/tests::native-float-specialization-layouts
                      trivial-simd/tests::native-float-disjoint-interleaved-updates))
        (unless (fiveam:run! name) (error "Strided ~A check failed" variant))))))
