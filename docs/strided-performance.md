# Strided execution and performance

Non-unit 1-D strides on `:native` traverse the original storage without
full-slice gather/scatter buffers. This covers every bulk operation and
reduction, including integer and complex vectors, masks, and encoded
conversions. Required [overlap snapshots](api.md#overlap) remain.

## Dispatch

| Storage | Pointer access | Copy access |
|---|---|---|
| Lisp arrays | Native C where supported; direct Lisp otherwise | Typed Lisp loops |
| Foreign views | Native C where supported; direct Lisp otherwise | Same as pointer access |
| Mixed arrays and views | Native C where supported; direct Lisp otherwise | Direct Lisp traversal |

Unit-stride calls use their existing paths. Signed strides retain the
[logical-count and physical-index rules](api.md#strides). Native arithmetic
uses NEON/SSE2 packs; general strides assemble and scatter their lanes directly.
Float memory paths use packed reverse transfers and bounded
stride-two deinterleaving loads. Production dispatch admits only measured
architecture/type/operation/layout combinations. Shorter calls retain general
execution.[^memory]
Scratch storage stays bounded independently of the element count.[^packs]

Native strided integer operations pack wrapping arithmetic, bounded arithmetic,
comparisons, selections, sums, products, dot products and extreme-index scans.
Complex add/subtract/multiply, scale, AXPY, sum, product and dot reducers use
native packs when storage supports direct pointers.[^complex]

```lisp
(trivial-simd:add! out input 10f0 :end 4 :left-start 7 :left-stride -2
                                        :destination-stride 2)
(trivial-simd:sum input :end 4 :input-start 7 :stride -2)
```

[The runnable example](../examples/strides.lisp) also exercises strided SAXPY.

## Measurements

Complete calls on SBCL 2.6.8, Apple M1, single-float, measured 2026-10-13.
Times are microseconds per call. The baseline uses gathered/staged dispatch
in the same process.[^method]

| Access | Elements | Operation | Gathered | Direct | Speedup |
|---|---:|---|---:|---:|---:|
| pointer | 1,024 | `sum` | 1.141 | 0.754 | 1.51× |
| pointer | 1,024 | `add!` | 2.673 | 1.215 | 2.20× |
| pointer | 65,536 | `sum` | 63.742 | 16.089 | 3.96× |
| pointer | 65,536 | `add!` | 152.512 | 45.198 | 3.37× |
| copy | 1,024 | `sum` | 1.940 | 1.411 | 1.38× |
| copy | 1,024 | `add!` | 5.335 | 2.410 | 2.21× |
| copy | 65,536 | `sum` | 112.813 | 61.918 | 1.82× |
| copy | 65,536 | `add!` | 302.371 | 103.453 | 2.92× |

The measured C and typed array paths allocate fixed-size Lisp/FFI metadata
rather than count-sized element buffers. The raw data includes allocated bytes,
both access modes, strides 1, -1, 2, -2, 3 and -3, and sum, add, dot, AXPY, copy, mask count
and f32-to-f64 conversion.

Raw data: [ARM64 complete calls](benchmark-runs/2026-10-13-strides-arm64.csv).

## Reproducing

Build the [native library](backends.md#build), then run:

```sh
sbcl --dynamic-space-size 4096 --script tests/strided-bench.lisp
TRIVIAL_SIMD_STRIDED_QUICK=1 sbcl --script tests/strided-bench.lisp
```

The quick run measures stride-two sum/add at both sizes and access modes.
The [testing guide](testing.md) describes scalar/SIMD C harnesses and the Lisp
checks for pack boundaries, aliases, capability fallback, and absence of staging.

## Memory-path profiling

Build general and forced-specialized libraries, then run five paired trials:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_STRIDED_PROFILE=ON
cmake --build build
sh tests/strided-profile.sh /tmp/strided-profile
python3 tests/strided-gates.py /tmp/strided-profile/*.csv
```

The profiler compares complete f32/f64 arithmetic and sum/dot calls, including
widened f32 accumulation. It measures strides -1 and ±2, mixed layouts, scalar
broadcasts, offsets, pointer/copy/view access and contiguous/general controls.
The gathered baseline remains available through the original benchmark.

```sh
python3 tests/strided-gates.py --lisp /tmp/strided-profile/*.csv > /tmp/stride-cases.lisp
python3 tests/strided-gates.py --json /tmp/strided-profile/*.csv > /tmp/stride-limits.json
```

Set `TRIVIAL_SIMD_STRIDED_GATES=/tmp/stride-cases.lisp` for targeted normal
validation. Use `TRIVIAL_SIMD_STRIDED_VARIANT=general` and `dispatch` in five
fresh paired processes, with `TRIVIAL_SIMD_STRIDED_PROFILE=1`, a trial number
in `TRIVIAL_SIMD_STRIDED_TRIAL`, and a CSV path in
`TRIVIAL_SIMD_STRIDED_OUTPUT`. The validation includes aliases, copy access,
below-threshold calls and unqualified layout controls.

```sh
python3 tests/strided-gates.py --variant dispatch --limits /tmp/stride-limits.json \
  /tmp/stride-validation/*.csv
```

Admission requires at least 10% median gain and at least 10% gain in four of
five paired trials at the threshold and every larger measured size, for both
pointer and foreign-view access where measured. Unqualified layouts retain
general execution. Final dispatch measurements include gate lookup and require no median
regression above 5% in copy, alias and control cases.[^memory-method]

## Qualified memory dispatch

On Apple M1, normal dispatch admits these single-float layouts. Counts below
these thresholds use general execution. Layouts list destination, left, right
and fourth strides; unused positions remain `1`.

| Operation | Layout | Minimum count |
|---|---|---:|
| negate, abs | (-1, -1, 1, 1) | 4,096 |
| dot | (1, -2, -2, 1) | 4,096 |
| dot, dot-wide | (1, -1, -1, 1) | 1,024 |
| dot, dot-wide | (1, -1, 1, 1) | 1,024 |
| dot, dot-wide | (1, -1, 2, 1) | 1,024 |
| dot | (1, 2, 2, 1) | 1,024 |
| dot-wide | (1, 2, 2, 1) | 4,096 |

Five fresh process pairs on 2026-10-20 verify the exact 11-entry production
table against general execution using the admission criteria above. Every
entry passes the pointer/view gain criteria and copy, alias, short-call and
unqualified-layout controls. Double-float and other layouts retain general
execution. x86-64 specializations remain disabled pending qualifying normal
dispatch measurements.

Evidence: [paired measurements](benchmark-runs/2026-10-20-strided-dispatch-arm64.csv.gz),
[qualified limits](benchmark-runs/2026-10-20-strided-dispatch-arm64-limits.json),
[environment](benchmark-runs/2026-10-20-strided-dispatch-arm64-environment.json).
These complete-call measurements do not establish inference-level speedups.

## Limitations

- Specialized float transfers require complete-call admission on each
  architecture. Other types and unqualified layouts use general memory-lane
  assembly. The admission scope is recorded in
  [#77](https://github.com/communal-software/trivial-simd/issues/77).
- Non-native backends retain gathering or view staging for non-unit strides.
- Integer division and exact conversions unsupported by native packs use scalar
  evaluation. Complex square roots, reciprocals, magnitudes and norms use direct
  Lisp arithmetic.
- Mixed storage in copy mode uses generic element access and can box values.
- Measurements cover one M1. ARM64 and x86-64 correctness checks do not establish
  performance on other machines.

[^packs]: General native operations use at most sixteen logical elements per
    transfer. Float arithmetic uses direct SIMD-width loads/stores; reduction
    accumulators persist across packs. Heap scratch is unnecessary. C harnesses
    disable heap allocation and test SIMD/scalar builds.
[^complex]: SBCL complex arrays expose interleaved components to C. Other Lisp
    implementations use direct Lisp access for complex arrays; foreign complex
    views supply interleaved storage directly. Missing native capabilities also
    select direct Lisp traversal.
[^method]: Each timing is the median of three warmed batches calibrated to at
    least 50 ms. Allocated bytes average 1,000 additional calls on SBCL and include
    metadata and returned scalar values; allocation counters have coarse
    granularity. The benchmark temporarily disables direct dispatch for its
    baseline and restores it after each batch. Floating-point reducers retain
    their documented backend-dependent accumulation order.

[^memory]: Reverse transfers preserve logical lane order. Stride-two loads read
    gaps only inside the validated span; final positive packs and first negative
    packs use lane assembly when needed. Destination reads and inputs sharing the
    destination's physical span use individual stride-two loads. Stores write only visited elements,
    preserving concurrent updates to disjoint interleaved slices. Scalar tails,
    snapshots and reduction accumulation order are unchanged.

[^memory-method]: Profiling uses three warmed batches calibrated to at least
    5 ms and alternates variant order across five fresh process pairs. Allocation
    counters average 32 extra calls and have coarse granularity. Profiling
    libraries export distinct symbols; the harness disables CFFI compiler macros
    and recompiles only its strided caller so each binding reaches its intended
    library. General and specialized libraries use the same compiler flags.
