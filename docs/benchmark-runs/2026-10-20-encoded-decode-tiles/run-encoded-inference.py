import os,subprocess,json,csv,hashlib
from pathlib import Path
work=Path('/tmp/encoded-tile-inference-2026-10-20')
p=work/'inference-bench.lisp';s=p.read_text().replace("(dolist (kind '(:qwen-f16 :qwen-q8))", "(dolist (kind '(:qwen-f16))");p.write_text(s)
def snapshot():
 return {c:subprocess.run(c.split(),capture_output=True,text=True).stdout for c in ('vm_stat','sysctl vm.swapusage','ps -axo pid,pcpu,comm')}
with (work/'results.csv').open('w') as stream:
 writer=csv.writer(stream,lineterminator='\n');writer.writerow(['pair','variant','model','phase','milliseconds'])
 for pair in range(1,4):
  for variant in (('before','after') if pair%2 else ('after','before')):
   print(f'pair {pair} {variant}',flush=True)
   before=snapshot();source=str(work/variant)+'/'
   env=dict(os.environ,CL_INFERENCE_SIMD_SOURCE=source,VECLIB_MAXIMUM_THREADS='1',TRIVIAL_SIMD_BACKEND='native',ASDF_OUTPUT_TRANSLATIONS=f'(:output-translations (t ("{work}/{variant}-cache/" :implementation)) :ignore-inherited-configuration)')
   path=work/f'{pair}-{variant}.log'
   with path.open('w') as log:
    p=subprocess.run(['sbcl','--dynamic-space-size','3072','--script',str(work/'inference-bench.lisp')],env=env,stdout=log,stderr=subprocess.STDOUT)
   lines=path.read_text().splitlines();rows=[s.split(',')[1:] for s in lines if s.startswith('RESULT,')];profiles=[s for s in lines if s.startswith('PROFILE')]
   assert p.returncode==0 and len(rows)==3 and len(profiles)==1
   assert f'{variant}/' in profiles[0] and ':NATIVE' in profiles[0]
   assert [s for s in lines if s.startswith('VERIFY,')]==['VERIFY,QWEN-F16,9625;374;785;6722']
   writer.writerows([[pair,variant,*r] for r in rows]);stream.flush()
   (work/f'{pair}-{variant}-environment.json').write_text(json.dumps({'before':before,'after':snapshot(),'profile':profiles[0]},indent=2))
   print(f'pair {pair} {variant} verified',flush=True)
