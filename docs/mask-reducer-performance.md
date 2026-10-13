# Numeric selection-reducer performance

Native dispatch uses complete-call measurements, including foreign setup, input
access, branch masks, arithmetic and reduction. Slower or unmeasured combinations
retain scalar execution. [Selection semantics](mask-reducers.md) apply to both
paths.

## Method

Five fresh SBCL 2.6.8 processes on Apple M1 measure typed scalar Lisp against
forced native execution. Arrays and programs are prepared before timing. Each
measurement uses the median of three batches after calibration; each batch takes
at least 2 ms. Pointer, copy and direct-view modes cover both float and all eight
integer types, with 32, 256, 1,024, 4,096, 16,384 and 65,536 elements.

| Expression class | Expression |
|---|---|
| Selection | `select(a > b, a, b)` |
| Arithmetic | `select(a > b, a + b, a - b)` |
| Spill stress | `select(a > b, balanced-addition(a, depth=9), b)` |

All eight reducers participate; integer `nrm2` is excluded. Spill stress uses
f32/u64 `sum` and `minimum` at 1,024 and 65,536 elements. Input masks are mixed;
first- and all-lane branch patterns are checked separately for correctness.

## Dispatch gates

ARM64 gates depend on dtype, reducer, pointer/copy/view access and expression
class. Admission requires a median gain of at least 25% and at least 10% gain in
four of five processes at the gate and every larger measured size. The final
public dispatcher is measured separately, including gate lookup.[^gates]

332 of 444 measured combinations meet admission. Selection and arithmetic gates
range from 256 to 65,536 elements. Measured f32 spill `sum`/`minimum` gates start
at 1,024 elements. Unmeasured spill combinations and u64 spill stress retain scalar
execution. Machine types without measured gates retain scalar execution.

Median complete-call results at 65,536 elements from the forced candidate runs:

| Expression | Type / reducer / access | Scalar µs | Native µs | Median speedup |
|---|---|---:|---:|---:|
| Selection | f32 sum, pointer | 1,394.00 | 361.75 | 3.85× |
| Selection | f32 sum, copy | 1,394.00 | 458.38 | 3.05× |
| Selection | f32 minimum, pointer | 673.75 | 367.12 | 1.84× |
| Selection | s8 sum, pointer | 1,169.50 | 296.25 | 3.94× |
| Selection | u64 sum, pointer | 1,164.00 | 361.88 | 3.22× |
| Arithmetic | f32 sum, pointer | 1,558.50 | 533.50 | 2.92× |
| Spill stress | f32 sum, pointer | 88,940.00 | 33,916.00 | 2.62× |
| Spill stress | u64 sum, pointer | 10,012.00 | 38,087.00 | 0.26× — scalar dispatch |

[Five-process candidate data](benchmark-runs/2026-10-13-mask-reducers-arm64.csv)
includes all measurements, including slower cases. In five fresh
[normal-dispatch processes](benchmark-runs/2026-10-13-mask-reducers-gated-arm64.csv),
all 332 enabled combinations retain at least 10% gain in four of five processes
at their gate and every larger measured size. Selected f32 sums at 65,536 elements
measure 3.93× in pointer mode and 3.10× in copy mode; u64 spill sum stays near
scalar-loop speed instead of using the slower VM.

## Validation

| Local target | Result |
|---|---|
| ARM64 SBCL | Full suite: 678,994 checks pass |
| ARM64 CCL | Full suite: 678,974 checks pass |
| ARM64 ECL | Full suite: 683,893 checks pass |
| x86 SBCL under Rosetta | Full suite: 836,455 checks pass |
| ARM64 and x86 C | All 15 SIMD/scalar tests pass |
| ARM64 native reducer harness | AddressSanitizer and UndefinedBehaviorSanitizer pass |

An initial 240-second ECL run reaches bulk-overlap checks without a mismatch
and times out. A fresh timed run completes its suite in 154.495 seconds and
passes. The [example](../examples/extended.lisp) prints a selected total of 10.5.

## Reproducing

```sh
sbcl --dynamic-space-size 4096 --non-interactive \
  --load tests/mask-reducers-bench.lisp
```

The runner forces native execution below dispatch gates and checks each result
against scalar execution. Set `MASK_REDUCER_GATED=1` to measure normal dispatch,
including fallback. Run it five times in separate processes with other
tests and benchmarks stopped.

## Limitations

Measurements cover Apple M1 workloads. Other Lisp implementations, architectures,
mask distributions and expression shapes can have different costs. Gates derive
from SBCL measurements; CCL/ECL checks establish correctness, without a throughput
claim for those implementations. Deep repeated
expressions also retain the [VM sharing limitation](mask-reducers.md#limitations).

[^gates]: [Gate data](../mask-reducer-gates.lisp) lists selection, arithmetic and
    spill thresholds, each in pointer/copy/view order. Metadata is prepared when
    defining a kernel; a hash lookup selects the gate. Calls below the smallest
    gate avoid that lookup. The private test override forces candidate dispatch.
