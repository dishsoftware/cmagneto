#!/usr/bin/env python3

# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import sys
import json


SEED_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
CMAGNETO_REPO_ROOT = SEED_PROJECT_ROOT.parent

cmagnetoRepoRootStr = str(CMAGNETO_REPO_ROOT)
seedProjectRootStr = str(SEED_PROJECT_ROOT)

if cmagnetoRepoRootStr not in sys.path:
    sys.path.insert(0, cmagnetoRepoRootStr)

if seedProjectRootStr not in sys.path:
    sys.path.insert(0, seedProjectRootStr)

from CMagneto.py.utils.process import Process


TEST_PROJECT_DIR = SEED_PROJECT_ROOT / "tests" / "@TestProjects" / "CMakePackageConsumer"
TEST_PROJECT_BUILD_DIR = TEST_PROJECT_DIR / "build"
ROOT_PRESETS_PATH = TEST_PROJECT_DIR / "CMakePresets.json"


def _buildPresetDefinitions() -> dict[str, dict[str, object]]:
    buildPresets: dict[str, dict[str, object]] = {}
    visitedPaths: set[Path] = set()

    def collectFromFile(iPresetFilePath: Path) -> None:
        presetFilePath = iPresetFilePath.resolve()
        if presetFilePath in visitedPaths:
            return
        visitedPaths.add(presetFilePath)

        with presetFilePath.open("r", encoding="utf-8") as handle:
            presetDocument = json.load(handle)

        for includePathStr in presetDocument.get("include", []):
            collectFromFile((presetFilePath.parent / includePathStr).resolve())

        for preset in presetDocument.get("buildPresets", []):
            presetName = preset["name"]
            if presetName in buildPresets:
                raise RuntimeError(f"Duplicate build preset \"{presetName}\" in fixture presets.")
            buildPresets[presetName] = preset

    collectFromFile(ROOT_PRESETS_PATH)
    return buildPresets


def _parseArgs() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Configure and build the CMakePackageConsumer fixture project against "
            "the installed primary project package."
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


def _setPrimaryProjectInstallDir(iInstallDir: Path) -> Path:
    installDir = iInstallDir.expanduser().resolve()
    if not installDir.exists():
        raise RuntimeError(
            f"--primary_project_path points to a non-existing path: \"{installDir}\"."
        )

    os.environ["PRIMARY_PROJECT_INSTALL_DIR"] = str(installDir)
    return installDir


def _clearTestProjectBuildDir() -> None:
    if TEST_PROJECT_BUILD_DIR.exists():
        shutil.rmtree(TEST_PROJECT_BUILD_DIR)


def _fixtureConfigurePresetNameForBuildPreset(iBuildPresetName: str) -> str:
    buildPreset = _buildPresetDefinitions().get(iBuildPresetName)
    if buildPreset is None:
        availableBuildPresets = ", ".join(sorted(_buildPresetDefinitions().keys()))
        raise RuntimeError(
            f"Build preset \"{iBuildPresetName}\" is not defined in {ROOT_PRESETS_PATH}. "
            f"Available build presets: {availableBuildPresets}"
        )

    configurePresetName = buildPreset.get("configurePreset")
    if not isinstance(configurePresetName, str) or not configurePresetName:
        raise RuntimeError(
            f"Build preset \"{iBuildPresetName}\" does not define a valid configurePreset."
        )

    return configurePresetName


def main() -> None:
    args = _parseArgs()

    if Process.findExecutable("cmake") is None:
        raise RuntimeError("Executable \"cmake\" was not found in PATH.")

    _setPrimaryProjectInstallDir(args.primary_project_path)
    _clearTestProjectBuildDir()
    buildPresetName = args.primary_build_preset
    configurePresetName = _fixtureConfigurePresetNameForBuildPreset(buildPresetName)

    Process.runCommand(
        ["cmake", "--preset", configurePresetName, "--fresh"],
        TEST_PROJECT_DIR,
    )

    Process.runCommand(
        ["cmake", "--build", "--preset", buildPresetName],
        TEST_PROJECT_DIR,
    )


if __name__ == "__main__":
    main()
