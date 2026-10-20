from pathlib import Path
base=Path('/tmp/encoded-format-specialization-2026-10-20/f16-only');work=base/'llama-inference';work.mkdir(exist_ok=True)
s=(base/'inference/inference-bench.lisp').read_text().replace("'(:qwen-f16)","'(:f16)").replace('below 128','below 16').replace('136','24').replace(':start 128',':start 16').replace("'(9625 374 785 6722)","'(9822 374 12366 627)")
(work/'inference-bench.lisp').write_text(s)
s=Path('/tmp/run-f16-only-inference.py').read_text().replace("work=Path('/tmp/encoded-format-specialization-2026-10-20/f16-only/inference')", "work=Path('/tmp/encoded-format-specialization-2026-10-20/f16-only/llama-inference')").replace("source=str(work/variant)+'/'", "source=str(work.parent/'inference'/variant)+'/'").replace("['VERIFY,QWEN-F16,9625;374;785;6722']", "['VERIFY,F16,9822;374;12366;627']")
Path('/tmp/run-format-llama.py').write_text(s)
