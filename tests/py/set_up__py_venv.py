# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from pathlib import Path
import subprocess
import os
import venv


VENV_DIR_NAME = ".venv"
CMAGNETO_PROJECT_ROOT: Path = Path(__file__).resolve().parent.parent.parent
VENV_PATH = CMAGNETO_PROJECT_ROOT / VENV_DIR_NAME

def create() -> Path:
    """
    Creates ./.venv/ in the root of CMagneto project and
    returns a path to Python binary inside the venv directory.
    """
    print(f"Creating virtual environment in {VENV_PATH} ...")
    venv.create(VENV_PATH, with_pip=True)
    print("Virtual environment created.")

    # Path to the python executable inside venv.
    pythonBin = VENV_PATH / "bin" / "python.exe"
    if os.name == "nt":
        if not pythonBin.exists():
            pythonBin = VENV_PATH / "Scripts" / "python.exe"
        if not pythonBin.exists():
            raise FileNotFoundError(f"Python binary is not found inside created virtual environment dir `{str(VENV_PATH)}`.")
    return pythonBin

def installPackages(iPythonBin: Path) -> None:
    print("Installing packages inside the virtual environment...")
    if not iPythonBin.exists():
        raise FileNotFoundError(f"Python binary is not found inside created `{str(VENV_PATH)}`.")
    subprocess.check_call([str(iPythonBin), "-m", "pip", "install", "pytest"])

if __name__ == "__main__":
    pythonBin = create()
    installPackages(pythonBin)
    print(f"Python venv has been created. To activate the venv, run", end='')
    if os.name == "nt":
        if pythonBin.parent.name == "Scripts":
            print(f":\n'{str(pythonBin.parent / "activate")}'")
        else:
            print(f" in MSYS2 console:\nsource '{(pythonBin.parent / "activate").as_posix()}'") # MSYS2 Python.
    else:
        print(f":\nsource '{str(pythonBin.parent / "activate")}'")