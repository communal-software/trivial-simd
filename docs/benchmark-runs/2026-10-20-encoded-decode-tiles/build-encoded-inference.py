import subprocess,os,json
from pathlib import Path
root=Path('/Users/george/git/trivial-simd');work=Path('/tmp/encoded-tile-inference-2026-10-20');work.mkdir(exist_ok=True)
revision=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
archive=subprocess.check_output(['git','-C',str(root),'archive',revision])
for variant,width in [('before',4),('after',8)]:
 d=work/variant;d.mkdir(exist_ok=True);subprocess.run(['tar','-x','-C',str(d)],input=archive,check=True)
 p=d/'native/encoded-matmul.c';s=p.read_text();p.write_text(s.replace('DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)',f'DEFINE_ENCODED_TILE(encoded_tile1, 1, {width})',1))
 with (work/(variant+'-build.log')).open('w') as log:
  subprocess.run(['cmake','-S',str(d),'-B',str(d/'build'),'-DCMAKE_BUILD_TYPE=Release'],stdout=log,stderr=subprocess.STDOUT,check=True)
  subprocess.run(['cmake','--build',str(d/'build'),'--target','trivial_simd','native_encoded_matmul_test','native_encoded_matmul_scalar_test','-j','4'],stdout=log,stderr=subprocess.STDOUT,check=True)
  subprocess.run(['ctest','--test-dir',str(d/'build'),'-R','encoded-matmul','--output-on-failure'],stdout=log,stderr=subprocess.STDOUT,check=True)
 print(variant+' built and tested',flush=True)
# Keep bulk copying enabled in both variants.
s=Path('/tmp/copy-inference-bench.lisp').read_text()
s=s.replace('(:directory "/Users/george/git/trivial-simd/")', '(:directory #.(uiop:getenv "CL_INFERENCE_SIMD_SOURCE"))')
a=s.index('(when (equal "before"');b=s.index('(defvar *result*)',a);s=s[:a]+s[b:]
s=s.replace('(defvar *result*)','''(format t "~&PROFILE backend=~S source=~S~%" (trivial-simd:backend)
        (asdf:component-pathname (asdf:find-system :trivial-simd)))
(assert (eq :native (trivial-simd:backend)))
(defvar *result*)''')
(work/'inference-bench.lisp').write_text(s)
(work/'revision.txt').write_text(revision+'\n')
