# Conversion and mask performance

Large pointer-mode conversions use native SIMD. Small and copy-mode numeric
conversions use typed Lisp loops; the native size gate is 32,768 elements.
SBCL s32-to-f32 conversion uses in-process SSE2 for its Lisp path and the
native entry point for eligible large pointer calls. Direct foreign views use the
available native conversion entry point at every size.

## Coverage

| Operation | Native SSE2/NEON | SBCL SSE2 |
|---|---|---|
| Integer to float | 8/16/32-bit sources to f32/f64; NEON 64-bit sources to f64 | s32 to f32 |
| Saturating integer narrowing | 16-bit to 8-bit and 32-bit to 16-bit, both signs | Typed Lisp fallback |
| f64 ↔ bf16/f16 | Packed normal lanes, scalar exceptional lanes | Native library |
| Comparisons and selection | All ten real/integer types, bulk and VM | Both floats and integers through 32 bits; bulk f32 selection stays scalar |
| Byte-mask count/any/all | Packed nonzero-byte counting | Packed nonzero-byte counting |
| Spilling mask kernels | One scratch allocation per call | Supported expressions compile in-process |

The [conversion rules](conversion.md) and [mask rules](masks.md) apply to packed
and scalar execution alike.

## Complete ARM64 calls

These are median speedups from five SBCL processes using native pointer access.
Values above 1× beat the baseline. Numeric conversion uses a typed loop baseline;
mask operations use the Lisp backend.

| Conversion | 32 elements | 1,024 | 65,536 |
|---|---:|---:|---:|
| s8 → f32 | 0.13× | 0.45× | 5.29× |
| u16 → f64 | 0.11× | 0.34× | 2.49× |
| s32 → f32 | 0.12× | 0.37× | 5.13× |
| u32 → f32 | 0.12× | 0.39× | 5.26× |
| s64 → f32 | 0.12× | 0.41× | 1.70× |
| u64 → f64 | 0.12× | 0.41× | 3.07× |
| s16 → u8 | 0.15× | 0.47× | 13.30× |
| u32 → u16 | 0.14× | 0.45× | 7.50× |

Small conversion calls include API overhead even when they use typed Lisp loops.
The large-array gate avoids paying native setup for those calls. Copy-mode
numeric conversion retains typed Lisp execution.

At 65,536 elements:

| Type | Bulk compare | Bulk select | Mask kernel | Select kernel | Count kernel | Repeated selection kernel |
|---|---:|---:|---:|---:|---:|---:|
| f32 | 6.52× | 15.42× | 65.65× | 42.70× | 46.20× | 15.44× |
| s8 | 52.55× | 41.77× | 136.17× | 96.37× | 109.42× | 36.01× |
| u64 | 3.32× | 4.95× | 17.10× | 15.48× | 15.49× | 5.87× |

Byte-mask counting measures about 313× the Lisp loop. The repeated-tree column
uses the sharing profile below. Its depth-seven selection tree followed by
count shares pure nodes and executes without spilling.

## Shared mask programs

The [sharing lowerer](kernel-sharing.md) reduces the repeated selection/count
program from 321 instructions to 11. At 65,536 elements, five-process median
complete-call results are:

| Type | Sharing disabled, pointer µs | Shared, pointer µs | Pointer speedup | Copy speedup |
|---|---:|---:|---:|---:|
| f32 | 2,698.25 | 91.94 | 29.27× | 14.89× |
| s8 | 1,119.39 | 36.50 | 30.59× | 9.05× |
| u64 | 7,430.00 | 224.69 | 33.04× | 23.43× |

Every repeated selection case improves in all five runs at 32, 1,024, and
65,536 elements, in both access modes. Nonrepeated selection, arithmetic, and
lazy-reducer controls retain identical bytecode. Their largest median slowdown
is 2.26%; none exceeds the 5% regression gate.

The repeated program uses zero scratch slots and allocations. Sharing-disabled
execution uses one spill, one reload, and one scratch allocation per call:

| Type | Sharing-disabled peak scratch bytes | Sharing-disabled executed scratch copy bytes |
|---|---:|---:|
| f32 | 1,024 | 524,288 |
| s8 | 256 | 131,072 |
| u64 | 2,048 | 1,048,576 |

Shared execution has zero scratch copy traffic for this case. Repeated arithmetic
inside a lazy reducer shrinks from 15 instructions to 13 and retains one spill,
one reload, and the same scratch allocation. At 65,536 elements, u64 measures
1.34× pointer and 1.27× copy speedup over sharing-disabled lowering. The f32/s8
median gains are about 1–2%, within the small variations between runs.[^sharing]

See the [five-process raw measurements](benchmark-runs/2026-10-13-kernel-sharing-arm64.csv)
and [reproduction commands](kernel-sharing.md#measurement).

## Emulated x86 calls

These are medians from five fresh SBCL processes under Rosetta, at 65,536
elements. Both backends use native conversion for eligible large pointer calls.

| Operation | Native pointer | SBCL |
|---|---:|---:|
| s32 → f32 | 4.72× | 3.83× |
| s16 → u8 | 12.74× | 12.55× |
| Bulk f32 compare | 5.09× | 2.27× |
| Bulk s8 compare | 35.12× | 2.78× |
| Bulk f32 select (SBCL scalar) | 9.03× | 0.95× |
| Bulk s8 select | 30.07× | 5.46× |
| f32 mask kernel | 49.63× | 8.23× |
| f32 select kernel | 44.50× | 13.73× |
| s8 mask kernel | 110.35× | 12.40× |
| s8 select kernel | 69.29× | 31.49× |

The packed bulk f32 selection candidate measures 0.91× its typed baseline;
public SBCL bulk f32 selection retains that typed loop. Its mask kernels use
packed comparisons and selection without byte-mask expansion. SBCL u64 masks
retain scalar execution. These are emulated costs, not physical x86 results.

## Numeric conversion crossover

With the native gate disabled for the probe, median complete-call speedups are:

| Pair | 4,096 | 8,192 | 16,384 | 32,768 |
|---|---:|---:|---:|---:|
| s8 → f32 | 1.25× | 2.36× | 3.32× | 4.25× |
| u16 → f64 | 0.94× | 1.38× | 2.12× | 2.29× |
| s32 → f32 | 1.31× | 1.95× | 3.68× | 3.88× |
| s64 → f32 | 0.77× | 0.96× | 1.34× | 1.41× |
| s16 → u8 | 1.67× | 2.71× | 5.55× | 8.69× |

At 32,768 elements every measured pair beats its typed baseline in all five
processes. The conservative shared gate retains those gains; earlier crossings
differ by pair. Direct views retain their native path independently of this gate.

## Native encoded conversion

At 65,536 elements, median speedup over the scalar bit-conversion loop is:

| Direction | Nearest even | Truncate | Floor | Ceiling |
|---|---:|---:|---:|---:|
| f64 → bf16 | 5.48× | 5.89× | 4.70× | 4.68× |
| f64 → f16 | 5.57× | 5.87× | 4.62× | 5.11× |

Exact widening has a median speedup of **4.11×** for bf16 → f64 and **3.39×**
for f16 → f64. These inputs mostly contain normal values; exceptional lanes
use scalar bit conversion.

The optimized C baseline is competitive for ordinary numeric conversion and
bulk comparison. Explicit packed bulk comparisons measure around 0.8–1.0×
that baseline on this host. Complete Lisp-call measurements determine the
numeric conversion size gate;
native-loop results alone do not show its benefit.

## Measurement method

The native profiler compares explicit packed paths with typed C loops. Clang
may vectorize those loops; this measures against optimized C rather than
forcing an artificially scalar baseline. The Lisp profiler measures complete
public calls against typed conversion loops or the Lisp kernel backend.
Pointer and copy modes include their normal dispatch and staging costs.

Each measurement warms the function, calibrates to batches of at least 50 ms,
and takes the median of three batches. Results compare five fresh processes
at 32, 1,024 and 65,536 elements. Inputs and destinations are allocated outside
timing; results are checked outside timing. Conversion crossover probes use
4,096, 8,192, 16,384 and 32,768 elements with the native size gate disabled.

The local host is an Apple M1. ARM64 runs measure native NEON; x86-64 runs use
Rosetta and measure emulated SSE2. Rosetta results validate execution and show
local costs; they do not predict physical Intel or AMD performance.[^versions][^inputs]

## Limitations

Sharing does not cross lazy branch transitions; see the
[sharing limitations](kernel-sharing.md#limitations). The sharing measurements
cover Apple M1; physical x86 performance is unmeasured.

Remaining conversion pairs, exceptional encoded lanes and platform-specific
size gates are tracked in [#67](https://github.com/communal-software/trivial-simd/issues/67).
Additional in-process SBCL conversions and 64-bit masks are tracked in
[#68](https://github.com/communal-software/trivial-simd/issues/68).
Local CCL x86-64 verification is subject to the
[Rosetta testing limitations](testing.md#limitations).

Numeric selection reductions have separate native dispatch gates and
[complete-call measurements](mask-reducer-performance.md). Unmeasured and
slower combinations retain scalar execution; see
[selection-reducer limitations](mask-reducers.md#limitations).

[^versions]: Release native builds use Apple Clang with CMake. Lisp measurements
    use SBCL 2.6.8. The test suite also covers CCL 1.13 and ECL 26.5.5.

[^sharing]: The sharing profile uses five fresh SBCL 2.6.8 processes with inputs
    2 and 1, alternating method order. Definitions, inputs, and outputs are
    prepared outside timing; results are checked against Lisp. Each function is
    warmed and measured with three calibrated batches of at least 50 ms. Tables
    use median times and median per-process speedups. Lazy reducer profiles force
    native dispatch to compare lowering; ordinary dispatch gates are unchanged.
    A separately instrumented native library counts scratch allocations and
    executed scratch copies outside timing. See the
    [traffic accounting rules](kernel-sharing.md#measurement).

[^inputs]: Lisp conversion inputs contain 127 in their declared integer type.
    Mask inputs contain 2 and 1, with predictable selections. Native C conversion
    inputs cover the source integer range; encoded inputs mostly contain normal
    values. Data-dependent boxing, branch and exceptional-lane costs can differ.
