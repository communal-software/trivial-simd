import subprocess,json,hashlib
from pathlib import Path
root=Path('/Users/george/git/trivial-simd');work=Path('/tmp/encoded-tile-sweep-2026-10-20');work.mkdir(exist_ok=True)
source=(root/'native/encoded-matmul.c').read_text()
for width in (4,8,12,16):
 p=work/f'encoded-{width}.c';p.write_text(source.replace('DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)',f'DEFINE_ENCODED_TILE(encoded_tile1, 1, {width})',1))
 subprocess.run(['cc','-O3','-ffp-contract=off','-dynamiclib','-I'+str(root/'native'),str(p),'-o',str(work/f'tile-{width}.dylib')],check=True)
subprocess.run(['cc','-O3','-ffp-contract=off','/tmp/encoded-tile-sweep.c','-o',str(work/'sweep')],check=True)
with (work/'results.csv').open('w') as out:
 subprocess.run([str(work/'sweep'),str(work)],stdout=out,check=True)
meta={'revision':subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),'compiler':subprocess.check_output(['cc','--version'],text=True),'flags':['-O3','-ffp-contract=off'],'method':'Five rotating width sweeps per encoding/shape in one process. Each cell is median of three batches calibrated to at least 20 ms, after warmup. Every candidate output must exactly match the four-output baseline for nonconstant finite fixtures.','files_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in work.iterdir() if p.is_file()}}
(work/'metadata.json').write_text(json.dumps(meta,indent=2)+'\n')
