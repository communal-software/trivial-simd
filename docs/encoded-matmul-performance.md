# Encoded weight measurements

Direct encoded matmul avoids an f32 weight buffer. On Apple M1 it is faster than converting 256 weight rows and calling native BLAS for one or six activation rows. At 46 rows, conversion plus BLAS is faster.

## Apple M1

SBCL 2.6.8, native NEON, pointer access, 8192×2048 weight rows; median milliseconds across five fresh processes.[^method] [Raw measurements](benchmark-runs/2026-10-12-encoded-matmul-native.txt).

| Encoding | Activation rows | Direct matmul | Convert 256 rows + BLAS |
|---|---:|---:|---:|
| f16 | 1 | 3.220 | 10.981 |
| f16 | 6 | 4.757 | 11.208 |
| f16 | 46 | 33.767 | 28.997 |
| bf16 | 1 | 3.078 | 11.553 |
| bf16 | 6 | 4.768 | 11.843 |
| bf16 | 46 | 33.620 | 29.732 |

Direct calls use stack-sized tiles and require no f32 weight allocation. The comparison reuses a 256×2048 f32 scratch buffer and includes conversion and every BLAS call. Its Lisp metadata allocation is approximately 35–37 KB per call.[^allocation]

## Contiguous foreign conversion

The same profile widens 16,777,216 f16 values into a Lisp f32 vector. N-D foreign conversion uses the packed converter without an element snapshot.

| Call | Median milliseconds |
|---|---:|
| `nd-convert!`, 1-D foreign input | 1.641 |
| `nd-convert!`, 8192×2048 foreign input | 1.639 |
| Flat `convert!`, foreign input | 1.629 |
| `nd-convert!`, Lisp input | 1.730 |

The baseline source recorded in the raw measurements takes 614 ms for foreign input and allocates a 33,554,448-byte snapshot.[^baseline]

## Run

```sh
sbcl --dynamic-space-size 4096 --script tests/encoded-matmul-bench.lisp
```

The manual **Encoded matmul profile** workflow runs the same profile in five fresh processes on native x86-64 Linux and uploads the results. Run it with `gh workflow run encoded-matmul-profile.yml`. Rosetta measurements describe emulation, not Intel or AMD hardware.

## Limitations

Large activation batches reread weights per activation tile. These kernels do not replace a cache-blocked GEMM for every batch size. Measurements use one matrix size and finite constant operands; they do not establish performance for every inference workload or CPU.

[^method]: Each process checks outputs and reports a warmed median of three calibrated batches. Timings include Lisp validation, pinning and native calls. Weights contain encoded 1.0 and activations contain f32 0.5. The BLAS comparison uses trivial-simd's native GEMM, rather than an external system BLAS.
[^allocation]: The SBCL allocation sample covers 32 calls and excludes foreign memory. Small metadata allocations can fall below the counter's reporting granularity; a zero sample does not prove that a call allocates no Lisp objects.
[^baseline]: The baseline loads the earlier `nd.lisp` against the same native library. The C f16-to-f32 converter is identical for this direction; the measurement isolates the mixed-storage snapshot cost. Baseline rows use the same warmed batch timer in one fresh process.
