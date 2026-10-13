# BLAS Level 1

`trivial-simd/blas` provides the standard Level 1 real and complex routines.
The [generic routines](#generic-f32-f16-and-bf16) operate on f32, f16 and bf16.
Names use the BLAS precision prefixes: `s` and `d` for real single and double;
`c` and `z` for complex single and double. Vectors are simple specialized
arrays or [vector views](vector-views.md). Counts are nonnegative, increments
are nonzero, and offsets default to zero. A negative increment visits a span
from its far end to its near end.
Invalid types or spans signal an error before the routine starts.

| Family | Variants | Result |
|---|---|---|
| Swap, copy, AXPY | `s`, `d`, `c`, `z` | Modified vector; swap returns both vectors |
| Scale | `s`, `d`, `c`, `z`; `csscal`, `zdscal` for real factors | Modified vector |
| Dot | `sdot`, `ddot`, `cdotu`, `zdotu`, `cdotc`, `zdotc`, `sdsdot`, `dsdot` | Scalar |
| Euclidean norm | `snrm2`, `dnrm2`, `scnrm2`, `dznrm2` | Real scalar |
| Absolute sum | `sasum`, `dasum`, `scasum`, `dzasum` | Real scalar |
| Maximum absolute index | `isamax`, `idamax`, `icamax`, `izamax` | Zero-based logical index |
| Rotation | `srotg`, `drotg`, `crotg`, `zrotg`, `srotmg`, `drotmg`, `srot`, `drot`, `csrot`, `zdrot`, `crot`, `zrot`, `srotm`, `drotm` | Parameters or modified vectors |

Copy, swap, AXPY, dot and same-type scale call the core [`copy!`, `swap!`](copy.md),
`axpy!`, `dot`, `dotc` and `scale!` at any increment; real `asum`, `nrm2` and `i?amax`
and complex `nrm2` call the core [reductions](reductions.md). Core [strides](api.md#strides)
carry the increments, and negative increments start at the far end of the span.
Complex absolute sums and index searches use `abs(realpart) + abs(imagpart)`;
norms use Euclidean magnitude. Index ties select the first visited element.
The empty index result is zero. `dotu` does not conjugate; `dotc` conjugates
its first vector. `sdsdot` accumulates in double precision, adds a
single-float scalar, then returns a single float. `dsdot` returns a double.

```lisp
(trivial-simd/blas:zdotc n x 1 y 1 :x-offset 2 :y-offset 5)
(trivial-simd/blas:csscal n 2.0f0 x -1)
```

Real `rotg` takes two same-precision scalars and returns `r`, `z`, `c`, `s` as
multiple values. `rotmg` takes `d1`, `d2`, `b1`, `b2` and returns updated
`d1`, `d2`, `b1`, and a five-element parameter vector. `rot` and `rotm`
modify both vectors and return them as two values. `rotm` takes the parameter
vector produced by `rotmg`.[^rotm]
Complex `rotg` returns `r`, the unchanged second input, real `c`, and complex
`s`. `csrot` and `zdrot` use real `c` and `s`; `crot` and `zrot` use real `c`
and complex `s`.

The optional convenience package supplies `axpy!`, `scal!`, `copy!`, `swap!`,
`dot`, and `norm2`. These use unit increments and derive the count from an
optional shared `:start`/`:end` slice. `dot` accepts `:conjugate t` for complex
vectors. Without `:end`, paired vectors have equal lengths.

## Generic f32, f16 and bf16

`axpy`, `scal`, `copy`, `swap`, `dot`, `nrm2`, `asum` and `iamax` use the
same positional arguments and offset keywords as their single-precision
variants. Every generic routine also accepts `:encoding`:

| Storage | `:encoding` | Arithmetic |
|---|---|---|
| `single-float` vector or `:f32` view | `nil` (default) | f32 |
| `(unsigned-byte 16)` vector or `:u16` view | `:f16` | Widen to f32; round once on store |
| `(unsigned-byte 16)` vector or `:u16` view | `:bf16` | Widen to f32; round once on store |

Paired operands share one storage type and encoding. Encoded values are
[float bit patterns](conversion.md#bf16-and-f16), not integers. Encoded stores
round to nearest, ties to even. `copy` and `swap` preserve all stored bits,
including NaN payloads and signed zeros.

```lisp
(trivial-simd/blas:axpy n 2 x 1 y 1 :encoding :f16)
(trivial-simd/blas:asum n y 1 :encoding :f16)
```

`axpy` and `scal` accept real factors and convert them once to single-float.
Zero-factor `axpy` leaves `y` unchanged; zero-factor `scal` writes positive
zeros without reading the visited values. All calls validate their arguments,
including empty calls and zero factors, before writes.

`dot`, `asum` and `nrm2` return single-floats; `iamax` returns an integer
logical index, with the first visited tie winning. Empty reductions return
`0.0f0`; empty `iamax` returns `0`. Generic `nrm2` uses scaled f32 arithmetic
to avoid overflow and underflow from raw squares. Mutators return the modified
vector; `swap` returns both vectors.

Generic calls follow the [bulk overlap rules](api.md#overlap). Their names and
arguments match [cl-gpu/blas](https://github.com/communal-software/cl-gpu/blob/trunk/docs/blas.md),
with CPU storage and snapshot behavior. Run the
[encoded example](../examples/blas-encoded.lisp) for arithmetic and reductions.

## Limitations

Generic encoded arithmetic allocates O(n) temporary f32 storage per call;
copy and swap move raw bits without f32 buffers. Generic names support f32, f16 and
bf16; use the precision-prefixed routines for f64 and complex data.
`iamax` on data containing NaNs is unspecified. Reduction order varies by
backend, so CPU and GPU results may differ in their last bits.

Complex `asum` and `i?amax` and the real-factor scales `csscal` and `zdscal` use
scalar loops; native complex reductions are tracked by
[#45](https://github.com/communal-software/trivial-simd/issues/45). Nonunit core
increments use [direct strided execution](strided-performance.md) on `:native`;
other backends retain staging. Core calls apply the
[bulk overlap rules](api.md#overlap); other BLAS routines retain the
[overlap limitation](blas.md#limitations).

[^rotm]: The flag in the first parameter element selects which matrix entries
    are active. The other four elements follow the reference BLAS order
    `h11`, `h21`, `h12`, `h22`.
