# Q8_0 matmul

`q8-0-matmul!` multiplies f32 activations by a Q8_0 weight matrix read in place from its GGUF blocks.

```lisp
;; out (n × m) = x (n × k) · weightsᵀ, weights being m rows of k Q8_0 elements
(trivial-simd:q8-0-matmul! out x blocks n m k)
```

| Argument | Meaning |
|---|---|
| `out` | `single-float` vector or view; row `i`, column `j` holds the dot product of `x` row `i` and weight row `j` |
| `x` | `single-float` vector or view of `n` rows of `k` |
| `blocks` | `(unsigned-byte 8)` vector or view of the weight rows, `k/32` blocks each |
| `n m k` | Activation rows, weight rows, row length; `k` is a multiple of 32 |
| `:x-stride`, `:out-stride` | Row strides in elements; default `k` and `m` |

Each block is 34 bytes: an f16 scale, then 32 signed bytes. The blocks are used exactly as GGUF stores them, so a memory-mapped file needs no copy.

Too-short vectors and a `k` that is not a multiple of 32 signal an error. An infinite or NaN scale is an error on the Lisp path and propagates on the native one.

## Speed

Apple M1, SBCL, an 8192 × 2048 weight matrix:

| Activation rows | `q8-0-matmul!` |
|---|---|
| 1 | 3.8 ms |
| 6 | 5.0 ms |
| 46 | 51 ms |

Each block is widened once and multiplied against 4 or 8 activation rows, so a row costs more than the first only in arithmetic.[^tiles] The native library is used when built; otherwise a Lisp loop computes the same result more slowly.[^lisp]

[^tiles]: Calls with at most 4 rows use a 4-row tile and larger calls an 8-row tile; the 8-row tile slows a single row. Without NEON a scalar C loop runs instead.
[^lisp]: The Lisp loop accumulates in double precision, so it differs from the native result in the last digits; the tests accept rounding error.
