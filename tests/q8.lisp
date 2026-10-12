(in-package #:trivial-simd/tests)

(in-suite :trivial-simd)

(defun random-q8-0-blocks (rows k)
  "RANK rows of K elements as GGUF Q8_0 blocks with normal f16 scales."
  (let ((blocks (make-array (* rows (floor k 32) 34) :element-type '(unsigned-byte 8))))
    (dotimes (block (* rows (floor k 32)) blocks)
      (let ((base (* block 34)) (scale (logior (ash (+ 10 (random 5)) 10) (random 1024)
                                               (ash (random 2) 15))))
        (setf (aref blocks base) (ldb (byte 8 0) scale)
              (aref blocks (1+ base)) (ldb (byte 8 8) scale))
        (dotimes (i 32) (setf (aref blocks (+ base 2 i)) (random 256)))))))

(defun random-floats (count)
  (let ((vector (make-array count :element-type 'single-float)))
    (dotimes (i count vector) (setf (aref vector i) (- (random 2f0) 1f0)))))

(defun q8-0-close-p (actual expected k)
  "Within single-float rounding of a K-term sum of terms at most 127 * 0.5 in size."
  (every (lambda (a e) (<= (abs (- a e)) (* 1f-6 k 64))) actual expected))

(test q8-0-matmul-matches-the-lisp-reference
  (dolist (shape '((1 1 32) (1 5 64) (3 7 96) (4 8 2048) (5 9 128) (6 33 2048) (46 17 256)))
    (destructuring-bind (n m k) shape
      (let ((blocks (random-q8-0-blocks m k)) (x (random-floats (* n k)))
            (out (make-array (* n m) :element-type 'single-float))
            (expected (make-array (* n m) :element-type 'single-float)))
        (simd::q8-0-matmul-lisp expected x blocks n m k k m)
        (simd:q8-0-matmul! out x blocks n m k)
        (is (q8-0-close-p out expected k) "~S" shape)))))

(test q8-0-matmul-honours-strides
  (let* ((n 3) (m 5) (k 64) (x-stride 70) (out-stride 9)
         (blocks (random-q8-0-blocks m k)) (x (random-floats (* n x-stride)))
         (out (make-array (* n out-stride) :element-type 'single-float :initial-element -7f0))
         (expected (make-array (* n out-stride) :element-type 'single-float :initial-element -7f0)))
    (simd::q8-0-matmul-lisp expected x blocks n m k x-stride out-stride)
    (simd:q8-0-matmul! out x blocks n m k :x-stride x-stride :out-stride out-stride)
    (is (q8-0-close-p out expected k))
    (is (= -7f0 (aref out 5)) "columns past M are untouched")))

(test q8-0-matmul-reads-foreign-views
  (let* ((n 2) (m 4) (k 128) (blocks (random-q8-0-blocks m k)) (x (random-floats (* n k)))
         (expected (make-array (* n m) :element-type 'single-float)))
    (simd::q8-0-matmul-lisp expected x blocks n m k k m)
    (cffi:with-foreign-objects ((raw :uint8 (length blocks)) (out :float (* n m)))
      (dotimes (i (length blocks)) (setf (cffi:mem-aref raw :uint8 i) (aref blocks i)))
      (let ((view (simd:make-vector-view raw :u8 (length blocks)))
            (result (simd:make-vector-view out :f32 (* n m))))
        (simd:q8-0-matmul! result x view n m k)
        (is (q8-0-close-p (coerce (loop for i below (* n m) collect (simd::view-ref result i)) 'vector)
                          expected k))))))

(test q8-0-matmul-handles-an-empty-product
  (let ((out (make-array 0 :element-type 'single-float)))
    (is (eq out (simd:q8-0-matmul! out (make-array 0 :element-type 'single-float)
                                   (make-array 0 :element-type '(unsigned-byte 8)) 0 0 32)))))

(test q8-0-matmul-rejects-bad-arguments
  (let ((blocks (random-q8-0-blocks 2 64)) (x (random-floats 64))
        (out (make-array 2 :element-type 'single-float)))
    (signals error (simd:q8-0-matmul! out x blocks 1 2 33))
    (signals error (simd:q8-0-matmul! out x (subseq blocks 1) 1 2 64))
    (signals error (simd:q8-0-matmul! out (subseq x 1) blocks 1 2 64))
    (signals error (simd:q8-0-matmul! (subseq out 1) x blocks 1 2 64))))
