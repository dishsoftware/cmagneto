#!/usr/bin/env python3

# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys
import time
from typing import cast


SEED_PROJECT_ROOT = Path(__file__).resolve().parent.parent
CMAGNETO_REPO_ROOT = SEED_PROJECT_ROOT.parent

cmagnetoRepoRootStr = str(CMAGNETO_REPO_ROOT)
seedProjectRootStr = str(SEED_PROJECT_ROOT)

if cmagnetoRepoRootStr not in sys.path:
    sys.path.insert(0, cmagnetoRepoRootStr)

if seedProjectRootStr not in sys.path:
    sys.path.insert(0, seedProjectRootStr)

from CMagneto.py.utils.process import Process
from CMagneto.py.utils.log import Log


SYSTEM_TESTS_DIR = Path(__file__).resolve().parent


def _formatDurationSeconds(iDurationSeconds: float) -> str:
    return f"{iDurationSeconds:.2f}s"


def _parseArgs() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run all SeedProject system tests against the already built and installed "
            "primary project."
        )
    )

    parser.add_argument(
        "-p",
        "--primary_project_path",
        type=Path,
        required=True,
        help="Install prefix of the primary project package to test against.",
    )
    parser.add_argument(
        "--primary_configure_preset",
        required=True,
        help="Configure preset name that was used to build the primary project.",
    )
    parser.add_argument(
        "--primary_build_preset",
        required=True,
        help="Build preset name that was used to build the primary project.",
    )
    parser.add_argument(
        "--primary_package_preset",
        required=True,
        help="Package preset name that was used to build the primary project.",
    )

    return parser.parse_args()


def main() -> None:
    args = _parseArgs()
    primaryProjectPath = cast(Path, args.primary_project_path)
    primaryConfigurePreset = cast(str, args.primary_configure_preset)
    primaryBuildPreset = cast(str, args.primary_build_preset)
    primaryPackagePreset = cast(str, args.primary_package_preset)

    sharedArgs: list[str] = [
        "--primary_project_path", str(primaryProjectPath),
        "--primary_configure_preset", primaryConfigurePreset,
        "--primary_build_preset", primaryBuildPreset,
        "--primary_package_preset", primaryPackagePreset,
    ]

    testCases: list[tuple[str, list[str]]] = [
        (
            "CMakePackageConsumer build",
            [
                sys.executable,
                str(SYSTEM_TESTS_DIR / "test__CMakePackageConsumer__build.py"),
                *sharedArgs,
            ],
        ),
    ]

    passedTestNames: list[str] = []
    failedTestNames: list[str] = []
    suiteStartTime = time.monotonic()

    for testName, command in testCases:
        print(flush=True)
        print(flush=True)
        Log.status(f"[SystemTests] START: {testName}")
        testStartTime = time.monotonic()
        try:
            Process.runCommand(command, SYSTEM_TESTS_DIR)
        except subprocess.CalledProcessError:
            testDurationSeconds = time.monotonic() - testStartTime
            failedTestNames.append(testName)
            Log.printColored(
                f"{Log.LOG_MESSAGE_PREFIX}[SystemTests] FAIL: {testName} ({_formatDurationSeconds(testDurationSeconds)})",
                Log.PrintColor.Red
            )
            continue

        testDurationSeconds = time.monotonic() - testStartTime
        passedTestNames.append(testName)
        Log.printColored(
            f"{Log.LOG_MESSAGE_PREFIX}[SystemTests] PASS: {testName} ({_formatDurationSeconds(testDurationSeconds)})",
            Log.PrintColor.Green
        )

    suiteDurationSeconds = time.monotonic() - suiteStartTime
    totalCount = len(testCases)
    passedCount = len(passedTestNames)
    failedCount = len(failedTestNames)

    print(flush=True)
    print(flush=True)
    Log.message(
        "System-test summary:\n"
        f"Total: {totalCount}\n"
        f"Passed: {passedCount}\n"
        f"Failed: {failedCount}\n"
        f"Time spent: {_formatDurationSeconds(suiteDurationSeconds)}"
    )

    if failedTestNames:
        Log.message(
            "Failed system tests:\n" + "\n".join(f"- {testName}" for testName in failedTestNames)
        )
        sys.exit(1)

    print(flush=True)


if __name__ == "__main__":
    main()
