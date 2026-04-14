# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from pathlib import Path
from py.set_up__venv import CMAGNETO_PROJECT_ROOT, VENV_PATH, getPythonBinInsideVEnvPath, installPackages, setUpVEnv
import argparse
import re
import subprocess


PYTEST_REPORT = CMAGNETO_PROJECT_ROOT / "tests" / "summary" / "pytest-report.xml"
PY_COVERAGE_XML_REPORT = CMAGNETO_PROJECT_ROOT / "tests" / "summary" / "py-coverage.xml"
PY_COVERAGE_TEXT_REPORT = CMAGNETO_PROJECT_ROOT / "tests" / "summary" / "py-coverage.txt"
PYTEST_ROOT = CMAGNETO_PROJECT_ROOT / "tests" / "py"
PY_SOURCE_ROOT = CMAGNETO_PROJECT_ROOT / "SeedProject" / "CMagneto" / "py"

def setUpPyVEnv(iRecreate: bool) -> Path:
    if iRecreate or not VENV_PATH.exists():
        return setUpVEnv(iPrintVEnvActivationInstruction=False)
    pythonBinPath = getPythonBinInsideVEnvPath()
    installPackages(pythonBinPath)
    return pythonBinPath

def runPyUnitAndIntegrationTestsInsideVEnv(iPythonBinPathInsideVEnv: Path) -> str:
    PYTEST_REPORT.parent.mkdir(parents=True, exist_ok=True)

    subprocess.run([
        iPythonBinPathInsideVEnv.as_posix(),
        "-m", "coverage",
        "erase"
    ], check=True)

    subprocess.run([
        iPythonBinPathInsideVEnv.as_posix(),
        "-m", "coverage",
        "run",
        f"--source={PY_SOURCE_ROOT.as_posix()}",
        "-m", "pytest", # `-m` tells Python to run a module as a script.
        PYTEST_ROOT.as_posix(),
        f"--junitxml={PYTEST_REPORT}"
    ], check=True)

    subprocess.run([
        iPythonBinPathInsideVEnv.as_posix(),
        "-m", "coverage",
        "xml",
        "-o",
        PY_COVERAGE_XML_REPORT.as_posix()
    ], check=True)

    coverageSummary = subprocess.run([
        iPythonBinPathInsideVEnv.as_posix(),
        "-m", "coverage",
        "report"
    ], check=True, capture_output=True, text=True)

    PY_COVERAGE_TEXT_REPORT.write_text(coverageSummary.stdout, encoding="utf-8")

    totalLineMatch = re.search(r"^TOTAL\s+\d+\s+\d+\s+(\d+%)$", coverageSummary.stdout, re.MULTILINE)
    if totalLineMatch is None:
        raise RuntimeError("Failed to parse Python test coverage percentage from coverage report.")

    coveragePercentage = totalLineMatch.group(1)
    print(f"Framework Python test coverage {coveragePercentage}")
    return coveragePercentage

def main():
    parser = argparse.ArgumentParser(
        description= \
f"Do all preparations and run CMagneto Project init and integration tests.\n\
Tests of the seed project and test projects are considered as stages system tests and not run.",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--recreate_py_venv",
        action="store_true",
        help=f"If a dir with Python a virtual environment exists, recreate the virtual environment and reinstall packages.",
        default=False
    )

    args, _ = parser.parse_known_args()

    pythonBinPathInsideVEnv = setUpPyVEnv(args.recreate_py_venv)
    runPyUnitAndIntegrationTestsInsideVEnv(pythonBinPathInsideVEnv)


if __name__ == "__main__":
    main()
