# Numeric selection reductions

Kernel reducers accept `select` expressions and evaluate only the chosen branch
at each element. This applies to `sum`, `asum`, `nrm2`, `minimum`, `maximum`,
`argmin`, `argmax`, and `prod` for real/integer inputs. Integer `nrm2` signals an
error.

```lisp
(trivial-simd:define-kernel selected-total (a b)
  (trivial-simd:sum (trivial-simd:select (> a b) a (/ a b))))
```

An element with `a > b` contributes `a`, even when `b` is zero. Otherwise it
contributes `a / b`; errors in that selected division follow scalar Lisp behavior.
Selections can nest, and inputs accept the usual kernel slices and foreign views.
See the [runnable example](../examples/extended.lisp).

## Results

| Behavior | Contract |
|---|---|
| Empty slice | Typed zero for `sum`/`asum`/`nrm2`, typed one for `prod`, `NIL` for extrema |
| Integer arithmetic | Wraps at the input width, including `asum` of the most negative value |
| Equal extremes | First element wins; selected signed-zero bits are preserved |
| Argument extremes | `:start` plus the position within the evaluated slice; per-input offsets do not change that index |
| Float accumulation | Uses the existing reducer precision; addition order can differ from scalar Lisp |

Inputs are read without modification. Existing overlap snapshots and view staging
continue to apply when these reducers appear in larger kernel executions.

## Native execution

Eligible native calls use packed comparison and arithmetic, including full-width
SIMD for mixed true/false masks. Inactive lanes receive safe operands before
arithmetic; their results do not overwrite active branch values. Entirely inactive
branches perform no arithmetic.[^execution]

Native arithmetic/domain errors cause scalar replay. Floating-point exception
handling preserves the caller's environment before replay or return.[^errors]
One invocation owns its spill and branch-mask scratch across 256-element blocks;
concurrent invocations share no scratch. Empty calls allocate none.

[Complete-call measurements](mask-reducer-performance.md) determine size gates.
Calls below a gate, without the required native capability, or without a measured
combination use scalar execution. SBCL numeric mask reducers remain scalar.

## Limitations

- The native reducer evaluates blocks before the final reduction. Fusion is
  tracked in [#48](https://github.com/communal-software/trivial-simd/issues/48).
- General SBCL mask-reducer integration is tracked in
  [#68](https://github.com/communal-software/trivial-simd/issues/68).
- Repeated pure subexpressions retain their VM work; sharing is tracked in
  [#70](https://github.com/communal-software/trivial-simd/issues/70).
- NaNs, infinities and non-default floating-point modes retain the
  [kernel numerical limitations](kernels.md#limitations).

[^execution]: Structured branch bytecode retains parent and false-lane masks in
    two reusable numeric scratch slots per live selection. Mixed-lane operations
    sanitize operands (`0 / 1` for division and `log(1)` for logarithms), execute
    existing packed arithmetic, and merge only active results. Transcendentals
    retain their existing scalar libm routines.
[^errors]: Native calls save the floating-point environment and suppress traps
    while checking invalid operations, division by zero, overflow and underflow.
    They restore the environment before scalar replay, which reproduces the
    Lisp implementation's conditions. Platforms without environment isolation
    select the scalar path. Robust norm rescaling can use several invocations.
