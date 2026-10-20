# Encoded conversion-mode specialization

The runtime retains dynamic conversion-mode selection in the four-output ARM64 kernel. A native-F16-only candidate reduces Qwen cached-decode time by 2.1%, but generation changes by only 0.3% and a Llama projection regresses. It is not admitted without valid cross-model measurements; see [Limitations](#limitations).

## Candidates and Qwen results

Both candidates select conversion mode once per call, preserving tile width, lane accumulation order, NaN handling and the existing FPCR gate. The broad candidate specializes BF16, portable F16 and native F16. The narrower candidate specializes native F16 only; BF16 and portable F16 use the generic kernel.

Qwen3 0.6B F16, 128 prompt tokens, serial execution, one native thread. Positive reductions mean less time; values are medians of three paired comparisons.[^paired]

| Candidate | Prefill reduction | Cached decode reduction | Four-token generation reduction |
|---|---:|---:|---:|
| All modes specialized | 0.47% | 4.16% | 0.98% |
| Native F16 only | 0.06% | 2.11% | 0.29% |

The narrow candidate's decode reductions are 2.03%, 2.36% and 2.11%; generation changes are −0.02%, +0.70% and +0.29%. All measured generations return `(9625 374 785 6722)` at the four-token limit.

## Primitive results and assembly

Five rotating rounds cover nine Qwen/Llama shapes in F16 and BF16: 180 timings per candidate. Every candidate output exactly matches the dynamic baseline for the finite nonconstant fixtures. Small F16 projections change little, despite the whole-model decode differences.

The broad candidate slows several large BF16 shapes by approximately 17–42%. The narrow candidate avoids those BF16 regressions, but its 8192 × 2048 F16 projection takes about 4.1% more time. No shape-dependent policy is added.

AppleClang assembly confirms that the baseline checks conversion mode in the inner four-element loop. The specialized loops select it before iteration. Removing that branch does not establish a general primitive speedup or assign a precise percentage of time to conversion versus loading: specialization also changes generated code and register allocation. The exact assembly is archived with the source.

## Llama control

The narrow candidate has an attempted 16-token Llama 3.2 1B F16 control. Its baseline prefill reaches 5974 ms and cached decode 4046 ms, versus approximately 957 ms and 257 ms in the earlier serial profile. System observations show substantial compression/page-in activity. The control is stopped as unsuitable for resolving a small kernel difference; zero Llama timing rows are accepted. Its partial log and cancellation observation remain in the evidence.

## Validation and reproduction

Each candidate and baseline passes reference checks plus ASan/UBSan in SIMD and scalar builds. Each full Release build passes both native encoded-matmul CTests. Coverage includes all encoded bit patterns, tails, offsets, padded weights, output sentinels, exceptional values and the FZ16 fallback.

[Sources, assembly, runners, raw results, summaries and hashes](benchmark-runs/2026-10-20-format-specialization/) preserve 360 primitive timings and 36 accepted inference timings. `before.c` and `after.c` identify the broad candidate; `f16-only/` identifies the narrower candidate. Both full-model comparisons use matching Release builds from the same Git revision and separate ASDF caches. Bulk tensor copying is enabled in both variants.

The archived scripts retain the measured checkout and `/tmp/` paths. `create-encoded-specialized.py` and `create-f16-only-specialized.py` generate candidates from the recorded baseline. `validate-format-specialization.py` accepts the candidate directory; `sweep-format-specialization.py` runs the archived C driver. Place the archived `sweep.c` at `/tmp/encoded-format-specialization-2026-10-20/sweep.c` and `copy-inference-bench.lisp` in `/tmp/`. The corresponding `build-*-inference.py` and `run-*-inference.py` scripts reproduce each Qwen comparison. Do not include the aborted Llama control in timing summaries.

Each inference case uses one warmup and the median of three calls, with full collection before each. Model loading, pinned hash checks and expected-token preparation are untimed. Prefill has no KV cache; decode overwrites one position after a prepared prefix; generation resets its session and includes prefill plus four output tokens.

## Limitations

This is one Apple M1 with 8 GiB RAM, macOS 15.7.5 and SBCL 2.6.8. Two unrelated CPU-bound jobs remain active. The primitive sweeps use rotating in-process comparisons, while model comparisons use alternating fresh processes. These measurements do not establish performance on other machines, formats, contexts or threading settings.

The Llama control is memory-limited and supplies no valid candidate comparison. Admission of the narrow candidate requires sufficiently free memory and a controlled cross-model measurement: [#87](https://github.com/communal-software/trivial-simd/issues/87). The runtime stays unchanged while that validation is pending.

[^paired]: Each pair reports `100 × (1 − candidate/baseline)`. The table uses the median paired reduction; independent timing medians can give a different ratio. No accepted Qwen sample is discarded. The primitive comparisons use three calibrated batches per cell after warmup, with a minimum batch duration of 20 ms.
