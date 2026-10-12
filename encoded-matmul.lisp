(in-package #:trivial-simd)

(define-native ("ts_encoded_matmul" %native-encoded-matmul) :int
  (f16 :int) (n :int64) (m :int64) (k :int64)
  (weights :pointer) (weights-stride :int64)
  (x :pointer) (x-stride :int64) (out :pointer) (out-stride :int64))

(defvar *native-encoded-matmul-p*
  (and *native-available-p* (null (missing-native-symbols '("ts_encoded_matmul")))))

(defun encoded-matrix-span (storage type start rows columns stride)
  (unless (eq (vector-type storage) type) (error "Matmul storage requires ~S" type))
  (nd-integer start 0)
  (nd-integer stride columns)
  (let ((end (if (or (zerop rows) (zerop columns)) start
                 (+ start (* (1- rows) stride) columns))))
    (nd-integer end 0)
    (nd-integer (* end (vector-element-size type)) 0)
    (when (and (plusp rows) (plusp columns) (> end (vector-length storage)))
      (error "Matmul storage is too short"))
    end))

(defun encoded-matmul-overlap-p (out out-start out-end input input-start input-end)
  (when (= input-start input-end) (return-from encoded-matmul-overlap-p nil))
  (let ((out-address (cdr (assoc out *nd-storage-addresses*)))
        (input-address (cdr (assoc input *nd-storage-addresses*))))
    (cond ((and out-address input-address)
           (let ((os (vector-element-size (vector-type out)))
                 (is (vector-element-size (vector-type input))))
             (and (< (+ out-address (* out-start os)) (+ input-address (* input-end is)))
                  (< (+ input-address (* input-start is)) (+ out-address (* out-end os))))))
          ((and (vector-view-p out) (vector-view-p input))
           (and (< (view-address out out-start) (view-address input input-end))
                (< (view-address input input-start) (view-address out out-end))))
          ((not (eq (vector-view-p out) (vector-view-p input))) t)
          (t (and (eq out input) (< out-start input-end) (< input-start out-end))))))

(defun encoded-matmul-lisp (encoding out x weights n m k xs ws os x-stride weights-stride out-stride)
  (dotimes (i n)
    (dotimes (j m)
      (let ((sum 0d0))
        (dotimes (e k)
          (incf sum (* (coerce (vector-ref x (+ xs (* i x-stride) e)) 'double-float)
                       (coerce (nd-convert-value (vector-ref weights (+ ws (* j weights-stride) e))
                                                 :f32 :u16 :nearest-even nil encoding)
                               'double-float))))
        (setf (vector-ref out (+ os (* i out-stride) j)) (coerce sum 'single-float))))))

(defun encoded-matmul! (encoding out x weights n m k xs ws os x-stride weights-stride out-stride)
  (dolist (dimension (list n m k)) (nd-integer dimension 0))
  (let ((out-end (encoded-matrix-span out :f32 os n m out-stride))
        (x-end (encoded-matrix-span x :f32 xs n k x-stride))
        (weights-end (encoded-matrix-span weights :u16 ws m k weights-stride)))
    (when (or (zerop n) (zerop m)) (return-from encoded-matmul! out))
    (flet ((execute ()
             (when (or (encoded-matmul-overlap-p out os out-end x xs x-end)
                       (encoded-matmul-overlap-p out os out-end weights ws weights-end))
               (error "Matmul output overlaps an input"))
             (if (and *native-encoded-matmul-p* (not (eq *backend* :lisp)))
                 (with-pinned-pointers ((wp weights) (xp x) (op out))
                   (check-native-extended-status
                    (%native-encoded-matmul
                     (if (eq encoding :f16) 1 0) n m k
                     (element-pointer wp :uint16 ws) weights-stride
                     (element-pointer xp :float xs) x-stride
                     (element-pointer op :float os) out-stride)))
                 (encoded-matmul-lisp encoding out x weights n m k xs ws os
                                      x-stride weights-stride out-stride))))
      #+(or sbcl ccl ecl)
      (nd-call-with-storage-addresses (remove-duplicates (list out x weights) :test #'eq) #'execute)
      #-(or sbcl ccl ecl)
      (execute)))
  out)

(defmacro define-encoded-matmul (name encoding)
  `(defun ,name (out x weights n m k
                 &key (x-start 0) (weights-start 0) (out-start 0)
                      (x-stride k) (weights-stride k) (out-stride m))
     ,(format nil "Write OUT = X × WEIGHTSᵀ, reading ~A weight bits and f32 activations." encoding)
     (encoded-matmul! ,encoding out x weights n m k x-start weights-start out-start
                      x-stride weights-stride out-stride)))

(define-encoded-matmul f16-matmul! :f16)
(define-encoded-matmul bf16-matmul! :bf16)
