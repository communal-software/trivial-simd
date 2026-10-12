(in-package #:trivial-simd)

(defconstant +q8-0-block-elements+ 32)
(defconstant +q8-0-block-bytes+ 34)

(define-native ("ts_q8_0_matmul" %native-q8-0-matmul) :int
  (n :int64) (m :int64) (k :int64) (blocks :pointer)
  (x :pointer) (x-stride :int64) (out :pointer) (out-stride :int64))

(defvar *native-q8-0-p*
  (and *native-available-p* (ignore-errors (cffi:foreign-symbol-pointer "ts_q8_0_matmul")) t))

(defun q8-0-scale (low high)
  "The f16 scale stored in the first two bytes of a Q8_0 block, as a double."
  (let* ((bits (logior low (ash high 8)))
         (sign (if (logbitp 15 bits) -1d0 1d0))
         (exponent (ldb (byte 5 10) bits))
         (fraction (ldb (byte 10 0) bits)))
    (cond ((zerop exponent) (* sign (scale-float (coerce fraction 'double-float) -24)))
          ((= exponent 31) (error "Q8_0 scale is not finite"))
          (t (* sign (scale-float (coerce (+ 1024 fraction) 'double-float) (- exponent 25)))))))

(defun lisp-vector (vector element-type)
  "VECTOR, or a Lisp copy of it when it is a view."
  (if (vector-view-p vector)
      (copy! (make-array (vector-view-length vector) :element-type element-type) vector)
      vector))

(defun q8-0-matmul-lisp (out x blocks n m k x-stride out-stride)
  (let ((block-count (floor k +q8-0-block-elements+))
        (x (lisp-vector x 'single-float))
        (blocks (lisp-vector blocks '(unsigned-byte 8)))
        (destination (lisp-vector out 'single-float)))
    (dotimes (j m)
      (dotimes (i n)
        (let ((sum 0d0))
          (dotimes (b block-count)
            (let* ((base (* (+ (* j block-count) b) +q8-0-block-bytes+))
                   (scale (q8-0-scale (aref blocks base) (aref blocks (1+ base))))
                   (partial 0d0))
              (dotimes (e +q8-0-block-elements+)
                (let ((byte (aref blocks (+ base 2 e))))
                  (incf partial (* (aref x (+ (* i x-stride) (* b +q8-0-block-elements+) e))
                                   (if (< byte 128) byte (- byte 256))))))
              (incf sum (* partial scale))))
          (setf (aref destination (+ (* i out-stride) j)) (coerce sum 'single-float)))))
    (unless (eq destination out) (copy! out destination))))

(defun q8-0-matmul! (out x blocks n m k &key (x-stride k) (out-stride m))
  "Set row i, column j of the N x M matrix OUT to the dot product of row i of X and
row j of the Q8_0 matrix BLOCKS, whose M rows of K elements are the GGUF blocks
of a f16 scale and 32 signed bytes. X and OUT are single-float vectors or views, and
BLOCKS an (unsigned-byte 8) vector or view. K is a multiple of 32."
  (check-type n (integer 0)) (check-type m (integer 0)) (check-type k (integer 0))
  (unless (zerop (mod k +q8-0-block-elements+))
    (error "Q8_0 row length ~D is not a multiple of ~D" k +q8-0-block-elements+))
  (let ((block-bytes (* m (floor k +q8-0-block-elements+) +q8-0-block-bytes+)))
    (unless (>= (vector-length blocks) block-bytes)
      (error "Q8_0 blocks hold ~D bytes, need ~D" (vector-length blocks) block-bytes)))
  (when (plusp n)
    (unless (>= (vector-length x) (+ (* (1- n) x-stride) k))
      (error "X is too short for ~D rows of ~D at stride ~D" n k x-stride))
    (unless (>= (vector-length out) (+ (* (1- n) out-stride) m))
      (error "OUT is too short for ~D rows of ~D at stride ~D" n m out-stride)))
  (if (and *native-q8-0-p* (not (eq *backend* :lisp)))
      (with-pinned-pointers ((blocks-pointer blocks) (x-pointer x) (out-pointer out))
        (%native-q8-0-matmul n m k blocks-pointer x-pointer x-stride out-pointer out-stride))
      (q8-0-matmul-lisp out x blocks n m k x-stride out-stride))
  out)
