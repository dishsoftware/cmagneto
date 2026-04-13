# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
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

def getPythonBinInsideVEnvPath() -> Path:
    """
    Returns the path to the Python binary inside an existing virtual environment dir.
    Raises an error if the environment dir or binary cannot be found.
    """
    if not VENV_PATH.exists():
        raise FileExistsError(
f"Can't find venv dir '{VENV_PATH}'.\n\
At first, call function '{create.__name__}' from module '{__name__}'.")
    if os.name == "nt":
        pythonBinPath = VENV_PATH / "Scripts" / "python.exe"
        if not pythonBinPath.exists():
            pythonBinPath = VENV_PATH / "bin" / "python.exe" # MSYS2 Python.
        if not pythonBinPath.exists():
            raise FileNotFoundError(f"Python binary is not found inside created virtual environment dir `{str(VENV_PATH)}`.")
    else:
        pythonBinPath = VENV_PATH / "bin" / "python"
        if not pythonBinPath.exists():
            raise FileNotFoundError(f"Python binary is not found inside created virtual environment dir `{str(VENV_PATH)}`.")
    return pythonBinPath

def create() -> Path:
    """
    Creates ./.venv/ in the root of CMagneto Project and
    returns a path to Python binary inside the venv directory.
    """
    print(f"Creating virtual environment in {VENV_PATH} ...")
    venv.create(VENV_PATH, with_pip=True)
    print("Virtual environment created.")
    pythonBinPath = getPythonBinInsideVEnvPath()
    print(f"Updating pip...")
    subprocess.run([str(pythonBinPath), "-m", "pip", "install", "--upgrade", "pip"], check=True)
    print(f"pip updated.")
    return pythonBinPath

def installPackages(iPythonBin: Path) -> None:
    print("Installing packages inside the virtual environment...")
    if not iPythonBin.exists():
        raise FileNotFoundError(f"Python binary is not found inside created `{str(VENV_PATH)}`.")
    subprocess.check_call([str(iPythonBin), "-m", "pip", "install", "pytest"])

def setUpVEnv(iPrintVEnvActivationInstruction: bool) -> Path:
    pythonBinPath = create()
    installPackages(pythonBinPath)

    instruction = f"Python venv has been created. To activate the venv, run"
    if os.name == "nt":
        if pythonBinPath.parent.name == "Scripts":
            instruction += f":\n'{str(pythonBinPath.parent / "activate")}'"
        else:
            instruction += f" in MSYS2 console:\nsource '{pythonBinPath.parent / "activate"}'" # MSYS2 Python.
    else:
        instruction += f":\nsource '{pythonBinPath.parent / "activate"}'"

    if (iPrintVEnvActivationInstruction):
        print(instruction)
    return pythonBinPath


if __name__ == "__main__":
    setUpVEnv(iPrintVEnvActivationInstruction=True)