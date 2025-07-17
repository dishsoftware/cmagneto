from pathlib import Path
from py.set_up__venv import CMAGNETO_PROJECT_ROOT, VENV_PATH, getPythonBinInsideVEnvPath, setUpVEnv
import argparse
import subprocess


PYTEST_REPORT = CMAGNETO_PROJECT_ROOT / "tests" / "summary" / "pytest-report.xml"

def setUpPyVEnv(iRecreate: bool) -> Path:
    if iRecreate or not VENV_PATH.exists():
        return setUpVEnv(iPrintVEnvActivationInstruction=False)
    return getPythonBinInsideVEnvPath()

def runPyUnitAndIntegrationTestsInsideVEnv(iPythonBinPathInsideVEnv: Path):
    result = subprocess.run([
        iPythonBinPathInsideVEnv.as_posix(),
        "-m", "pytest", # `-m` tells Python to run a module as a script.
        "tests/py/",
        f"--junitxml={PYTEST_REPORT}"
    ], check=True)
    return result

def main():
    parser = argparse.ArgumentParser(
        description= \
f"Do all preparations and run CMagneto project init and integration tests.\n\
Tests of the seed project and test projects are considered as stages system tests and not run.",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--recreate_py_venv",
        action="store_true",
        help=f"If a dir with Python a virtual environment exists, recreate the virtual environment and reinstall packages.",
        default=False
    )

    args, unknownArgs = parser.parse_known_args()

    pythonBinPathInsideVEnv = setUpPyVEnv(args.recreate_py_venv)
    runPyUnitAndIntegrationTestsInsideVEnv(pythonBinPathInsideVEnv)


if __name__ == "__main__":
    main()