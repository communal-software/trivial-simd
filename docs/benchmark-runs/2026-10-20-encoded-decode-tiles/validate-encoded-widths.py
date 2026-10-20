from pathlib import Path
import subprocess
root=Path('/Users/george/git/trivial-simd');work=Path('/tmp/encoded-tile-sweep-2026-10-20')
s=(root/'tests/native-encoded-matmul.c').read_text()
with (work/'candidate-validation.log').open('w') as log:
 for width in (4,8,12,16):
  test=work/f'test-{width}.c';test.write_text(s.replace('#include "../native/encoded-matmul.c"',f'#include "{work}/encoded-{width}.c"'))
  for scalar in (False,True):
   exe=work/f'test-{width}-{int(scalar)}'
   cmd=['cc','-O1','-g','-ffp-contract=off','-fsanitize=address,undefined','-fno-omit-frame-pointer','-I'+str(root/'native'),str(test),'-o',str(exe)]
   if scalar:cmd.append('-DTS_SCALAR')
   subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,check=True)
   subprocess.run([str(exe)],stdout=log,stderr=subprocess.STDOUT,check=True)
   log.write(f'width={width} scalar={scalar}: ASan/UBSan and reference checks pass\n');log.flush()
