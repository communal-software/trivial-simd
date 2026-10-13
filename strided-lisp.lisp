(in-package #:trivial-simd)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *strided-lisp-operations*
    '(:add :subtract :multiply :divide :scale :axpy :fma :negate :abs :sqrt
      :reciprocal :min :max :clamp :compare :select :copy :fill :swap))

  (defun strided-lisp-name (operation type)
    (intern (format nil "%LISP-STRIDED-~A-~A" operation type) :trivial-simd))

  (defun strided-lisp-binary-form (operation type left right)
    `(,(if (integer-type-p type) (integer-operation-symbol operation type)
           (ecase operation (:add '+) (:subtract '-) (:multiply '*) (:divide '/)))
      ,left ,right)))

;; Public entry points validate types and every span before these unchecked loops.
(defmacro define-strided-lisp-bulk ()
  `(progn
     ,@(loop for (type element) in (append *numeric-types* '((:c32 (complex single-float)) (:c64 (complex double-float))))
             append
             (loop for operation in *strided-lisp-operations*
                   unless (or (and (integer-type-p type) (member operation '(:sqrt :reciprocal :fma)))
                              (and (complex-type-p type) (member operation '(:abs :min :max :clamp :fma))))
                   collect
                   (let* ((destination-element (if (eq operation :compare) '(unsigned-byte 8) element))
                          (x `(if av (aref (the (simple-array ,(if (eq operation :select) '(unsigned-byte 8) element) (*)) a) ai)
                                  (the ,element a)))
                          (y `(if bv (aref (the (simple-array ,element (*)) b) bi) (the ,element b)))
                          (z `(if cv (aref (the (simple-array ,element (*)) c) ci) (the ,element c)))
                          (value
                            (case operation
                              ((:add :subtract :multiply :divide) (strided-lisp-binary-form operation type x y))
                              (:scale (strided-lisp-binary-form :multiply type '(aref destination di) x))
                              (:axpy (strided-lisp-binary-form :add type (strided-lisp-binary-form :multiply type x y) '(aref destination di)))
                              (:fma `(fma ,x ,y ,z))
                              ((:negate :abs) (if (integer-type-p type) `(,(integer-operation-symbol operation type) ,x)
                                                 `(,(if (eq operation :negate) '- 'abs) ,x)))
                              (:sqrt `(kernel-sqrt ,x))
                              (:reciprocal `(/ ,(coerce 1 element) ,x))
                              (:min `(kernel-min-left ,x ,y))
                              (:max `(kernel-max-left ,x ,y))
                              (:clamp `(let ((x ,x) (low ,y) (high ,z))
                                         (when (> low high) (error "CLAMP! lower bound exceeds upper bound"))
                                         (if (< x low) low (if (> x high) high x))))
                              (:compare `(if (compare-values operator ,x ,y) 1 0))
                              (:select `(if (zerop ,x) ,z ,y))
                              ((:copy :fill :swap) x))))
                     `(defun ,(strided-lisp-name operation type) (destination a b c count offsets strides operator)
                        (declare (type (simple-array ,destination-element (*)) destination)
                                 (type fixnum count) (ignorable a b c operator)
                                 (optimize (speed 3) (safety 0)))
                        (let ((di (first offsets)) (ai (or (second offsets) 0))
                              (bi (or (third offsets) 0)) (ci (or (fourth offsets) 0))
                              (ds (or (first strides) 1)) (as (or (second strides) 1))
                              (bs (or (third strides) 1)) (cs (or (fourth strides) 1))
                              (av (vectorp a)) (bv (vectorp b)) (cv (vectorp c)))
                          (declare (type fixnum di ai bi ci ds as bs cs) (ignorable av bv cv))
                          (dotimes (i count destination)
                            ,(if (eq operation :swap)
                                 `(let ((value ,x))
                                    (setf (aref (the (simple-array ,element (*)) a) ai) (aref destination di)
                                          (aref destination di) value))
                                 `(setf (aref destination di) ,value))
                            (incf di ds) (incf ai as) (incf bi bs) (incf ci cs)))))))))
(define-strided-lisp-bulk)

(defun strided-lisp-bulk-p (operation destination operands)
  (let ((type (if (eq operation :compare) (vector-type (find-if #'operand-vector-p operands))
                  (vector-type destination))))
    (and (vectorp destination) (member operation *strided-lisp-operations*)
         (not (and (eq operation :abs) (complex-type-p (vector-type (first operands)))))
         (every (lambda (value) (or (not (operand-vector-p value)) (vectorp value))) operands)
         (fboundp (strided-lisp-name operation type)))))

(defun strided-bulk-arrays (operation destination operands count offsets strides operator)
  (let ((type (if (eq operation :compare) (vector-type (find-if #'operand-vector-p operands))
                  (vector-type destination))))
    (funcall (strided-lisp-name operation type) destination (first operands) (second operands)
             (third operands) count offsets strides operator)))

(defmacro define-strided-lisp-reductions ()
  `(progn
     ,@(loop for (type element) in *numeric-types* append
             (loop for operation in '(:sum :dot :asum :prod :argmin :argmax :iamax :count :any :all)
                   append
                   (loop for wide in (if (and (eq type :f32) (member operation '(:sum :dot :asum))) '(nil t) '(nil))
                         for result-element = (if wide 'double-float element)
                         for name = (intern (format nil "%LISP-STRIDED-~A-~A~A" operation type (if wide "-WIDE" "")))
                         collect
                         `(defun ,name (a b count offsets strides)
                            (declare (type (simple-array ,element (*)) a)
                                     (type fixnum count) (ignorable b)
                                     (optimize (speed 3) (safety 0)))
                            (let ((ai (first offsets)) (bi (or (second offsets) 0))
                                  (as (or (first strides) 1)) (bs (or (second strides) 1)))
                              (declare (type fixnum ai bi as bs) (ignorable bi bs))
                              ,(if (member operation '(:argmin :argmax :iamax))
                                   `(unless (zerop count)
                                      (let ((best ,(if (eq operation :iamax) `(abs (aref a ai)) '(aref a ai)))
                                            (index ai))
                                        (declare (type ,element best) (type fixnum index))
                                        (dotimes (i count index)
                                          (let ((value ,(if (eq operation :iamax) `(abs (aref a ai)) '(aref a ai))))
                                            (when (,(if (eq operation :argmin) '< '>) value best)
                                              (setf best value index ai)))
                                          (incf ai as))))
                                   `(let ((result ,(case operation
                                                     (:prod (coerce 1 result-element))
                                                     (:count 0) (:any nil) (:all t)
                                                     (otherwise (coerce 0 result-element)))))
                                      (declare ,@(cond ((eq operation :count) '((type fixnum result)))
                                                      ((not (member operation '(:any :all))) `((type ,result-element result)))))
                                      (dotimes (i count result)
                                        (let ((x ,(if wide `(coerce (aref a ai) 'double-float) '(aref a ai))))
                                          (setf result
                                                ,(case operation
                                                   (:sum (strided-lisp-binary-form :add type 'result 'x))
                                                   (:prod (strided-lisp-binary-form :multiply type 'result 'x))
                                                   (:dot (strided-lisp-binary-form :add type 'result
                                                          (strided-lisp-binary-form :multiply type 'x
                                                            (if wide `(coerce (aref (the (simple-array ,element (*)) b) bi) 'double-float)
                                                                `(aref (the (simple-array ,element (*)) b) bi)))))
                                                   (:asum (strided-lisp-binary-form :add type 'result
                                                           (if (integer-type-p type) `(,(integer-operation-symbol :abs type) x) '(abs x))))
                                                   (:count '(+ result (if (zerop x) 0 1)))
                                                   (:any `(if (zerop x) nil (return-from ,name t)))
                                                   (:all `(if (zerop x) (return-from ,name nil) t)))))
                                        (incf ai as) (incf bi bs)))))))))))
(define-strided-lisp-reductions)

(defun strided-lisp-reduce-function (operation inputs wide)
  (when (every #'vectorp inputs)
    (let* ((type (vector-type (first inputs)))
           (name (intern (format nil "%LISP-STRIDED-~A-~A~A" operation type (if wide "-WIDE" "")) :trivial-simd)))
      (when (fboundp name) (symbol-function name)))))

(defmacro define-strided-lisp-conversions ()
  `(progn
     ,@(loop for (input-type input-element) in *numeric-types* append
             (loop for (output-type output-element) in *numeric-types*
                   for name = (intern (format nil "%LISP-STRIDED-CONVERT-~A-~A" input-type output-type))
                   for value = (cond ((not (integer-type-p output-type)) `(coerce value ',output-element))
                                     ((integer-type-p input-type)
                                      (multiple-value-bind (low high) (integer-limits output-type)
                                        `(min ,high (max ,low value))))
                                     (t `(convert-element value ,output-type rounding)))
                   collect
                   `(defun ,name (destination input count offsets strides rounding)
                      (declare (type (simple-array ,input-element (*)) input)
                               (type (simple-array ,output-element (*)) destination)
                               (type fixnum count) (ignorable rounding)
                               (optimize (speed 3) (safety 0)))
                      (let ((di (first offsets)) (ii (second offsets))
                            (ds (or (first strides) 1)) (is (or (second strides) 1)))
                        (declare (type fixnum di ii ds is))
                        (dotimes (i count destination)
                          (let ((value (aref input ii))) (setf (aref destination di) ,value))
                          (incf di ds) (incf ii is))))))))
(define-strided-lisp-conversions)

(defun strided-lisp-convert-function (destination input d-encoding i-encoding)
  (when (and (vectorp destination) (vectorp input) (not d-encoding) (not i-encoding)
             (not (complex-type-p (vector-type destination))) (not (complex-type-p (vector-type input))))
    (symbol-function (intern (format nil "%LISP-STRIDED-CONVERT-~A-~A" (vector-type input)
                                     (vector-type destination)) :trivial-simd))))
