(require :asdf)
(asdf:load-system "trivial-simd/blas")

(let ((input (make-array 8 :element-type 'single-float
                           :initial-contents '(0f0 1f0 2f0 3f0 4f0 5f0 6f0 7f0)))
      (output (make-array 8 :element-type 'single-float :initial-element -1f0)))
  (trivial-simd:add! output input 10f0 :end 4 :left-start 7 :left-stride -2
                                     :destination-stride 2)
  (assert (equalp output #(17f0 -1f0 15f0 -1f0 13f0 -1f0 11f0 -1f0)))
  (assert (= 16f0 (trivial-simd:sum input :end 4 :input-start 7 :stride -2)))
  (trivial-simd/blas:saxpy 4 2f0 input 2 output 2)
  (assert (equalp output #(17f0 -1f0 19f0 -1f0 21f0 -1f0 23f0 -1f0)))
  (trivial-simd:add! output input input :end 8 :destination-start 7
                                       :left-start 7 :right-start 7 :stride -1)
  (assert (equalp output #(0f0 2f0 4f0 6f0 8f0 10f0 12f0 14f0))))
