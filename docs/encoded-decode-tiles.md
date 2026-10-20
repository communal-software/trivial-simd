# ARM64 encoded decode tiles

ARM64 single-row encoded matmul uses four output rows per tile. Wider 8/12/16-output tiles do not establish a Qwen inference improvement in this profile, so no wider tile is selected. F16/BF16 accumulation order, multi-row tiles and x86 kernels are unchanged.

## Isolated shape sweep

Positive percentages mean less time than the four-output tile. Values are medians of five within-round comparisons. Nine shapes cover Qwen/Llama projections and vocabulary heads; selected results are below, with all 360 timings in the [evidence](benchmark-runs/2026-10-20-encoded-decode-tiles/).[^sweep]

| Encoding | Outputs × inputs | 8 outputs | 12 outputs | 16 outputs |
|---|---|---:|---:|---:|
| f16 | 3072 × 1024 | +0.5% | -1.7% | -4.0% |
| f16 | 151936 × 1024 | -40.7% | -24.4% | -28.4% |
| f16 | 8192 × 2048 | +10.1% | +11.2% | +11.7% |
| f16 | 128256 × 2048 | +10.2% | +11.5% | +11.9% |
| bf16 | 3072 × 1024 | +0.4% | -0.7% | -2.0% |
| bf16 | 151936 × 1024 | -36.9% | -22.9% | -32.9% |
| bf16 | 8192 × 2048 | +6.8% | +8.9% | +10.1% |
| bf16 | 128256 × 2048 | +7.2% | +9.6% | +10.7% |

Wider tiles barely help the small Qwen projections and slow its 151936 × 1024 head. Some larger Llama shapes improve, but those isolated gains do not establish a useful global tile choice or a Llama inference speedup.

## Whole Qwen comparison

Three fresh-process pairs compare four and eight outputs in alternating order. Both use bulk tensor copying, automatic dispatch, no tensor executor and one native thread. Model: Qwen3 0.6B F16; prompt: 128 tokens. Eight outputs is the closest candidate on the smaller projections.

The first pair records 138.79 versus 141.68 ms for cached decode and 2947.43 versus 3044.00 ms for four-token generation. None of the three pairs reports an improvement for the eight-output tile.

Background load limits interpretation. A macOS XProtect process is active at the end of the second candidate process. Later runs also have slower prefill, although its multi-row kernel is identical. These results reject admission of the candidate; they do not establish a precise causal slowdown. All 18 timing rows remain in the evidence, including the noisy runs.

## Validation

All candidate widths match the baseline output exactly for the sweep's finite, nonconstant fixtures. Reference and ASan/UBSan checks pass for all four widths in SIMD and scalar builds. The retained single-row test sweeps 0–35 output rows and 0–69 input elements with pointer offsets, padded weights and output sentinels; existing exceptional-value and FPCR tests remain in place.

All 19 native CTests pass. Every measured generation returns `(9625 374 785 6722)` and finishes at the four-token limit.

## Reproduction and evidence

[Archived sources, runners, logs, raw timings, summaries and hashes](benchmark-runs/2026-10-20-encoded-decode-tiles/) identify the exact inputs. The sweep compares temporary shared libraries built with `-O3 -ffp-contract=off`; inference uses matching full Release builds from the same Git revision and separate ASDF caches. Only the ARM64 single-row tile invocation differs.

The archived runners retain the measured checkout paths. Place `encoded-tile-sweep.c` in `/tmp/` and run `run-encoded-tile-sweep.py` for the isolated sweep. Place the archived `copy-inference-bench.lisp` in `/tmp/`, then run `build-encoded-inference.py` followed by `run-encoded-inference.py` for the Qwen comparison. Native builds are temporary; the repository's kernel is not modified.

Inference timings use one warmup and a median of three calls with full collection before each call. Loading, pinned model SHA checks and expected-token preparation are untimed. Prefill has no KV cache; decode overwrites one position after a prepared prefix; generation resets its session and includes prefill plus four output tokens.

## Limitations

This is one Apple M1 with 8 GiB RAM, macOS 15.7.5 and SBCL 2.6.8. Two unrelated CPU-bound jobs remain active, and background scans interfere with some inference runs. Process and memory observations cover full processes, including setup. The sweep is a rotating in-process experiment, not five independent processes. BF16 has primitive measurements but no full-model comparison here.

This profile does not test shape-dependent tile dispatch, other CPUs, GPU execution or alternative accumulation schemes. Larger activation-batch blocking and x86 tuning remain in [#74](https://github.com/communal-software/trivial-simd/issues/74). Weight conversion/loading within the four-output kernel needs a separate experiment before selecting another implementation.

[^sweep]: One activation row; widths rotate across five rounds for each shape/encoding. Each cell reports three calibrated batches of at least 20 ms after warmup. F16/BF16 weights and activations vary over finite values. Every width's output is checked against the baseline before timing; positive reduction is `100 × (1 − candidate/baseline)`. Kernel timings exclude Lisp validation and model allocation.
