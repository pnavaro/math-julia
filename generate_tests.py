from glob import glob

nbfiles = glob("*.ipynb")

with open("tests.py","w") as f:
    f.write("""\
import sys,os
sys.path.append(os.getcwd())
from nbtest import _notebook_run

print("Running Notebooks...")
\n\n""")

for i, nb in enumerate(sorted(nbfiles)):  
    with open("tests.py", "a") as f:
        f.write("def test_ipynb_{0}():\n".format(i))
        f.write("\t nb, errors = _notebook_run('"+nb+"')\n")
        f.write("\t assert errors == []\n\n")
