# Native mask expression sharing

Native mask kernels compute identical pure subexpressions once per execution
region. Shared values remain available until their last use, in registers or
private invocation scratch storage. Public kernel syntax and overlap rules are
unchanged.

## Repeated expressions

```lisp
(trivial-simd:define-kernel repeated-selection (a b)
  (trivial-simd:select (> (+ a b) b)
                      (+ a b)
                      (+ (+ a b) (+ a b))))
```

The native program shares `(+ a b)`. Its arithmetic retains the input type's
wrapping and floating-point rules. Structural sharing preserves operand order;
it does not reassociate arithmetic or simplify selections. Constants with
different float precision, zero sign, or NaN payload remain distinct.

## Lazy selection reducers

[Numeric selection reducers](mask-reducers.md) share expressions within each
straight-line branch region. Branch transitions end a sharing region. A value
computed with one active-lane mask is not reused as another region's result.
Unselected branches and short-circuit error handling retain their normal rules.

Live parent values are saved before entering a branch. The selected branch
results merge before parent lanes resume. Scratch remains private to each call;
concurrent calls do not share computed values.[^allocation]

Programs with no repeated computations retain the existing lowerer. Ordinary
numeric, complex, row, and declared-input kernels retain their existing lowering.
Dispatch gates for numeric selection reducers are unchanged.

## Measurement

The [conversion and mask profile](conversion-mask-performance.md) records
complete-call measurements. The sharing profiler compares identical definitions
with sharing disabled and enabled, plus the Lisp backend. It measures repeated
selection/count, repeated lazy arithmetic, and nonrepeated controls.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_KERNEL_SHARING_PROFILE=ON
cmake --build build --target native_kernel_sharing_profile
SHARING_PROFILE_COPY=1 SHARING_PROFILE_TRIAL=0 \
  sbcl --dynamic-space-size 4096 --script tests/kernel-sharing-bench.lisp
```

Use trials `0` through `4` in five fresh processes on an idle machine. The trial
number alternates measurement order. `SHARING_PROFILE_COPY=1` includes both
pointer and copy access; otherwise the profiler measures pointer access only.
`TRIVIAL_SIMD_SHARING_PROFILE_LIBRARY` selects the instrumented library path
on other platforms.

The profiler reports instructions, spills/reloads, peak scratch bytes, allocations,
and executed scratch copy traffic. Instrumented calls run outside timing; timed
calls use the normal native library.[^traffic]

## Limitations

Sharing does not cross lazy branch transitions. Repeated selections in different
regions remain separate computations. Floating-point any/all fallback and
platform coverage retain the [mask limitations](masks.md#limitations).

[^allocation]: Shared-value register allocation uses remaining uses and spills
    the unpinned value with the farthest next use. Scratch slots are reused after
    their last use. Bytecode addressing retains the
    [scratch limitations](kernel-spilling.md#limitations).

[^traffic]: The single-threaded instrumented library counts allocations and
    `memcpy` reads/writes involving scratch storage, including lazy validation
    frame copies. Direct branch-mask stores and reads are excluded. Results are
    checked against Lisp before warmed, calibrated median timings.
