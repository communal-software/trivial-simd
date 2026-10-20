from pathlib import Path
import subprocess,shutil,sys
work=Path(sys.argv[1])
for i,v in enumerate(('before','after')):shutil.copyfile(work/(v+'.dylib'),work/f'tile-{i}.dylib')
s=Path('/tmp/encoded-format-specialization-2026-10-20/sweep.c').read_text();(work/'sweep.c').write_text(s)
subprocess.run(['cc','-O3','-ffp-contract=off',str(work/'sweep.c'),'-o',str(work/'sweep')],check=True)
with (work/'sweep.csv').open('w') as out:subprocess.run([str(work/'sweep'),str(work)],stdout=out,check=True)
