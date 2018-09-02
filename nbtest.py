import os
import subprocess
import tempfile
import nbformat
import sys
from pathlib import Path
import nbconvert
from nbconvert.preprocessors import ExecutePreprocessor
import glob

def _notebook_run(nb_file):

    """Execute a notebook via nbconvert and collect output.
       :returns (parsed nb object, execution errors)
    """

    with tempfile.NamedTemporaryFile(suffix=".ipynb") as fout:
        args = ["jupyter", "nbconvert", "--to", "notebook", "--execute",
          "--ExecutePreprocessor.timeout=500",
          "--output", fout.name, nb_file]
        subprocess.check_call(args)

        fout.seek(0)
        nb = nbformat.read(fout, nbformat.current_nbformat)

    errors = [output for cell in nb.cells if "outputs" in cell
                     for output in cell["outputs"]\
                     if output.output_type == "error"]
    return nb, errors


