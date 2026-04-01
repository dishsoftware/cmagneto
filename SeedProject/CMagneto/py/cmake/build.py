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

"""
build.py

Presets-first build script.

`CMakePresets.json` is the build source of truth. This script is an optional
frontend that selects the appropriate presets, keeps a consistent
`--build_variant/--build_type` UX across single- and multi-config generators,
and performs a few convenience actions such as Graphviz picture rendering and
test execution via the generated `run_tests` helper script.
"""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, Mapping, cast
import argparse
import json
import os
import re
import shutil
import subprocess
import sys


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.linux_package_verifier import verifyGeneratedLinuxPackages
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process


@dataclass(frozen=True)
class BuildVariantSpec:
    name: str
    multiConfig: bool

    def configurePresetName(self, iBuildType: BuildRunner.BuildType) -> str:
        if self.multiConfig:
            return self.name
        return f"{self.name}__{iBuildType.name}"

    def buildPresetName(self, iBuildType: BuildRunner.BuildType) -> str:
        if self.multiConfig:
            return f"{self.name}__{iBuildType.name}"
        return self.configurePresetName(iBuildType)

    def packagePresetName(self, iBuildType: BuildRunner.BuildType) -> str:
        if self.multiConfig:
            return f"{self.name}__{iBuildType.name}"
        return self.configurePresetName(iBuildType)

@dataclass(frozen=True)
class ResolvedVariantLayout:
    buildDir: Path
    installDir: Path
    graphvizDotfilePath: Path | None
    multiConfig: bool
    buildType: BuildRunner.BuildType

    def buildSubDir(self, iSubDir: Path) -> Path:
        if self.multiConfig:
            return self.buildDir / iSubDir / self.buildType.name
        return self.buildDir / iSubDir

    def exeDir(self) -> Path:
        return self.buildSubDir(BuildRunner.CMagneto__SUBDIR_EXECUTABLE)

    def summaryDir(self) -> Path:
        return self.buildSubDir(BuildRunner.CMagneto__SUBDIR_SUMMARY)

    def runTestsScriptPath(self) -> Path:
        extension = ".bat" if BuildPlatform().hostOS() == BuildPlatform.OS.Windows else ".sh"
        return self.exeDir() / f"{BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE}{extension}"

    def packagesDir(self) -> Path:
        return self.buildDir / BuildRunner.CMagneto__SUBDIR_PACKAGES

    def graphvizPictureFilePath(self) -> Path | None:
        if self.graphvizDotfilePath is None:
            return None
        return self.graphvizDotfilePath.parent.parent / "targets.svg"

REQUIRED_CMAKE_VERSION: tuple[int, int, int] = (3, 31, 0)
ROOT_PRESETS_PATH = PROJECT_ROOT / "CMakePresets.json"
PRESET_KINDS = ("configurePresets", "buildPresets", "packagePresets")
PRESET_MACRO_PATTERN = re.compile(r"\$env\{([^}]+)\}|\$penv\{([^}]+)\}|\$\{([^}]+)\}")


def _availableBuildVariants() -> dict[str, BuildVariantSpec]:
    availableBuildVariants: dict[str, BuildVariantSpec] = {}
    rawConfigurePresets = _presetDefinitions()["configurePresets"]

    for presetName, rawPreset in rawConfigurePresets.items():
        if rawPreset.get("hidden", False):
            continue

        resolvedConfigurePreset = _resolvedPreset("configurePresets", presetName)
        if not _presetConditionMatches(resolvedConfigurePreset.get("condition")):
            continue

        vendorMetadata: dict[str, Any] | Any = resolvedConfigurePreset.get("vendor")
        if not isinstance(vendorMetadata, dict):
            vendorMetadata = {}
        vendorMetadata = cast(dict[str, Any], vendorMetadata)

        cmagnetoVendorMetadata: dict[str, Any] | Any = vendorMetadata.get("CMagneto")
        if not isinstance(cmagnetoVendorMetadata, dict):
            cmagnetoVendorMetadata = {}
        cmagnetoVendorMetadata = cast(dict[str, Any], cmagnetoVendorMetadata)

        variantDescriptor: dict[str, Any] | Any = cmagnetoVendorMetadata.get("buildVariant")
        if not isinstance(variantDescriptor, dict):
            Log.error(
                f"Configure preset \"{presetName}\" must define vendor.CMagneto.buildVariant metadata."
            )
        variantDescriptor = cast(dict[str, Any], variantDescriptor)

        variantName = variantDescriptor.get("name")
        multiConfig = variantDescriptor.get("multiConfig")
        if not isinstance(variantName, str) or not variantName.strip():
            Log.error(
                f"Configure preset \"{presetName}\" has invalid vendor.CMagneto.buildVariant.name metadata."
            )
        if not isinstance(multiConfig, bool):
            Log.error(
                f"Configure preset \"{presetName}\" has invalid vendor.CMagneto.buildVariant.multiConfig metadata."
            )

        existingVariant = availableBuildVariants.get(variantName)
        candidateVariant = BuildVariantSpec(name=variantName, multiConfig=multiConfig)
        if existingVariant is None:
            availableBuildVariants[variantName] = candidateVariant
            continue

        if existingVariant.multiConfig != candidateVariant.multiConfig:
            Log.error(
                f"Preset-derived build variant \"{variantName}\" is inconsistent: "
                f"both single-config and multi-config presets map to it."
            )

    return availableBuildVariants


def _cmakeHostSystemName() -> str:
    hostOS = BuildPlatform().hostOS()
    if hostOS == BuildPlatform.OS.Linux:
        return "Linux"
    if hostOS == BuildPlatform.OS.Windows:
        return "Windows"
    return hostOS.value


def _presetConditionOperandValue(iOperand: Any) -> Any:
    if isinstance(iOperand, str):
        return _expandPresetString(iOperand, os.environ)
    return iOperand


def _presetConditionMatches(iCondition: Any) -> bool:
    if iCondition is None:
        return True
    if not isinstance(iCondition, dict):
        Log.error(f"Unsupported preset condition: {iCondition!r}.")
    iCondition = cast(dict[str, Any], iCondition)

    conditionType = iCondition.get("type")
    if conditionType == "const":
        return bool(iCondition.get("value"))
    if conditionType == "equals":
        return _presetConditionOperandValue(iCondition.get("lhs")) == _presetConditionOperandValue(iCondition.get("rhs"))
    if conditionType == "notEquals":
        return _presetConditionOperandValue(iCondition.get("lhs")) != _presetConditionOperandValue(iCondition.get("rhs"))
    if conditionType == "inList":
        string = _presetConditionOperandValue(iCondition.get("string"))
        values = iCondition.get("list", [])
        return string in [_presetConditionOperandValue(value) for value in values]
    if conditionType == "matches":
        string = str(_presetConditionOperandValue(iCondition.get("string")))
        regex = str(_presetConditionOperandValue(iCondition.get("regex")))
        return re.search(regex, string) is not None
    if conditionType == "anyOf":
        return any(_presetConditionMatches(subCondition) for subCondition in iCondition.get("conditions", []))
    if conditionType == "allOf":
        return all(_presetConditionMatches(subCondition) for subCondition in iCondition.get("conditions", []))
    if conditionType == "not":
        return not _presetConditionMatches(iCondition.get("condition"))

    Log.error(f"Unsupported preset condition type: {conditionType!r}.")


@lru_cache(maxsize=1)
def _presetDefinitions() -> dict[str, dict[str, dict[str, Any]]]:
    definitions: dict[str, dict[str, dict[str, Any]]] = {kind: {} for kind in PRESET_KINDS}
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

        for presetKind in PRESET_KINDS:
            for preset in presetDocument.get(presetKind, []):
                presetName = preset["name"]
                if presetName in definitions[presetKind]:
                    Log.error(f"Duplicate {presetKind} entry: \"{presetName}\".")
                definitions[presetKind][presetName] = preset

    collectFromFile(ROOT_PRESETS_PATH)
    return definitions


def _mergePreset(iBase: dict[str, Any], iOverride: dict[str, Any]) -> dict[str, Any]:
    merged = dict(iBase)
    for key, value in iOverride.items():
        if key in {"cacheVariables", "environment", "vendor"} and isinstance(value, dict):
            merged[key] = {**merged.get(key, {}), **value}
        else:
            merged[key] = value
    return merged


@lru_cache(maxsize=None)
def _resolvedPreset(iPresetKind: str, iPresetName: str) -> dict[str, Any]:
    preset = _presetDefinitions()[iPresetKind].get(iPresetName)
    if preset is None:
        Log.error(f"{iPresetKind} entry \"{iPresetName}\" is not defined in committed presets.")

    resolvedPreset: dict[str, Any] = {}
    inheritedPresetNames = preset.get("inherits", [])
    if isinstance(inheritedPresetNames, str):
        inheritedPresetNames = [inheritedPresetNames]

    for inheritedPresetName in inheritedPresetNames:
        resolvedPreset = _mergePreset(resolvedPreset, _resolvedPreset(iPresetKind, inheritedPresetName))

    return _mergePreset(resolvedPreset, preset)


def _expandPresetString(iValue: str, iPresetEnvironment: Mapping[str, str]) -> str:
    def replaceMacro(match: re.Match[str]) -> str:
        envName, parentEnvName, cmakeMacroName = match.groups()
        if envName is not None:
            return iPresetEnvironment.get(envName, os.environ.get(envName, ""))
        if parentEnvName is not None:
            return os.environ.get(parentEnvName, "")
        if cmakeMacroName == "sourceDir":
            return str(PROJECT_ROOT)
        if cmakeMacroName == "sourceParentDir":
            return str(PROJECT_ROOT.parent)
        if cmakeMacroName == "pathListSep":
            return os.pathsep
        if cmakeMacroName == "hostSystemName":
            return _cmakeHostSystemName()
        return match.group(0)

    expanded = iValue
    for _ in range(8):
        nextExpanded = PRESET_MACRO_PATTERN.sub(replaceMacro, expanded)
        if nextExpanded == expanded:
            break
        expanded = nextExpanded
    return expanded


def _resolvedPresetEnvironment(iResolvedPreset: dict[str, Any]) -> dict[str, str]:
    rawEnvironment = iResolvedPreset.get("environment", {})
    resolvedEnvironment: dict[str, str] = {
        key: ""
        for key, value in rawEnvironment.items()
        if value is not None
    }

    for _ in range(max(1, len(resolvedEnvironment) * 2)):
        didChange = False
        lookupEnvironment = {**os.environ, **resolvedEnvironment}
        for key, value in rawEnvironment.items():
            if value is None:
                continue
            expandedValue = _expandPresetString(str(value), lookupEnvironment)
            if resolvedEnvironment.get(key) != expandedValue:
                resolvedEnvironment[key] = expandedValue
                didChange = True
        if not didChange:
            break

    return resolvedEnvironment


def _resolvedPresetPath(iPathStr: str | None, iPresetEnvironment: dict[str, str]) -> Path | None:
    if not iPathStr:
        return None

    resolvedPath = Path(_expandPresetString(iPathStr, iPresetEnvironment))
    if resolvedPath.is_absolute():
        return resolvedPath
    return PROJECT_ROOT / resolvedPath


def _resolvedVariantLayout(iVariant: BuildVariantSpec, iBuildType: BuildRunner.BuildType) -> ResolvedVariantLayout:
    configurePreset = _resolvedPreset("configurePresets", iVariant.configurePresetName(iBuildType))
    presetEnvironment = _resolvedPresetEnvironment(configurePreset)

    buildDir = _resolvedPresetPath(configurePreset.get("binaryDir"), presetEnvironment)
    if buildDir is None:
        Log.error(f"Configure preset \"{iVariant.configurePresetName(iBuildType)}\" does not define binaryDir.")

    installDir = _resolvedPresetPath(configurePreset.get("installDir"), presetEnvironment)
    if installDir is None:
        installDir = PROJECT_ROOT / BuildRunner.CMagneto__SUBDIR_INSTALL / iVariant.name
    if iVariant.multiConfig:
        installDir = installDir / iBuildType.name

    graphvizDotfilePath = _resolvedPresetPath(configurePreset.get("graphviz"), presetEnvironment)

    return ResolvedVariantLayout(
        buildDir=buildDir,
        installDir=installDir,
        graphvizDotfilePath=graphvizDotfilePath,
        multiConfig=iVariant.multiConfig,
        buildType=iBuildType
    )


def _ensureCompatibleCMakeOnPath() -> None:
    cmakeExecutable = shutil.which("cmake")
    if cmakeExecutable is None:
        Log.error("`cmake` was not found in PATH.")
    assert cmakeExecutable is not None

    completed = subprocess.run(
        [cmakeExecutable, "--version"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    firstLine = completed.stdout.splitlines()[0] if completed.stdout else ""
    versionMatch = re.search(r"cmake version (\d+)\.(\d+)\.(\d+)", firstLine)
    if versionMatch is None:
        Log.error(f"Could not detect CMake version from: {firstLine!r}.")

    currentVersion = tuple(int(component) for component in versionMatch.groups())
    if currentVersion < REQUIRED_CMAKE_VERSION:
        requiredVersionText = ".".join(str(component) for component in REQUIRED_CMAKE_VERSION)
        currentVersionText = ".".join(str(component) for component in currentVersion)
        Log.error(
            f"CMake {requiredVersionText} or newer is required because CMakePresets.json uses newer presets features.\n"
            f"Current `cmake` resolves to \"{cmakeExecutable}\" and reports version {currentVersionText}.\n"
            "Switch the active CMake in this shell, then rerun the command."
        )


def _renderGraphvizPicture(iGraphvizDotfilePath: Path | None) -> None:
    if iGraphvizDotfilePath is None:
        return

    graphvizBinaryDir: Path | None = None
    graphvizDirStr = os.environ.get("GRAPHVIZ_DIR")
    if graphvizDirStr:
        graphvizBinaryDir = Path(graphvizDirStr) / "bin"

    pictureFilePath = iGraphvizDotfilePath.parent.parent / "targets.svg"
    try:
        command = [
            str((graphvizBinaryDir / "dot")) if graphvizBinaryDir else "dot",
            "-Tsvg",
            str(iGraphvizDotfilePath),
            "-o",
            str(pictureFilePath)
        ]
        Process.runCommand(command)
    except subprocess.CalledProcessError as e:
        Log.warning(f"Graphviz can't generate target dependency graph picture: {e}")
    except FileNotFoundError:
        Log.warning("Graphviz is not found. Target dependency graph picture is not generated.")


def _isBuildDirExist(iLayout: ResolvedVariantLayout) -> bool:
    return iLayout.buildDir.exists()


def _isBuildSummaryExist(iLayout: ResolvedVariantLayout) -> bool:
    return (iLayout.summaryDir() / BuildRunner.CMagneto__BUILD_SUMMARY__FILE_NAME).exists()


def _isCompiledTestsFileExist(iLayout: ResolvedVariantLayout) -> bool:
    return (iLayout.summaryDir() / BuildRunner.CMagneto__TEST_BUILD_SUMMARY__FILE_NAME).exists()


def _isTestReportExist(iLayout: ResolvedVariantLayout) -> bool:
    return (iLayout.summaryDir() / BuildRunner.CMagneto__TEST_REPORT__FILE_NAME).exists()


def _isInstallDirExist(iLayout: ResolvedVariantLayout) -> bool:
    return iLayout.installDir.exists()


def _isPackageExist(iLayout: ResolvedVariantLayout) -> bool:
    packagesDir = iLayout.packagesDir()
    if not packagesDir.exists():
        return False

    for packagePath in packagesDir.rglob("*"):
        if not packagePath.is_file():
            continue
        if "_CPack_Packages" in packagePath.parts:
            continue
        return True
    return False


def _isStageRequired(
    iStageToCheck: BuildRunner.BuildStage,
    iArtifactExists: bool,
    iRequestedStage: BuildRunner.BuildStage,
    iRunPrecedingStages: BuildRunner.RunPrecedingStages
) -> bool:
    if iRequestedStage == iStageToCheck:
        return True

    if iRequestedStage.value <= iStageToCheck.value:
        return False

    if iRunPrecedingStages == BuildRunner.RunPrecedingStages.Rerun:
        return True

    if iRunPrecedingStages == BuildRunner.RunPrecedingStages.Run:
        return not iArtifactExists

    return False

def _parseLibSharedOverrides(iUnknownArgs: list[str]) -> tuple[dict[str, str], list[str]]:
    libSharedOptions: dict[str, str] = {}
    unrecognizedArgs: list[str] = []

    for arg in iUnknownArgs:
        if not arg.startswith("--"):
            unrecognizedArgs.append(arg)
            continue

        processedArg = arg[2:]
        optionAndVal = processedArg.split("=")
        if len(optionAndVal) != 2:
            unrecognizedArgs.append(arg)
            continue

        option, optionVal = optionAndVal
        if not option.startswith("LIB_") or not option.endswith("_SHARED"):
            unrecognizedArgs.append(arg)
            continue

        if optionVal not in ["ON", "OFF", "DEFAULT"]:
            unrecognizedArgs.append(arg)
            continue

        libTargetName = option[4:-7]
        if re.match(r"^_+$", libTargetName):
            Log.warning(f"Invalid library name \"{libTargetName}\". It must not be composed only of underscores.")
            continue
        if not re.match(r"^[A-Z_][A-Z0-9_]*$", libTargetName):
            Log.warning(f"Invalid library name \"{libTargetName}\". Expected letters, digits and underscores. Must start with a letter or underscore.")
            continue

        libSharedOptions[libTargetName] = optionVal

    return libSharedOptions, unrecognizedArgs


def _configureCommand(
    iVariant: BuildVariantSpec,
    iBuildType: BuildRunner.BuildType,
    iBuildSharedLibs: bool,
    iEnableCoverage: bool,
    iLibSharedOptions: dict[str, str]
) -> list[str]:
    command = ["cmake", "--preset", iVariant.configurePresetName(iBuildType)]
    command.append("-DBUILD_SHARED_LIBS=ON" if iBuildSharedLibs else "-DBUILD_SHARED_LIBS=OFF")

    if iEnableCoverage:
        if iBuildType == BuildRunner.BuildType.Debug:
            command.append("-DENABLE_COVERAGE=ON")
        else:
            Log.warning(f"Code coverage is only enabled if the build type is {BuildRunner.BuildType.Debug.name}. Ignored.")

    for libTargetName, sharedOption in iLibSharedOptions.items():
        if sharedOption == "DEFAULT":
            continue
        command.append(f"-DLIB_{libTargetName}_SHARED={sharedOption}")

    return command


def _buildCommand(iVariant: BuildVariantSpec, iBuildType: BuildRunner.BuildType, iTarget: str | None = None) -> list[str]:
    command = ["cmake", "--build", "--preset", iVariant.buildPresetName(iBuildType)]
    if iTarget is not None:
        command.extend(["--target", iTarget])
    return command


def _installCommand(iVariant: BuildVariantSpec, iBuildType: BuildRunner.BuildType) -> list[str]:
    layout = _resolvedVariantLayout(iVariant, iBuildType)
    command = [
        "cmake",
        "--install", str(layout.buildDir),
        "--prefix", str(layout.installDir),
    ]
    if iVariant.multiConfig:
        command.extend(["--config", iBuildType.name])
    return command


def _packageCommand(iVariant: BuildVariantSpec, iBuildType: BuildRunner.BuildType) -> list[str]:
    return ["cpack", "--preset", iVariant.packagePresetName(iBuildType)]


def _runTests(iLayout: ResolvedVariantLayout, iEnableCoverage: bool) -> None:
    text = f"Running tests ({iLayout.buildType.name})"
    Log.status(text + "...")

    runTestsScriptPath = iLayout.runTestsScriptPath()
    if not runTestsScriptPath.exists():
        Log.error(f"Run-tests script was not found: \"{runTestsScriptPath}\".")

    BuildPlatform().runScript(runTestsScriptPath)
    Log.status(text + " finished.\n")

    if iEnableCoverage and iLayout.buildType == BuildRunner.BuildType.Debug:
        BuildRunner.generateTestCoverageReport(
            iLayout.buildDir,
            iLayout.summaryDir()
        )


def _variantDescription(iVariant: BuildVariantSpec, iBuildType: BuildRunner.BuildType, iLayout: ResolvedVariantLayout) -> str:
    configurePresetName = iVariant.configurePresetName(iBuildType)
    buildPresetName = iVariant.buildPresetName(iBuildType)
    packagePresetName = iVariant.packagePresetName(iBuildType)
    return (
        f"Build variant name: \"{iVariant.name}\"\n"
        f"Generator is multi-config: {iVariant.multiConfig}\n"
        f"Build type: {iBuildType.name}\n"
        f"Configure preset: \"{configurePresetName}\"\n"
        f"Build preset: \"{buildPresetName}\"\n"
        f"Package preset: \"{packagePresetName}\"\n"
        f"Project root:      \"{PROJECT_ROOT}\"\n"
        f"Build directory:   \"{iLayout.buildDir}\"\n"
        f"Install directory: \"{iLayout.installDir}\"\n"
    )


def buildProject() -> None:
    _ensureCompatibleCMakeOnPath()
    Log.status(f"Host OS: {BuildPlatform().hostOS().value}")
    availableBuildVariants = _availableBuildVariants()
    buildVariantNames = tuple(availableBuildVariants.keys())

    parser = argparse.ArgumentParser(
        description=(
            "Builds the CMake project using committed CMake presets.\n"
            f"The build pipeline consists of the following stages: {', '.join(stage.name for stage in BuildRunner.BuildStage)}.\n"
            "Preset names stay close to CMake semantics, while this script provides a consistent\n"
            "`--build_variant/--build_type` interface across single- and multi-config generators.\n"
        ),
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--build_variant",
        choices=buildVariantNames,
        required=True,
        help=(
            "Select a logical build variant.\n"
            "The available variants depend on the host OS."
            if buildVariantNames else Log.makeColored("No build variants available for the OS!", Log.PrintColor.Yellow)
        )
    )
    parser.add_argument(
        "--build_type",
        choices=[buildType.name for buildType in BuildRunner.BuildType],
        default=BuildRunner.BuildType.Release.name,
        help=f"Select build type. Default is {BuildRunner.BuildType.Release.name}."
    )
    parser.add_argument(
        "--build_stage",
        choices=[buildStage.name for buildStage in BuildRunner.BuildStage],
        default=BuildRunner.BuildStage.Package.name,
        help=f"Specify a build stage to run. Default is {BuildRunner.BuildStage.Package.name}."
    )
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        choices=[rps.name for rps in BuildRunner.RunPrecedingStages],
        default=BuildRunner.RunPrecedingStages.Run.name,
        help=(
            f"Specify whether to run preceding build stages. Default is {BuildRunner.RunPrecedingStages.Run.name}.\n"
            f"{BuildRunner.RunPrecedingStages.Run.name}: run missing preceding stages only.\n"
            f"{BuildRunner.RunPrecedingStages.Rerun.name}: rerun all preceding stages.\n"
            f"{BuildRunner.RunPrecedingStages.Skip.name}: never run preceding stages automatically."
        )
    )
    parser.add_argument(
        "--BUILD_SHARED_LIBS",
        action="store_true",
        help=(
            "Build implicit type (DEFAULT) libraries as shared.\n"
            "Per-library overrides can still be passed as --LIB_<TARGET>_SHARED=ON|OFF|DEFAULT."
        )
    )
    parser.add_argument(
        "--coverage",
        action="store_true",
        help=(
            f"Enable code coverage instrumentation.\n"
            f"The option only takes effect for {BuildRunner.BuildType.Debug.name} builds."
        )
    )

    args, unknownArgs = parser.parse_known_args()
    libSharedOptions, unrecognizedArgs = _parseLibSharedOverrides(unknownArgs)
    if unrecognizedArgs:
        Log.error(f"Unknown arguments: {', '.join(unrecognizedArgs)}.")

    buildVariant = availableBuildVariants[args.build_variant]
    buildType = BuildRunner.BuildType[args.build_type]
    buildStage = BuildRunner.BuildStage[args.build_stage]
    runPrecedingStages = BuildRunner.RunPrecedingStages[args.run_preceding_stages]
    layout = _resolvedVariantLayout(buildVariant, buildType)

    Log.message(_variantDescription(buildVariant, buildType, layout))

    if _isStageRequired(BuildRunner.BuildStage.Generate, _isBuildDirExist(layout), buildStage, runPrecedingStages):
        text = f"Generation of build system files ({buildType.name})"
        Log.status(text + "...")
        Process.runCommand(
            _configureCommand(buildVariant, buildType, args.BUILD_SHARED_LIBS, args.coverage, libSharedOptions),
            PROJECT_ROOT
        )
        _renderGraphvizPicture(layout.graphvizDotfilePath)
        Log.status(text + " finished.\n")

    if _isStageRequired(BuildRunner.BuildStage.Compile, _isBuildSummaryExist(layout), buildStage, runPrecedingStages):
        text = f"Compiling ({buildType.name})"
        Log.status(text + "...")
        Process.runCommand(_buildCommand(buildVariant, buildType), PROJECT_ROOT)
        Log.status(text + " finished.\n")

    if _isStageRequired(BuildRunner.BuildStage.CompileTests, _isCompiledTestsFileExist(layout), buildStage, runPrecedingStages):
        text = f"Compiling tests ({buildType.name})"
        Log.status(text + "...")
        Process.runCommand(_buildCommand(buildVariant, buildType, "build_tests"), PROJECT_ROOT)
        Log.status(text + " finished.\n")

    if _isStageRequired(BuildRunner.BuildStage.RunTests, _isTestReportExist(layout), buildStage, runPrecedingStages):
        _runTests(layout, args.coverage)

    if _isStageRequired(BuildRunner.BuildStage.Install, _isInstallDirExist(layout), buildStage, runPrecedingStages):
        text = f"Installing ({buildType.name})"
        Log.status(text + "...")
        layout.installDir.mkdir(parents=True, exist_ok=True)
        Process.runCommand(_installCommand(buildVariant, buildType), PROJECT_ROOT)
        Log.status(text + " finished.\n")

    if _isStageRequired(BuildRunner.BuildStage.Package, _isPackageExist(layout), buildStage, runPrecedingStages):
        text = f"Packaging ({buildType.name})"
        Log.status(text + "...")
        Process.runCommand(_packageCommand(buildVariant, buildType), PROJECT_ROOT)
        verifyGeneratedLinuxPackages(
            layout.buildDir,
            layout.exeDir(),
            buildType.name,
            BuildRunner.CMagneto__SUBDIR_PACKAGES,
            BuildRunner.CMagneto__SUBDIR_EXECUTABLE,
            BuildRunner.CMagneto__SUBDIR_SHARED,
            BuildRunner.CMagneto__RUNTIME_DEPENDENCY_MANIFEST__FILE_NAME
        )
        Log.status(text + " finished.\n")


if __name__ == "__main__":
    buildProject()
