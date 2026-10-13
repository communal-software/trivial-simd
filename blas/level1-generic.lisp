(in-package #:trivial-simd/blas)

(defun validate-generic-span (n vector increment offset encoding)
  (unless (member encoding '(nil :f16 :bf16))
    (error "Encoding must be NIL, :F16 or :BF16"))
  (let ((type (if encoding '(unsigned-byte 16) 'single-float))
        (view-type (if encoding :u16 :f32)))
    (unless (or (typep vector `(simple-array ,type (*)))
                (and (trivial-simd:vector-view-p vector)
                     (eq (trivial-simd:vector-view-type vector) view-type)))
      (error 'type-error :datum vector
                         :expected-type `(or (simple-array ,type (*))
                                             trivial-simd:vector-view))))
  (validate-span-bounds n vector increment offset))

(defun generic-alpha (alpha)
  (unless (realp alpha)
    (error 'type-error :datum alpha :expected-type 'real))
  (coerce alpha 'single-float))

(defun widen-blas-span (n vector increment offset encoding)
  (let ((floats (make-array n :element-type 'single-float)))
    (trivial-simd:convert! floats vector :end n
                          :input-start (span-start n increment offset)
                          :input-stride increment :input-encoding encoding)
    floats))

(defun store-blas-span (n vector increment offset encoding floats)
  (trivial-simd:convert! vector floats :end n
                        :destination-start (span-start n increment offset)
                        :destination-stride increment :destination-encoding encoding))

(defun generic-copy-swap (operation n x incx y incy x-offset y-offset encoding)
  (validate-generic-span n x incx x-offset encoding)
  (validate-generic-span n y incy y-offset encoding)
  (let ((x-start (span-start n incx x-offset))
        (y-start (span-start n incy y-offset)))
    (ecase operation
      (:copy (trivial-simd:copy! y x :end n
                                   :source-start x-start :source-stride incx
                                   :destination-start y-start :destination-stride incy))
      (:swap (trivial-simd:swap! x y :end n
                                   :x-start x-start :x-stride incx
                                   :y-start y-start :y-stride incy)))))

(defun copy (n x incx y incy &key (x-offset 0) (y-offset 0) encoding)
  "Copy N stored values from X to Y, preserving encoded bits."
  (generic-copy-swap :copy n x incx y incy x-offset y-offset encoding))

(defun swap (n x incx y incy &key (x-offset 0) (y-offset 0) encoding)
  "Exchange N stored values and return X and Y."
  (generic-copy-swap :swap n x incx y incy x-offset y-offset encoding))

(defun axpy (n alpha x incx y incy &key (x-offset 0) (y-offset 0) encoding)
  "Set Y to ALPHA*X+Y in f32, rounding encoded results once on store."
  (validate-generic-span n x incx x-offset encoding)
  (validate-generic-span n y incy y-offset encoding)
  (let ((alpha (generic-alpha alpha)))
    (unless (or (zerop n) (zerop alpha))
      (if encoding
          (let ((xf (widen-blas-span n x incx x-offset encoding))
                (yf (widen-blas-span n y incy y-offset encoding)))
            (saxpy n alpha xf 1 yf 1)
            (store-blas-span n y incy y-offset encoding yf))
          (saxpy n alpha x incx y incy :x-offset x-offset :y-offset y-offset))))
  y)

(defun scal (n alpha x incx &key (x-offset 0) encoding)
  "Scale X in f32; a zero factor writes positive zeros without reading X."
  (validate-generic-span n x incx x-offset encoding)
  (let ((alpha (generic-alpha alpha)))
    (unless (zerop n)
      (cond ((zerop alpha)
             (let ((index (span-start n incx x-offset)))
               (dotimes (i n)
                 (setf (element x index) (if encoding 0 0.0f0))
                 (incf index incx))))
            (encoding
             (let ((xf (widen-blas-span n x incx x-offset encoding)))
               (sscal n alpha xf 1)
               (store-blas-span n x incx x-offset encoding xf)))
            (t (sscal n alpha x incx :x-offset x-offset)))))
  x)

(defun dot (n x incx y incy &key (x-offset 0) (y-offset 0) encoding)
  "Return the f32 dot product of the visited values."
  (validate-generic-span n x incx x-offset encoding)
  (validate-generic-span n y incy y-offset encoding)
  (cond ((zerop n) 0.0f0)
        (encoding
         (sdot n (widen-blas-span n x incx x-offset encoding) 1
               (widen-blas-span n y incy y-offset encoding) 1))
        (t (sdot n x incx y incy :x-offset x-offset :y-offset y-offset))))

(defun generic-reduce (operation n x incx x-offset encoding)
  (validate-generic-span n x incx x-offset encoding)
  (cond ((zerop n) (if (eq operation 'isamax) 0 0.0f0))
        (encoding
         (funcall operation n (widen-blas-span n x incx x-offset encoding) 1))
        (t (funcall operation n x incx :x-offset x-offset))))

(defun asum (n x incx &key (x-offset 0) encoding)
  "Return the sum of absolute values as a single-float."
  (generic-reduce 'sasum n x incx x-offset encoding))

(defun iamax (n x incx &key (x-offset 0) encoding)
  "Return the first logical index with maximum magnitude, or zero if empty."
  (generic-reduce 'isamax n x incx x-offset encoding))

(defun scaled-f32-norm (n x incx x-offset)
  (let ((scale 0.0f0) (ssq 1.0f0)
        (index (span-start n incx x-offset)))
    (declare (type single-float scale ssq))
    ;; Underflowed scaled contributions cannot change SSQ, which is at least one.
    (dotimes (i n)
      (let ((a (abs (element x index))))
        (unless (zerop a)
          (cond ((= scale a) (incf ssq 1.0f0))
                ((< scale a)
                 (setf ssq (+ 1.0f0 (handler-case
                                       (let ((ratio (/ scale a)))
                                         (* ssq ratio ratio))
                                     (floating-point-underflow () 0.0f0)))
                       scale a))
                (t (incf ssq (handler-case
                                (let ((ratio (/ a scale))) (* ratio ratio))
                              (floating-point-underflow () 0.0f0)))))))
      (incf index incx))
    (* scale (sqrt ssq))))

(defun nrm2 (n x incx &key (x-offset 0) encoding)
  "Return a scaled Euclidean norm computed in f32."
  (validate-generic-span n x incx x-offset encoding)
  (cond ((zerop n) 0.0f0)
        (encoding (scaled-f32-norm n (widen-blas-span n x incx x-offset encoding) 1 0))
        (t (scaled-f32-norm n x incx x-offset))))
