(ql:quickload :trivial-simd/blas)

(dolist (encoding '(:f16 :bf16))
  (let ((x (make-array 3 :element-type '(unsigned-byte 16)))
        (y (make-array 3 :element-type '(unsigned-byte 16)))
        (floats (make-array 3 :element-type 'single-float
                             :initial-contents '(1.0f0 2.0f0 3.0f0))))
    (trivial-simd:convert! x floats :destination-encoding encoding)
    (trivial-simd/blas:copy 3 x 1 y 1 :encoding encoding)
    (trivial-simd/blas:axpy 3 2 x -1 y 1 :encoding encoding)
    (trivial-simd:convert! floats y :input-encoding encoding)
    (assert (equalp floats #(7.0f0 6.0f0 5.0f0)))
    (assert (= 18.0f0 (trivial-simd/blas:asum 3 y 1 :encoding encoding)))
    (assert (= 34.0f0 (trivial-simd/blas:dot 3 x 1 y 1 :encoding encoding)))
    (assert (= 0 (trivial-simd/blas:iamax 3 y 1 :encoding encoding)))
    (format t "~A: Y=~S, norm=~F~%" encoding floats
            (trivial-simd/blas:nrm2 3 y 1 :encoding encoding))))
