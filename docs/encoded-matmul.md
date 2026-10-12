# f16 and bf16 matmul

`f16-matmul!` and `bf16-matmul!` multiply f32 activation rows by encoded weight rows and write f32 output. Foreign weight views are read directly, without an f32 weight buffer.

```lisp
;; out[n,m] = x[n,k] × weights[m,k]ᵀ
(trivial-simd:f16-matmul! out x weights n m k)
(trivial-simd:bf16-matmul! out x weights n m k)
```

| Argument | Storage or meaning |
|---|---|
| `out` | f32 vector or view, `n` rows of `m` |
| `x` | f32 vector or view, `n` rows of `k` |
| `weights` | unsigned-byte-16 vector or `:u16` view, `m` rows of `k` encoded values |
| `:out-start`, `:x-start`, `:weights-start` | Element offsets, default zero |
| `:out-stride`, `:x-stride`, `:weights-stride` | Row strides in elements, defaults `m`, `k`, `k` |

Each row is contiguous; padding between rows is allowed. Strides are nonnegative and at least the row width. `k` accepts any nonnegative length, including SIMD tails. Types, dimensions, spans and output/input overlap are checked before writes. Overlapping output signals an error. Both calls return `out`. Empty outputs perform no writes; a zero contraction writes zeros.

Run [the example](../examples/encoded-matmul.lisp) for ordinary arrays and foreign weights.

## Execution

| Configuration | Path |
|---|---|
| Native library with the matmul symbol, backend `:native` or `:sbcl` | NEON on ARM64, SSE2 on x86-64, scalar C elsewhere |
| Backend `:lisp`, missing library or missing symbol | Direct Lisp computation |

Packed kernels widen weights in registers and reuse activations and weights across output tiles. Native accumulation uses f32; the Lisp reference uses f64 accumulation and rounds the output to f32. Results agree within accumulation rounding error, rather than bit for bit. Exceptional arithmetic follows the active backend.[^widening]

## Measurements

See [encoded weight measurements](encoded-matmul-performance.md) for complete calls, comparison with conversion plus BLAS, and commands for local and native x86-64 profiles.

## Limitations

Arbitrary inner strides, general GEMM transpose/alpha/beta options, two encoded operands and f64 activations are outside these functions. Tensor callers adapt layouts and use f32 output.

Large activation batches reread weights across tiles. At 46 rows on M1, conversion plus BLAS is faster; see [the measurements](encoded-matmul-performance.md).

[^widening]: f16 and bf16 widening is exact for finite values and quiets NaNs. ARM64 uses hardware f16 widening when its half-format and flush settings permit it; otherwise it constructs f32 values explicitly. Mathematical operations retain the caller's floating-point environment. SSE2 widening uses integer construction and exact subtraction for f16 subnormals.
