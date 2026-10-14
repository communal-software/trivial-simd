# Q4/Q6 matmul

`q4-0-matmul!`, `q4-k-matmul!` and `q6-k-matmul!` multiply F32 activations by packed GGUF weights without expanding the whole weight matrix.

```lisp
(trivial-simd:q4-k-matmul! out x blocks n m k)
```

The product is `out (n × m) = x (n × k) · weightsᵀ`, where weights contain `m` rows of `k` elements.

## Arguments

| Argument | Contract |
|---|---|
| `out` | F32 vector or foreign-memory view; receives the result |
| `x` | F32 vector or view of activation rows |
| `blocks` | Unsigned-byte-8 vector or view of packed weight rows |
| `n m k` | Nonnegative activation rows, weight rows and inner dimension |
| `:x-stride` | Activation row stride in elements, at least `k`; default `k` |
| `:out-stride` | Output row stride in elements, at least `m`; default `m` |

| Format | Elements/block | Bytes/block |
|---|---:|---:|
| Q4_0 | 32 | 18 |
| Q4_K | 256 | 144 |
| Q6_K | 256 | 210 |

`k` is a multiple of the format's block size. A view's pointer supplies its starting offset. Bounds, element types, strides and output/input overlap are checked before writing. Non-finite scales signal errors before writing in both native and Lisp execution. Empty output shapes do no work; a zero inner dimension writes zeros.

## Execution

Native ARM64 kernels use NEON; other architectures use scalar C. Each kernel decodes one block into stack storage and reuses it across up to four activation rows. Weight files remain packed and memory-mapped.

A Lisp implementation runs when the native library lacks `ts_packed_matmul` or the Lisp backend is selected. It reads foreign bytes in place and uses a block-sized scratch vector. Lisp products accumulate in double precision and native products in single precision, so comparisons allow rounding error.

## Verification

The suite compares both paths with block expectations generated independently by pinned llama.cpp. It covers packed scale fields, signed subscales, nibble and high-bit ordering, subnormal scales, padded strides, foreign views, missing-symbol fallback and validation before writes.

On macOS or Linux, `python3 tests/packed-matmul-native.py` checks both the built native library and a separately compiled scalar kernel. The committed expectations need no llama.cpp runtime. Their generator lives in cl-inference's `tests/local/generate-quant-fixtures.py`.

## M1 measurements

SBCL 2.6.8, Release build, a mapped 512 × 2048 weight matrix; five-call means:

| Activation rows | Q4_0 | Q4_K | Q6_K |
|---|---:|---:|---:|
| 1 | 0.429 ms | 0.466 ms | 0.443 ms |
| 16 | 2.729 ms | 3.693 ms | 3.705 ms |
| 64 | 10.847 ms | 14.773 ms | 14.516 ms |

These runs report zero measured Lisp heap bytes per call after warmup; inputs and outputs are allocated before timing. Native decode scratch lives on the stack. Run `sbcl --non-interactive --load examples/packed-matmul-bench.lisp` to repeat the measurements with a configured ASDF registry.
