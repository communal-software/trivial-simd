(in-package #:trivial-simd/tests)
(in-suite :trivial-simd)

(test encoded-matmul-native-capability
  (dolist (backend (available-backends))
    (with-backend (backend)
      (is (eq (and simd::*native-encoded-matmul-p* (not (eq backend :lisp)) t)
              (simd:encoded-matmul-native-p)))))
  (let ((simd::*native-encoded-matmul-p* nil))
    (is (null (simd:encoded-matmul-native-p)))))

(test encoded-matmul-layouts-and-backends
  (dolist (encoding '(:f16 :bf16))
    (dolist (shape '((1 1 1) (3 5 7) (4 3 16) (5 9 33) (6 7 65) (46 3 128)))
      (destructuring-bind (n m k) shape
        (let* ((xs (+ k 3)) (ws (+ k 5)) (os (+ m 2))
               (x (random-floats (+ 2 (* n xs))))
               (values (random-floats (+ 3 (* m ws))))
               (weights (make-array (length values) :element-type '(unsigned-byte 16)))
               (out (make-array (+ 4 (* n os)) :element-type 'single-float :initial-element -7f0))
               (expected (copy-seq out))
               (function (if (eq encoding :f16) #'simd:f16-matmul! #'simd:bf16-matmul!)))
          (simd:convert! weights values :destination-encoding encoding)
          (simd::encoded-matmul-lisp encoding expected x weights n m k 2 3 4 xs ws os)
          (dolist (backend (available-backends))
            (with-backend (backend)
              (is (eq out (funcall function out x weights n m k :x-start 2 :weights-start 3
                                  :out-start 4 :x-stride xs :weights-stride ws :out-stride os)))
              (loop for a across out for e across expected
                    do (is (<= (abs (- a e)) (* 2d-6 k)))))))))))

(test encoded-matmul-foreign-and-fallback
  (dolist (encoding '(:f16 :bf16))
    (let* ((x (random-floats 35)) (values (random-floats 21))
           (weights (make-array 21 :element-type '(unsigned-byte 16)))
           (expected (make-array 15 :element-type 'single-float))
           (function (if (eq encoding :f16) #'simd:f16-matmul! #'simd:bf16-matmul!)))
      (simd:convert! weights values :destination-encoding encoding)
      (simd::encoded-matmul-lisp encoding expected x weights 5 3 7 0 0 0 7 7 3)
      (cffi:with-foreign-objects ((raw :uint16 21) (result :float 15))
        (dotimes (i 21) (setf (cffi:mem-aref raw :uint16 i) (aref weights i)))
        (dolist (native '(t nil))
          (let ((simd::*native-encoded-matmul-p* (and native simd::*native-encoded-matmul-p*))
                (view (simd:make-vector-view result :f32 15)))
            (funcall function view x (simd:make-vector-view raw :u16 21) 5 3 7)
            (dotimes (i 15) (is (< (abs (- (simd::view-ref view i) (aref expected i))) 1f-4)))))))))

(test encoded-matmul-validation-and-empty
  (let ((out (make-array 6 :element-type 'single-float :initial-element -7f0))
        (x (random-floats 8)) (weights (make-array 12 :element-type '(unsigned-byte 16))))
    (dolist (function (list #'simd:f16-matmul! #'simd:bf16-matmul!))
      (signals error (funcall function out x weights 2 3 4 :x-stride 3))
      (signals error (funcall function out x weights 2 3 4 :weights-start 1))
      (signals error (funcall function out out weights 2 3 3))
      (signals error (funcall function out weights x 0 0 0))
      (signals error (funcall function out x weights -1 3 4))
      (is (every (lambda (v) (= v -7f0)) out))
      (funcall function out x weights 0 3 4)
      (funcall function out x weights 2 3 0)
      (is (every #'zerop out))
      (fill out -7f0))))

#+(or sbcl ccl ecl)
(test encoded-matmul-rejects-mixed-aliases
  (let ((storage (make-array 32 :element-type 'single-float :initial-element 1f0)))
    (simd::with-vector-pointer (pointer storage)
      (signals error
        (simd:f16-matmul! storage (random-floats 4) (simd:make-vector-view pointer :u16 64) 1 4 4))
      (is (every (lambda (v) (= v 1f0)) storage)))))
