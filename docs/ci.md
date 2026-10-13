# CI

GitHub Actions runs a small set of jobs automatically and the full Linux and Windows matrix on
request. macOS runs locally; see
[local platform runs](testing.md#local-platform-runs). Lisp errors return a
failing process status in Roswell test steps. SBCL jobs reserve a 4 GiB heap
for [cold test compilation](testing.md).

## When jobs run

| Trigger | Jobs |
|---|---|
| Push to `trunk` or pull request | Tier 1, chosen by changed paths |
| Docs-only change | None |
| `[ci full]` in the latest commit message | Full matrix |
| `ci-full` label on a pull request | Full matrix on every push while labelled |
| Tag `v*` | Full matrix |
| Manual dispatch | Full matrix, narrowed by inputs |

New pushes cancel the previous run for the same branch or pull request.

## Tiers

| Tier | Jobs | Runs |
|---|---|---|
| 1 | SBCL / Linux, Lisp fallback / Linux | Any code change |
| 1 | ECL / Linux | Native code changes[^focus] |
| 2 | Other Linux and Windows combinations | Full matrix only |

The job list lives in [`.github/ci-matrix.json`](../.github/ci-matrix.json).
[`.github/scripts/plan.sh`](../.github/scripts/plan.sh) selects from it.

CCL runs locally only; neither the main matrix nor the manual profiling workflow
starts CCL jobs. See [local diagnostics](testing.md#test-diagnostics).

## Running a slice

```sh
gh workflow run ci.yml -f os=windows            # every Windows job
gh workflow run ci.yml -f lisp=ecl              # ECL on every OS
```

`os` is `all`, `linux`, or `windows`. `lisp` is matched against the
Lisp name in the matrix (`sbcl`, `ecl`).

## Before dispatching

Run the suite locally first; see [testing](testing.md). A local run on one
platform catches most failures; dispatch a slice for the platform you cannot
run.

## Cost

Private repositories bill macOS minutes at about ten times and Windows at about
twice the Linux rate; public repositories use standard runners for free.[^cost]

## BLAS measurements

The **FMA profile** workflow also has a `blas` job. It builds the BLAS profile
with each tile and blocking override, runs it twice per build, then runs the
SBCL BLAS benchmark with native kernels always dispatched
(`BLAS_BENCH_THRESHOLD=1`) and with Lisp kernels to find the threshold. Output
lands in the job logs, and `lscpu` is recorded first because runner CPUs vary.
See [BLAS profiling](testing.md#blas-profiling).

## FMA measurements

Run the **FMA profile** workflow manually for x86-64 Linux correctness checks
and repeated SBCL and ECL FMA measurements. It includes the native
hardware-selected and forced software profiles. Timing results appear in the
job logs; see [FMA profiling](testing.md#fma-profiling) for local commands.

## Encoded matmul profile

The manual **Encoded matmul profile** workflow builds and checks the native library on x86-64 Linux, then runs five fresh SBCL processes comparing direct encoded matmul with 256-row conversion plus BLAS. It also measures contiguous foreign N-D conversion. The artifact contains machine details and complete-call timings.

```sh
gh workflow run encoded-matmul-profile.yml
```

See [the measurement method](encoded-matmul-performance.md).

## Limitations

CCL runs require local verification. Remaining x86-64 CCL test setup and
lifetime-stress overhead is tracked in
[#56](https://github.com/communal-software/trivial-simd/issues/56).

[^focus]: Paths matching `native/`, `native.lisp`, `backends.lisp`,
    `kernel.lisp`, `kernel-math.lisp`, or `CMakeLists.txt`. The path lists are in the `paths`
    section of the matrix file.
[^cost]: GitHub's current rates are in its Actions billing documentation.
