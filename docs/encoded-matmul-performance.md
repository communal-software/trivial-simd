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

## Single-row ARM64 tiles

Single-row decode uses four-output tiles. The [wider-tile profile](encoded-decode-tiles.md) compares 8/12/16 outputs on Qwen and Llama shapes and checks complete Qwen inference. It does not establish a wider global tile choice. [Conversion-mode specialization](encoded-format-specialization.md) records a modest native-F16 Qwen decode gain with cross-model validation pending.

## Native x86-64

Intel Xeon 6973P-C GitHub runner, SBCL 2.6.9, native pointer access; the same matrix size and five-process method. Encoded matmul uses SSE2; the native BLAS comparison uses its available AVX/FMA path. [Raw measurements](benchmark-runs/2026-10-12-encoded-matmul-linux.txt) and [profile run](https://github.com/communal-software/trivial-simd/actions/runs/38310528630).

| Encoding | Activation rows | Direct matmul | Convert 256 rows + BLAS |
|---|---:|---:|---:|
| f16 | 1 | 9.375 | 17.500 |
| f16 | 6 | 23.000 | 17.750 |
| f16 | 46 | 151.001 | 34.000 |
| bf16 | 1 | 2.625 | 12.000 |
| bf16 | 6 | 11.375 | 12.125 |
| bf16 | 46 | 76.000 | 28.000 |

Times are milliseconds. This virtualized runner measures native x86-64 instructions, rather than Rosetta emulation. The [separate Rosetta record](benchmark-runs/2026-10-12-encoded-matmul-rosetta.txt) describes Apple M1 emulation and is not an Intel throughput result.

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

Large activation batches reread weights per activation tile. These kernels do not replace a cache-blocked GEMM for every batch size. Measurements use one matrix size and finite constant operands; they do not establish performance for every inference workload or CPU. Large-batch cache blocking and guarded x86 F16C/AVX paths are tracked in [#74](https://github.com/communal-software/trivial-simd/issues/74).

[^method]: Each process checks outputs and reports a warmed median of three calibrated batches. Timings include Lisp validation, pinning and native calls. Weights contain encoded 1.0 and activations contain f32 0.5. The BLAS comparison uses trivial-simd's native GEMM, rather than an external system BLAS.
[^allocation]: The SBCL allocation sample covers 32 calls and excludes foreign memory. Small metadata allocations can fall below the counter's reporting granularity; a zero sample does not prove that a call allocates no Lisp objects.
[^baseline]: The baseline loads the earlier `nd.lisp` against the same native library. The C f16-to-f32 converter is identical for this direction; the measurement isolates the mixed-storage snapshot cost. Baseline rows use the same warmed batch timer in one fresh process.
