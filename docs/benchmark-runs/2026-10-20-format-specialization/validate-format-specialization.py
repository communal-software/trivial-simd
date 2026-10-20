from pathlib import Path
import subprocess,sys
root=Path('/Users/george/git/trivial-simd');work=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/encoded-format-specialization-2026-10-20')
with (work/'candidate-validation.log').open('w') as log:
 for variant in ('before','after'):
  common=['cc','-O3','-DNDEBUG','-ffp-contract=off','-I'+str(root/'native'),str(work/(variant+'.c'))]
  subprocess.run([*common,'-dynamiclib','-o',str(work/(variant+'.dylib'))],stdout=log,stderr=subprocess.STDOUT,check=True)
  subprocess.run([*common,'-S','-o',str(work/(variant+'.s'))],stdout=log,stderr=subprocess.STDOUT,check=True)
  test=(root/'tests/native-encoded-matmul.c').read_text().replace('#include "../native/encoded-matmul.c"',f'#include "{work}/{variant}.c"');(work/(variant+'-test.c')).write_text(test)
  for scalar in (False,True):
   exe=work/f'{variant}-test-{int(scalar)}';cmd=['cc','-O1','-g','-ffp-contract=off','-fsanitize=address,undefined','-fno-omit-frame-pointer','-I'+str(root/'native'),str(work/(variant+'-test.c')),'-o',str(exe)]
   if scalar:cmd.append('-DTS_SCALAR')
   subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,check=True);subprocess.run([str(exe)],stdout=log,stderr=subprocess.STDOUT,check=True)
   log.write(f'{variant} scalar={scalar}: ASan/UBSan and reference checks pass\n');log.flush()
