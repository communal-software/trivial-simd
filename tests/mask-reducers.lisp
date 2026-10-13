(in-package #:trivial-simd/tests)
(in-suite :trivial-simd)

(macrolet ((reducers ()
             `(progn
                ,@(loop for reducer in '(simd:sum simd:asum simd:nrm2 simd:minimum simd:maximum
                                        simd:argmin simd:argmax simd:prod)
                        collect `(simd:define-kernel
                                  ,(intern (format nil "LAZY-SELECT-~A" reducer)) (a b)
                                  (,reducer (simd:select (> a b) a b)))))))
  (reducers))

(defparameter *lazy-selection-reducers*
  '(lazy-select-sum lazy-select-asum lazy-select-nrm2 lazy-select-minimum
    lazy-select-maximum lazy-select-argmin lazy-select-argmax lazy-select-prod))

(simd:define-kernel lazy-divide-sum (a b)
  (simd:sum (simd:select (> a b) a (/ a b))))
(simd:define-kernel lazy-root-maximum (a b)
  (simd:maximum (simd:select (> a b) a (sqrt b))))
(simd:define-kernel lazy-log-maximum (a b)
  (simd:maximum (simd:select (> a b) a (log b))))
(simd:define-kernel lazy-overflow-minimum (a b)
  (simd:minimum (simd:select (> a b) a (* a a))))
(simd:define-kernel lazy-negate-minimum (a b)
  (simd:minimum (simd:select (= a b) (- a) b)))
(simd:define-kernel lazy-nested-sum (a b)
  (simd:sum (simd:select (> a b) (simd:select (> b 0) (/ a b) a)
                       (simd:select (> b 0) b (/ a b)))))

(macrolet ((spilling ()
             (let ((tree (balanced-expression 9)))
               `(simd:define-kernel lazy-spilling-sum (a b)
                  (simd:sum (simd:select (> a b) ,tree b))))))
  (spilling))

(test native-mask-reducers-types-slices-and-views
  (when simd::*native-kernel-predication-p*
    (let ((simd::*native-mask-reducer-minimum-count* 0))
      (dolist (entry simd::*numeric-types*)
        (let* ((key (first entry)) (element (second entry))
               (a (make-array 609 :element-type element
                                  :initial-contents (loop for i below 609 collect (coerce (mod i 3) element))))
               (b (make-array 609 :element-type element
                                  :initial-contents (loop for i below 609 collect (coerce (mod (+ i 1) 3) element)))))
          (dolist (function *lazy-selection-reducers*)
            (if (and (simd::integer-type-p key) (eq function 'lazy-select-nrm2))
                (with-backend (:native) (signals error (funcall function a b)))
                (dolist (n '(0 1 3 15 16 17 255 256 257 601))
                  (let* ((keys (list :start 2 :end (+ n 2) :a-start 3 :b-start 5))
                         (expected (with-backend (:lisp) (apply function a b keys))))
                    (dolist (access '(:pointer :copy))
                      (let ((simd::*native-array-access* access))
                        (with-backend (:native)
                          (is (if (floatp expected)
                                  (floats-close-p (apply function a b keys) expected)
                                  (eql (apply function a b keys) expected)))
                          (when (= n 601)
                            (dolist (simd::*view-block-size* '(5 4096))
                              (check-views function (append (list a b) keys)
                                           :test #'numerically-close-p)))))))))))))))

(test native-mask-reducers-dispatch-and-fallback
  (when simd::*native-kernel-predication-p*
    (let* ((a (make-array 19 :element-type 'single-float :initial-element 4f0))
           (b (make-array 19 :element-type 'single-float :initial-element 0f0))
           (original (symbol-function 'simd::call-native-kernel-reduction))
           (calls 0)
           (simd::*native-mask-reducer-minimum-count* 0))
      (unwind-protect
           (progn
             (setf (symbol-function 'simd::call-native-kernel-reduction)
                   (lambda (&rest arguments) (incf calls) (apply original arguments)))
             (with-backend (:native)
               (is (= 76f0 (lazy-divide-sum a b)))
               (is (= 1 calls))
               (let ((simd::*native-kernel-predication-p* nil))
                 (is (= 76f0 (lazy-divide-sum a b)))
                 (with-view-memory (is (= 76f0 (lazy-divide-sum (mirror a) (mirror b)))))
                 (is (= 1 calls)))
               (let ((simd::*native-mask-reducer-minimum-count* 20))
                 (is (= 76f0 (lazy-divide-sum a b)))
                 (is (= 1 calls)))))
        (setf (symbol-function 'simd::call-native-kernel-reduction) original)))))

(test native-mask-reducers-lazy-errors
  (when simd::*native-kernel-predication-p*
    (let ((simd::*native-mask-reducer-minimum-count* 0))
      (dolist (entry simd::*numeric-types*)
        (let* ((element (second entry))
               (a (make-array 601 :element-type element :initial-element (coerce 4 element)))
               (b (make-array 601 :element-type element :initial-element (coerce 0 element))))
          (loop for i below 601 by 2 do (setf (aref b i) (coerce 8 element)))
          (with-backend (:native)
            (is (eql (with-backend (:lisp) (lazy-divide-sum a b)) (lazy-divide-sum a b)))
            (is (eql (with-backend (:lisp) (lazy-nested-sum a b)) (lazy-nested-sum a b)))
            (setf (aref a 301) (coerce 0 element))
            (flet ((condition-type (left right backend)
                     (with-backend (backend)
                       (handler-case (progn (lazy-divide-sum left right) nil)
                         (error (condition) (type-of condition))))))
              (let ((expected (condition-type a b :lisp)))
                (is (eq expected (condition-type a b :native)))
                (with-view-memory
                  (is (eq expected (condition-type (mirror a) (mirror b) :native)))))))))
      (dolist (element '(single-float double-float))
        (let ((a (make-array 601 :element-type element :initial-element (coerce 4 element)))
              (b (make-array 601 :element-type element :initial-element (coerce -1 element))))
          (with-backend (:native)
            (is (= 4 (lazy-root-maximum a b)))
            (is (= 4 (lazy-log-maximum a b)))
            (fill a (if (eq element 'single-float) most-positive-single-float most-positive-double-float))
            (is (= (aref a 0) (lazy-overflow-minimum a b)))
            (setf (aref a 300) (coerce -2 element))
            (signals error (lazy-root-maximum a b))
            (signals error (lazy-log-maximum a b))))))))

(test native-mask-reducers-spill-concurrency
  (when simd::*native-kernel-predication-p*
    (dolist (element '(single-float double-float (signed-byte 8) (unsigned-byte 64)))
      (let* ((a (make-array 1025 :element-type element
                                  :initial-contents (loop for i below 1025 collect (coerce (mod i 2) element))))
             (b (make-array 1025 :element-type element :initial-element (coerce 0 element)))
             (expected (with-backend (:lisp) (lazy-spilling-sum a b)))
             (workers
               (loop repeat 4 collect
                 (bordeaux-threads:make-thread
                  (lambda ()
                    (let ((simd::*native-mask-reducer-minimum-count* 0)
                          (simd::*backend* :native))
                      (loop repeat 10 always (= expected (lazy-spilling-sum a b)))))))))
        (dolist (worker workers) (is-true (bordeaux-threads:join-thread worker)))))))

(test native-mask-reducers-zero-ties-and-norms
  (when simd::*native-kernel-predication-p*
    (let ((simd::*native-mask-reducer-minimum-count* 0))
      (dolist (element '(single-float double-float))
        (let* ((zero (coerce 0 element))
               (a (make-array 601 :element-type element :initial-element zero))
               (b (make-array 601 :element-type element :initial-element zero)))
          (with-backend (:native)
            (is (eql (- zero) (lazy-negate-minimum a b)))
            (is (= 0 (lazy-select-argmin a b)))
            (setf (aref a 256) (- zero))
            (is (eql zero (lazy-select-minimum a b)))
            (is (= 0 (lazy-select-argmax a b)))
            (fill a (if (eq element 'single-float) 1f30 1d200))
            (is (floats-close-p (lazy-select-nrm2 a b)
                               (with-backend (:lisp) (simd:nrm2 a))))
            (fill a (if (eq element 'single-float) 1f-30 1d-200))
            (is (floats-close-p (lazy-select-nrm2 a b)
                               (with-backend (:lisp) (simd:nrm2 a))))))))))

(test native-mask-reducers-integer-boundaries
  (when simd::*native-kernel-predication-p*
    (let ((simd::*native-mask-reducer-minimum-count* 0))
      (dolist (entry simd::*numeric-types*)
        (when (simd::integer-type-p (first entry))
          (multiple-value-bind (low high) (simd::integer-limits (first entry))
            (dolist (value (list low high))
              (let* ((a (make-array 257 :element-type (second entry) :initial-element value))
                     (b (copy-seq a)))
                (dolist (function '(lazy-select-sum lazy-select-asum lazy-select-prod
                                    lazy-select-minimum lazy-select-maximum lazy-select-argmin lazy-select-argmax))
                  (is (eql (with-backend (:lisp) (funcall function a b))
                           (with-backend (:native) (funcall function a b)))))))))))))

(test native-mask-reducers-gate-boundaries
  (when simd::*native-kernel-predication-p*
    (let ((tree '(:select (:operation :gt (:argument 0) (:argument 1)) (:argument 0) (:argument 1)))
          (simd::*native-mask-reducer-minimum-count* nil))
      (with-backend (:native)
        (maphash
         (lambda (key gate)
           (destructuring-bind (architecture type reducer access class) key
             (when (equal architecture simd::*native-mask-reducer-architecture*)
               (let* ((simd::*native-array-access* (if (eq access :copy) :copy :pointer))
                      (a (make-array 1 :element-type (second (simd::numeric-type type))
                                       :initial-element (coerce 0 (second (simd::numeric-type type))))))
                 (with-view-memory
                   (let ((inputs (if (eq access :view) (list (mirror a) (mirror a)) (list a a))))
                     (is-true (simd::native-mask-reducer-eligible-p tree type reducer inputs gate class nil nil))
                     (is-false (simd::native-mask-reducer-eligible-p tree type reducer inputs (1- gate) class nil nil))))))))
         simd::*native-mask-reducer-gates*)))))

(test native-mask-reducers-missing-math-capabilities
  (when simd::*native-kernel-predication-p*
    (let ((simd::*native-mask-reducer-minimum-count* 0)
          (simd::*native-kernel-activation-math-p* nil)
          (simd::*native-kernel-transcendentals-p* nil)
          (a (make-array 257 :element-type 'single-float :initial-element 4f0))
          (b (make-array 257 :element-type 'single-float :initial-element -1f0)))
      (with-backend (:native)
        (is (= 4f0 (lazy-log-maximum a b)))
        (with-view-memory
          (is (= 4f0 (lazy-log-maximum (mirror a) (mirror b)))))))))

(test native-mask-reducers-default-dispatch
  (when simd::*native-kernel-predication-p*
    (let ((gate (gethash (list simd::*native-mask-reducer-architecture* :f32 'simd:sum :pointer :selection)
                        simd::*native-mask-reducer-gates*)))
      (when gate
        (let* ((a (make-array gate :element-type 'single-float :initial-element 4f0))
               (b (make-array gate :element-type 'single-float :initial-element 0f0))
               (original (symbol-function 'simd::call-native-kernel-reduction))
               (calls 0)
               (simd::*native-mask-reducer-minimum-count* nil)
               (simd::*native-array-access* :pointer))
          (unwind-protect
               (progn
                 (setf (symbol-function 'simd::call-native-kernel-reduction)
                       (lambda (&rest arguments) (incf calls) (apply original arguments)))
                 (with-backend (:native)
                   (is (= (* gate 4f0) (lazy-select-sum a b)))
                   (is (= 1 calls))
                   (is (= (* (1- gate) 4f0) (lazy-select-sum a b :end (1- gate))))
                   (is (= 1 calls))))
            (setf (symbol-function 'simd::call-native-kernel-reduction) original)))))))
