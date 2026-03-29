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
build_runner.py

The location relative to the project root must be preserved.
"""

from __future__ import annotations
from .build_platform import BuildPlatform
from abc import ABC
from CMagneto.py.cmake.build_variant import BuildVariant, ExternalSharedLibraryInstallMode
from CMagneto.py.metadata_holder import MetadataHolder
from CMagneto.py.utils.const_meta_class import ConstMetaClass
from CMagneto.py.utils.good_path import GoodPath
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Callable, cast
import inspect
import json
import os
import re
import shutil
import subprocess
import tarfile


@dataclass(frozen=True)
class _ExternalSharedLibraryDeploymentEntry:
    importedTargetName: str
    paths: tuple[Path, ...]


@dataclass(frozen=True)
class _ExtractedLinuxPackage:
    packagePath: Path
    extractDir: Path
    installRoot: Path


class BuildRunner(ABC):
    """
    Properly calls "cmake" commands. Coupled with the CMagneto CMake module.
    Base class for BuildRunnerSingleConfig and BuildRunnerMultiConfig.
    """


    class BuildType(Enum):
        Debug = 0
        Release = 1
        RelWithDebInfo = 2
        MinSizeRel = 3


    class BuildStage(Enum):
        Generate = 0 # Generate build system files (e.g. MakeFiles or MSVS solution).
        Compile = 1 # Compile the project (create project's binaries, create auxilliary scripts, and place all of them into a build directory).
        CompileTests = 2
        RunTests = 3
        Install = 4 # Install the project (copy scripts and compiled binaries to an install directory).
        Package = 5 # Package the project (create packages, e.g. .deb, .rpm, .zip, etc.).
        # Install stage is technically not required for Package stage. But the file is written .


    class RunPrecedingStages(Enum):
        Run = 0 # Run preceding stages, if their artifacts do not exist.
        Rerun = 1 # Rerun preceding stages, even if their artifacts exist.
        Skip = 2 # Skip preceding stages, even if their artifacts do not exist.
        # Build/install sibdirectory names.


    # CMagneto__* constants are in synch (as the methods of this file) with the CMagneto CMake module,
    # and the constants' names do not obey the Python naming convention.
    CMagneto__SUBDIR_SOURCE  = Path("src/")
    CMagneto__SUBDIR_TESTS   = Path("tests/")
    CMagneto__SUBDIR_BUILD   = Path("build/")
    CMagneto__SUBDIR_INSTALL = Path("install/")
    CMagneto__SUBDIR_STATIC     = Path("lib/")
    CMagneto__SUBDIR_SHARED     = Path("lib/")
    CMagneto__SUBDIR_EXECUTABLE = Path("bin/")
    CMagneto__SUBDIR_SUMMARY = Path("summary/")
    CMagneto__SUBDIR_PACKAGES = Path("packages/")

    CMagneto__BUILD_SUMMARY__FILE_NAME      = "build_summary.txt"
    CMagneto__TEST_BUILD_SUMMARY__FILE_NAME = "test_build_summary.txt"
    CMagneto__RUN_TESTS__SCRIPT_NAME_WE = "run_tests"
    CMagneto__TEST_REPORT__FILE_NAME = "test_report.xml"
    CMagneto__COMPILE_COMMANDS__FILE_NAME = "compile_commands.json"
    CMagneto__RUNTIME_DEPENDENCY_MANIFEST__FILE_NAME = "runtime_dependency_manifest.json"

    # Report of source code (under './src/' ) test coverage.
    CMagneto__TEST_COVERAGE_REPORT__FILE_NAME_WE      = "test_coverage_report"

    # Report of test   code (under './test/') coverage.
    # This coverage report helps identify non-executed parts of tests themselves.
    CMagneto__TEST_CODE_COVERAGE_REPORT__FILE_NAME_WE = "test_code_coverage_report"

    CMagneto__COVERAGE_REPORT_SUMMARY__FILE_NAME_SUFFIX = "_summary"

    # The file contans just overall `XX.X%` or `N/A` to ease creation of CI/CD badges.
    CMagneto__COVERAGE_REPORT_PERCENTAGE__FILE_NAME_SUFFIX = "_percentage.txt"
    ##################################################################################################

    def __init__(self,
            iBuildVariant: BuildVariant,
            iBuildTypes: set[BuildType],
            iEnableCodeCoverage: bool = False
        ):
        assert GoodPath.isNameGood(iBuildVariant.name)
        assert not iBuildVariant.generatorName.isspace()

        self.__buildVariant = iBuildVariant
        self.__buildTypes = iBuildTypes

        if iEnableCodeCoverage:
            if BuildRunner.BuildType.Debug not in self.__buildTypes:
                Log.warning(f"Code coverage is only enabled if the build type is {BuildRunner.BuildType.Debug.name}. Ignored.")
                self.__enableCodeCoverage = False
            else:
                self.__enableCodeCoverage = True
        else:
            self.__enableCodeCoverage = False

        self.__cmakeFlagsFor__generate__command: list[str] = list()
        os.chdir(GoodPath.projectRoot())
        self.__buildDir    = GoodPath.projectRoot() / BuildRunner.CMagneto__SUBDIR_BUILD / self.buildVariantName()
        self.__installDir  = GoodPath.projectRoot() / BuildRunner.CMagneto__SUBDIR_INSTALL / self.buildVariantName()
        self.__setUpBuildVariantEnvironment()

    def __str__(self) -> str:
        text = \
        f"Build variant name: \"{self.buildVariantName()}\"\n" + \
        f"Generator: \"{self.generatorName()}\"\n" + \
        f"Generator is multi-config: {self.multiConfig()}\n"

        if self.cppCompilerName() is not None:
            text += f"C++ compiler: \"{self.cppCompilerName()}\"\n"
        else:
            text += f"C++ compiler: default\n"

        text += \
        f"Build types: {', '.join([buildType.name for buildType in self.__buildTypes])}\n"

        if self.__enableCodeCoverage:
            text += f"Code coverage enabled for the build type {BuildRunner.BuildType.Debug.name}\n"

        if self.__cmakeFlagsFor__generate__command:
            text += "CMake flags for `generate` command: \"" + " ".join(self.__cmakeFlagsFor__generate__command) + "\"\n"

        text += \
        f"Project root:      \"{GoodPath.projectRoot()}\"\n" + \
        f"Build directory:   \"{self.__buildDir}\"\n" + \
        f"Install directory: \"{self.__installDir}\"\n"
        return text

    def buildVariant(self) -> BuildVariant:
        return self.__buildVariant

    def buildVariantName(self) -> str:
        return self.buildVariant().name

    def generatorName(self) -> str:
        return self.buildVariant().generatorName

    def cppCompilerName(self) -> str | None:
        return self.buildVariant().cppCompilerName

    def multiConfig(self) -> bool:
        return self.buildVariant().multiConfig

    def buildTypes(self) -> set[BuildType]:
        return self.__buildTypes

    def enableCodeCoverage(self) -> bool:
        return self.__enableCodeCoverage

    def setCMakeFlagsFor__generate__command(self, iFlags: list[str]) -> None:
        """These flags are passed to CMake on generation stage."""
        self.__cmakeFlagsFor__generate__command = iFlags

    def cmakeFlagsFor__generate__command(self) -> list[str]:
        return self.__cmakeFlagsFor__generate__command

    def buildDir(self) -> Path:
        """Returns the absolute path to the build directory."""
        return self.__buildDir

    def buildSubDirForBuildType(self, iSubDir: Path, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Log.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

    def buildDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Log.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

    def exeDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with executables in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.CMagneto__SUBDIR_EXECUTABLE, iBuildType)

    def sharedLibDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with shared libs in the build directory for the specified build type.\n
           Note: on Windows, .dll files are the shared libraries, but CMake treats them as runtime artifacts, not library artifacts."""
        return self.buildSubDirForBuildType(BuildRunner.CMagneto__SUBDIR_SHARED, iBuildType)

    def staticLibDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with static libs in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.CMagneto__SUBDIR_STATIC, iBuildType)

    def summaryDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with summary files in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.CMagneto__SUBDIR_SUMMARY, iBuildType)

    def isBuildDirExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the build directory exists for the specified build type."""
        return os.path.exists(self.buildDirForBuildType(iBuildType))

    def isBuildSummaryExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the build summary file exists for the specified build type."""
        buildSummaryFilePath = self.summaryDirForBuildType(iBuildType) / BuildRunner.CMagneto__BUILD_SUMMARY__FILE_NAME
        return buildSummaryFilePath.exists()

    def _runTests(self, iBuildType: BuildType) -> None:
        text = f"Running tests ({iBuildType.name})"
        Log.status(text + "...")

        run_tests__scriptDir = self.exeDirForBuildType(iBuildType)
        run_tests__scriptName = GoodPath.findInDirFileWithNameWE(run_tests__scriptDir, BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE)
        if run_tests__scriptName is None:
            Log.warning(f"Script \"{BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE}\" was not found in \"{run_tests__scriptDir}\". Tests have not been run. Call CMagnetoInternal__set_up__run_tests__script() in the root CMakeLists.txt to set up the script.")
        else:
            run_tests__scriptPath = run_tests__scriptDir / run_tests__scriptName
            BuildPlatform().runScript(run_tests__scriptPath)

        Log.status(text + " finished.\n")
        # If `run_tests` script exists and hasn't failed ...
        if run_tests__scriptName is not None and iBuildType == BuildRunner.BuildType.Debug and self.enableCodeCoverage():
            self.__generateTestCoverageReport()

    def __generateTestCoverageReport(self) -> None:
        text = "Generation of test coverage report"
        Log.status(text + "...")

        hostOS: BuildPlatform.OS = BuildPlatform().hostOS()
        if hostOS == BuildPlatform.OS.Linux:
            BuildRunner._LCOVRunner.generateTestCoverageReport(
                self.buildDirForBuildType(BuildRunner.BuildType.Debug),
                self.summaryDirForBuildType(BuildRunner.BuildType.Debug)
            )
        else:
            Log.warning(f"Generation of test coverage report is not supported on {hostOS.name}.")

        Log.status(text + " finished.\n")


    # This class should be private, but making it private triggers name mangling, which prevents its own static methods from being called internally.
    class _LCOVRunner:
        """
        Generates `.info` trace files and human-readable HTML-reports usings `.gcno` and `.gcda` files.

        `.gcno` — Notes (Static Metadata)
        Generated at compile time, alongside your object (.o) files.
        Contains:
            - Control flow graph (CFG) of the program.
            - Source line mappings for tracking coverage.
            - Required to understand what could be covered (all possible lines/branches).
            - One .gcno file per compiled translation unit (usually per .cpp file).
        Think of it as the map of what can be executed.

        `.gcda` — Data (Dynamic Execution)
        Generated at runtime, when the instrumented binary is executed.
        Contains:
            - Actual execution counts (how many times each line or branch was hit).
            - Updated or created when the program exits normally.
        Think of it as the record of what was actually executed.

        `lcov --capture` reads `.gcno` and `.gcda` files to compute coverage and create a consolidated raw summary `.info`.
        `genhtml` makes pretty HTML reports from `.info`.
        """

        @staticmethod
        def generateTestCoverageReport(iBuildDir: Path, iSummaryDir: Path) -> None:
            if shutil.which("lcov") is None:
                Log.warning("LCOV is not installed. Can't generate test coverage report.")
                return

            # 1. Generate code coverage report for source code files (under './src/').
            BuildRunner._LCOVRunner.__generateCoverageReport(
                iBuildDir,
                GoodPath.projectRoot() / BuildRunner.CMagneto__SUBDIR_SOURCE,
                iSummaryDir,
                BuildRunner.CMagneto__TEST_COVERAGE_REPORT__FILE_NAME_WE
            )

            # 2. Generate code coverage report for test code files (under './tests/').
            # This coverage report helps identify non-executed parts of tests themselves.
            BuildRunner._LCOVRunner.__generateCoverageReport(
                iBuildDir,
                GoodPath.projectRoot() / BuildRunner.CMagneto__SUBDIR_TESTS,
                iSummaryDir,
                BuildRunner.CMagneto__TEST_CODE_COVERAGE_REPORT__FILE_NAME_WE
            )

        @staticmethod
        def __generateCoverageReport(
            iBuildDir: Path,
            iBaseDir: Path,
            iSummaryDir: Path,
            iTracefileNameWE: str
        ) -> None:
            tracefilePath = iSummaryDir / (iTracefileNameWE + ".info")

            # 1. Generate coverage tracefile.
            Process.runCommand(["lcov", "--capture",
                "--directory", str(iBuildDir),
                "--output-file", str(tracefilePath),
                "--base-directory", str(iBaseDir),

                # "mismatch" -  Get rid of: `geninfo: ERROR: mismatched end line for <some cpp file of a test target> ...`,
                #               which is, probably, due to a bug in GCC/GCOV (GCOV is called by LCOV under the hood).
                # "unused"   -  Don't fail, if a pattern to include/exclude does not match to anything.
                # "empty"    -  Don't fail, if no `.gcda` files found (no tests added).
                "--ignore-errors", "mismatch,unused,empty",

                # Don't capture code coverage of source files, outside the base dir.
                # It also excludes 3rd-party libs code, e.g. system or added using `target_link_libraries`,
                "--no-external",

                # Don't capture code coverage of third-party dependencies like GoogleTest, fmt, etc.,
                # that are typically pulled in `{buildDir}/_deps/` via FetchContent or ExternalProject.
                "--exclude", str(iBuildDir) + "/_deps/*",

                # Don't capture code coverage of compiled Qt Resource Collection binaries.
                "--exclude", "*.rcc"
            ])
            Log.message(
"Most probably such LCOV-generated warnings should be ignored:\n\
\t'geninfo: WARNING: ('mismatch') mismatched end line for ...'\n\
It seems, it is a bug in in GCC/GCOV (GCOV is called by LCOV under the hood)."
            )

            # 2. Generate short summary using the tracefile.
            # TODO Is it really required? Probably the next "genhtml" command generates the desired "lines......: X%" (overall, not per file).
            lcovSummaryOutput = Process.runCommand(
                ["lcov", "--summary", str(tracefilePath), "--ignore-errors", "empty"],
                iCaptureOutput=True, iCheck=False
            )

            assert lcovSummaryOutput is not None

            summaryFilePath = iSummaryDir / (iTracefileNameWE + BuildRunner.CMagneto__COVERAGE_REPORT_SUMMARY__FILE_NAME_SUFFIX)
            with open(summaryFilePath, "w", encoding="utf-8") as summaryFile:
                summaryFile.write(lcovSummaryOutput.stdout)

            # 3. Create a file with just `XX%` or `N/A` to ease creation of CI/CD badges.
            percentageFileContent = "N/A"
            if lcovSummaryOutput.returncode == 0 or "lines......: no data found" not in lcovSummaryOutput.stdout:
                for line in lcovSummaryOutput.stdout.splitlines():
                    if "lines......:" in line:
                        percentageFileContent = line.split()[1]  # e.g., '87.5%'

            percentageFilePath = iSummaryDir / (iTracefileNameWE + BuildRunner.CMagneto__COVERAGE_REPORT_PERCENTAGE__FILE_NAME_SUFFIX)
            with open(percentageFilePath, "w", encoding="utf-8") as percentageFile:
                percentageFile.write(percentageFileContent)

            # 4. Create verbose human-readable HTML-reports using the tracefile.

            ## Don't pollute build log with "errors", if tracefile is not meaningful (i.e. if tests have not been added to the project yet).
            if lcovSummaryOutput.returncode != 0 or "lines......: no data found" in lcovSummaryOutput.stdout:
                return

            ## `genhtml` is part of the `lcov` package.
            Process.runCommand(["genhtml", str(tracefilePath),
                "--output-directory", str(iSummaryDir / (iTracefileNameWE + "_html/")),
                "--ignore-errors", "empty"
            ])


    def isCompiledTestsFileExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the compiled tests file exists for the specified build type."""
        compiledTestsFilePath = self.summaryDirForBuildType(iBuildType) / BuildRunner.CMagneto__TEST_BUILD_SUMMARY__FILE_NAME
        return compiledTestsFilePath.exists()

    def isTestReportExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the test report file exists for the specified build type."""
        testReportFilePath = self.summaryDirForBuildType(iBuildType) / BuildRunner.CMagneto__TEST_REPORT__FILE_NAME
        return testReportFilePath.exists()

    def installDir(self) -> Path:
        """Returns the absolute path to the install directory."""
        return self.__installDir

    def installDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to the install directory for the specified build type."""
        return self.__installDir / iBuildType.name

    def isInstallDirExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the install directory exists for the specified build type."""
        return self.installDirForBuildType(iBuildType).exists()

    def isPackageExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the 'packages' directory contains at least one file (recursively)."""
        packagesDir = self.buildDirForBuildType(iBuildType) / BuildRunner.CMagneto__SUBDIR_PACKAGES
        for _, _, files in os.walk(packagesDir):
            if files:
                return True
        return False

    def isStageRequired(self, iBuildStageOfStage: BuildStage, iBuildType: BuildType, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> bool:
        """Checks if the build stage (iBuildStageOfStage) is required to run based on existence of its artifacts for the iBuildType,
           requested iBuildStage and iRunPrecedingStages option."""

        def isStageRequiredFor(
                iStageToCheck: BuildRunner.BuildStage,
                iArtifactExistenceChecker: Callable[[BuildRunner.BuildType], bool],
                iRequestedBuildType: BuildRunner.BuildType,
                iRequestedBuildStage: BuildRunner.BuildStage
            ) -> bool:
            return (
                iRequestedBuildStage == iStageToCheck or
                iRequestedBuildStage.value > iStageToCheck.value and
                (
                    iRunPrecedingStages == BuildRunner.RunPrecedingStages.Rerun or
                    (
                        iRunPrecedingStages == BuildRunner.RunPrecedingStages.Run and
                        not iArtifactExistenceChecker(iRequestedBuildType)
                    )
                )
            )

        match iBuildStageOfStage:
            case BuildRunner.BuildStage.Generate:
                return isStageRequiredFor(BuildRunner.BuildStage.Generate, self.isBuildDirExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Compile:
                return isStageRequiredFor(BuildRunner.BuildStage.Compile, self.isBuildSummaryExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.CompileTests:
                return isStageRequiredFor(BuildRunner.BuildStage.CompileTests, self.isCompiledTestsFileExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.RunTests:
                return isStageRequiredFor(BuildRunner.BuildStage.RunTests, self.isTestReportExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Install:
                return isStageRequiredFor(BuildRunner.BuildStage.Install, self.isInstallDirExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Package:
                return isStageRequiredFor(BuildRunner.BuildStage.Package, self.isPackageExistForBuildType, iBuildType, iBuildStage)
            case _:
                Log.error(f"Invalid logics of {__file__}: unknown build stage: {iBuildStageOfStage}.")

    def _package(self, iBuildType: BuildType) -> None:
        text = f"Packaging ({iBuildType.name})"
        Log.status(text + "...")
        Process.runCommand(["cpack"], self.buildDirForBuildType(iBuildType))
        self.__verifyGeneratedLinuxPackages(iBuildType)
        Log.status(text + " finished.\n")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Log.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

    def _setDependencyPaths(self) -> None:
        for dependencyPath in self.buildVariant().dependencyPaths:
            BuildRunner._addVarPathTo_CMAKE_PREFIX_PATH(dependencyPath.envVarName, dependencyPath.cmakePathPostfix)

    def _cmakeFlagsFor__externalSharedLibraryPolicies(self) -> list[str]:
        importedTargetsByMode: dict[ExternalSharedLibraryInstallMode, list[str]] = {
            ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE: [],
            ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE: []
        }
        installModesByImportedTarget: dict[str, ExternalSharedLibraryInstallMode] = {}

        for policy in self.buildVariant().externalSharedLibraryPolicies:
            existingMode = installModesByImportedTarget.get(policy.importedTargetName)
            if existingMode is not None and existingMode != policy.installMode:
                Log.error(
                    f"Build variant \"{self.buildVariantName()}\" configures imported shared library "
                    f"\"{policy.importedTargetName}\" with conflicting install modes: "
                    f"\"{existingMode.value}\" and \"{policy.installMode.value}\"."
                )

            installModesByImportedTarget[policy.importedTargetName] = policy.installMode
            importedTargetsByMode[policy.installMode].append(policy.importedTargetName)

        flags: list[str] = []
        for installMode, importedTargets in importedTargetsByMode.items():
            if not importedTargets:
                continue

            deduplicatedImportedTargets = list(dict.fromkeys(importedTargets))
            if installMode == ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE:
                varName = "CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE"
            elif installMode == ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE:
                varName = "CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE"
            else:
                Log.error(f"Invalid logics of {__file__}: unsupported install mode \"{installMode.value}\".")

            flags.append(f"-D{varName}={';'.join(deduplicatedImportedTargets)}")

        return flags

    def _cmakeFlagsFor__runtimeDependencyBundlingOverrides(self) -> list[str]:
        flags: list[str] = []

        overrideVarNamesAndValues: tuple[tuple[str, tuple[str, ...]], ...] = (
            ("CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILES", self.buildVariant().bundledRuntimeDependencyFiles),
            ("CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS", self.buildVariant().bundledRuntimeDependencyFilePatterns),
            ("CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILES", self.buildVariant().excludedBundledRuntimeDependencyFiles),
            ("CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS", self.buildVariant().excludedBundledRuntimeDependencyFilePatterns),
        )

        for varName, rawValues in overrideVarNamesAndValues:
            if not rawValues:
                continue

            deduplicatedValues = tuple(dict.fromkeys(rawValues))
            flags.append(f"-D{varName}={';'.join(deduplicatedValues)}")

        return flags

    def __verifyGeneratedLinuxPackages(self, iBuildType: BuildType) -> None:
        """Extracts generated Linux packages and verifies external shared-library deployment policy."""
        if BuildPlatform().hostOS() != BuildPlatform.OS.Linux:
            return

        deploymentEntriesByMode = self.__loadRuntimeDependencyManifestDeploymentEntries(iBuildType)
        if all(not deploymentEntries for deploymentEntries in deploymentEntriesByMode.values()):
            return

        text = f"Verifying generated packages ({iBuildType.name})"
        Log.status(text + "...")

        packagesDir = self.buildDirForBuildType(iBuildType) / BuildRunner.CMagneto__SUBDIR_PACKAGES
        extractedPackages = self.__extractSupportedLinuxPackages(packagesDir)
        if not extractedPackages:
            Log.error(f"No supported Linux packages with runtime payload were found in \"{packagesDir}\".")

        for extractedPackage in extractedPackages:
            self.__verifyExternalSharedLibrariesInLinuxPackage(extractedPackage, deploymentEntriesByMode)

        Log.status(text + " finished.\n")

    def __loadRuntimeDependencyManifestDeploymentEntries(self, iBuildType: BuildType) -> dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]]:
        """Loads imported shared-library deployment expectations from the canonical runtime dependency manifest."""
        manifestPath = self.exeDirForBuildType(iBuildType) / BuildRunner.CMagneto__RUNTIME_DEPENDENCY_MANIFEST__FILE_NAME
        if not manifestPath.exists():
            Log.warning(f"Runtime dependency manifest file was not found: \"{manifestPath}\".")
            return {
                ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE: tuple(),
                ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE: tuple()
            }

        with manifestPath.open("r", encoding="utf-8") as manifestFile:
            manifest = json.load(manifestFile)

        if not isinstance(manifest, dict):
            Log.error(f"Invalid runtime dependency manifest file: \"{manifestPath}\".")
        manifestDict = cast(dict[str, object], manifest)

        rawImportedSharedLibraries = manifestDict.get("ImportedSharedLibraries", [])
        if not isinstance(rawImportedSharedLibraries, list):
            Log.error(f"Invalid ImportedSharedLibraries section in \"{manifestPath}\".")
        importedSharedLibraries = cast(list[object], rawImportedSharedLibraries)

        entriesByMode: dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]] = {}
        for installMode in ExternalSharedLibraryInstallMode:
            parsedEntries: list[_ExternalSharedLibraryDeploymentEntry] = []
            for rawEntry in importedSharedLibraries:
                if not isinstance(rawEntry, dict):
                    Log.error(f"Invalid imported shared-library entry in \"{manifestPath}\": {rawEntry!r}.")
                rawEntryDict = cast(dict[str, object], rawEntry)

                importedTargetName = rawEntryDict.get("ImportedTarget")
                rawInstallMode = rawEntryDict.get("InstallMode")
                rawPaths = rawEntryDict.get("Paths")
                if not isinstance(importedTargetName, str):
                    Log.error(f"Invalid imported target name in \"{manifestPath}\": {rawEntry!r}.")
                if not isinstance(rawInstallMode, str):
                    Log.error(f"Invalid install mode in \"{manifestPath}\": {rawEntry!r}.")
                if not isinstance(rawPaths, list):
                    Log.error(f"Invalid imported target paths in \"{manifestPath}\": {rawEntry!r}.")
                if rawInstallMode != installMode.value:
                    continue

                rawPathList = cast(list[object], rawPaths)
                pathListItems: list[str] = []
                for rawPath in rawPathList:
                    if not isinstance(rawPath, str):
                        Log.error(f"Invalid imported target path item in \"{manifestPath}\": {rawEntry!r}.")
                    pathListItems.append(rawPath)
                pathList = tuple(pathListItems)

                parsedEntries.append(
                    _ExternalSharedLibraryDeploymentEntry(
                        importedTargetName=importedTargetName,
                        paths=tuple(Path(path) for path in pathList)
                    )
                )

            entriesByMode[installMode] = tuple(parsedEntries)

        return entriesByMode

    def __linuxPackageInstallPrefixRelativePath(self) -> Path:
        """Returns the runtime payload root inside Linux packages generated by the current project metadata."""
        companyNameShort = MetadataHolder().getMetadataValue(Path("./Project.json"), ["CompanyName_SHORT"])
        projectNameBase = MetadataHolder().getMetadataValue(Path("./Project.json"), ["ProjectNameBase"])
        if not (isinstance(companyNameShort, str) and isinstance(projectNameBase, str)):
            Log.error(f"{self.__class__.__name__}: can't get required project metadata for package verification.")

        return Path("opt") / companyNameShort / projectNameBase

    def __extractSupportedLinuxPackages(self, iPackagesDir: Path) -> tuple[_ExtractedLinuxPackage, ...]:
        """Extracts supported Linux package formats and returns only packages that contain the runtime payload."""
        installPrefixRelativePath = self.__linuxPackageInstallPrefixRelativePath()
        extractionRoot = iPackagesDir / ".tmp" / "package_verification"

        extractedPackages: list[_ExtractedLinuxPackage] = []
        for packagePath in sorted(iPackagesDir.rglob("*")):
            if not packagePath.is_file():
                continue
            if "_CPack_Packages" in packagePath.parts:
                continue
            if not (
                packagePath.name.endswith(".deb") or
                packagePath.name.endswith(".tgz") or
                packagePath.name.endswith(".tar.gz")
            ):
                continue

            extractDir = extractionRoot / packagePath.name
            self.__extractLinuxPackage(packagePath, extractDir)

            installRoot = extractDir / installPrefixRelativePath
            if not installRoot.exists():
                Log.warning(f"Skipping package without runtime payload at \"{installPrefixRelativePath}\": \"{packagePath}\".")
                continue

            extractedPackages.append(
                _ExtractedLinuxPackage(
                    packagePath=packagePath,
                    extractDir=extractDir,
                    installRoot=installRoot
                )
            )

        return tuple(extractedPackages)

    def __extractLinuxPackage(self, iPackagePath: Path, iExtractDir: Path) -> None:
        """Extracts one supported Linux package into iExtractDir."""
        if iExtractDir.exists():
            shutil.rmtree(iExtractDir)
        iExtractDir.mkdir(parents=True, exist_ok=True)

        if iPackagePath.name.endswith(".deb"):
            Process.runCommand(["dpkg-deb", "-x", str(iPackagePath), str(iExtractDir)])
            return

        if iPackagePath.name.endswith(".tgz") or iPackagePath.name.endswith(".tar.gz"):
            with tarfile.open(iPackagePath, "r:*") as packageArchive:
                packageArchive.extractall(iExtractDir)
            return

        Log.error(f"Unsupported Linux package format: \"{iPackagePath}\".")

    def __verifyExternalSharedLibrariesInLinuxPackage(
            self,
            iExtractedPackage: _ExtractedLinuxPackage,
            iDeploymentEntriesByMode: dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]]
        ) -> None:
        """Checks that bundled and externally provided shared libraries resolve as configured inside one extracted package."""
        elfFiles = (
            *self.__findElfFilesUnder(iExtractedPackage.installRoot / BuildRunner.CMagneto__SUBDIR_EXECUTABLE),
            *self.__findElfFilesUnder(iExtractedPackage.installRoot / BuildRunner.CMagneto__SUBDIR_SHARED)
        )
        if not elfFiles:
            Log.warning(f"Skipping package verification because no ELF runtime files were found in \"{iExtractedPackage.packagePath}\".")
            return

        packagedFilesByName: dict[str, set[Path]] = {}
        for packagedFile in iExtractedPackage.installRoot.rglob("*"):
            if not packagedFile.is_file():
                continue
            packagedFilesByName.setdefault(packagedFile.name, set()).add(packagedFile)

        resolvedLibrariesByName = self.__collectResolvedLinuxSharedLibraries(tuple(elfFiles), iExtractedPackage.packagePath)

        for deploymentEntry in iDeploymentEntriesByMode[ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE]:
            candidateLibraryNames = self.__sharedLibraryNamesForPaths(deploymentEntry.paths)
            packagedPaths = self.__pathsForLibraryNames(candidateLibraryNames, packagedFilesByName)
            if not packagedPaths:
                Log.error(
                    f"Bundled imported shared library \"{deploymentEntry.importedTargetName}\" is missing from package "
                    f"\"{iExtractedPackage.packagePath}\". Expected one of: {sorted(candidateLibraryNames)}."
                )

            resolvedPaths = self.__pathsForLibraryNames(candidateLibraryNames, resolvedLibrariesByName)
            if not any(resolvedPath.is_relative_to(iExtractedPackage.installRoot) for resolvedPath in resolvedPaths):
                Log.error(
                    f"Bundled imported shared library \"{deploymentEntry.importedTargetName}\" was not resolved from within "
                    f"the extracted package \"{iExtractedPackage.packagePath}\"."
                )

        for deploymentEntry in iDeploymentEntriesByMode[ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE]:
            candidateLibraryNames = self.__sharedLibraryNamesForPaths(deploymentEntry.paths)
            packagedPaths = self.__pathsForLibraryNames(candidateLibraryNames, packagedFilesByName)
            if packagedPaths:
                Log.error(
                    f"Imported shared library \"{deploymentEntry.importedTargetName}\" is expected on the target machine, "
                    f"but package \"{iExtractedPackage.packagePath}\" contains {sorted(str(path) for path in packagedPaths)}."
                )

            resolvedPaths = self.__pathsForLibraryNames(candidateLibraryNames, resolvedLibrariesByName)
            if not any(not resolvedPath.is_relative_to(iExtractedPackage.installRoot) for resolvedPath in resolvedPaths):
                Log.error(
                    f"Imported shared library \"{deploymentEntry.importedTargetName}\" was expected to resolve outside the "
                    f"package \"{iExtractedPackage.packagePath}\", but no such resolution was observed."
                )

    def __findElfFilesUnder(self, iRoot: Path) -> tuple[Path, ...]:
        """Returns ELF files found recursively under iRoot."""
        if not iRoot.exists():
            return tuple()

        elfFiles: list[Path] = []
        for path in sorted(iRoot.rglob("*")):
            if not path.is_file():
                continue
            try:
                with path.open("rb") as binaryFile:
                    if binaryFile.read(4) == b"\x7fELF":
                        elfFiles.append(path)
            except OSError:
                continue

        return tuple(elfFiles)

    def __collectResolvedLinuxSharedLibraries(self, iElfFiles: tuple[Path, ...], iPackagePath: Path) -> dict[str, set[Path]]:
        """Runs ldd for packaged ELF files and collects resolved shared libraries by library name."""
        resolvedLibrariesByName: dict[str, set[Path]] = {}
        for elfFile in iElfFiles:
            lddOutput = Process.runCommand(["ldd", str(elfFile)], iCaptureOutput=True, iCheck=False)
            assert lddOutput is not None

            for line in lddOutput.stdout.splitlines():
                if "=>" not in line:
                    continue

                libraryName, resolvedPart = line.split("=>", maxsplit=1)
                libraryName = libraryName.strip()
                resolvedPathStr = resolvedPart.split("(", maxsplit=1)[0].strip()
                if resolvedPathStr == "not found":
                    Log.error(f"Shared library \"{libraryName}\" required by \"{elfFile}\" was not resolved in package \"{iPackagePath}\".")
                if resolvedPathStr == "":
                    continue

                resolvedLibrariesByName.setdefault(libraryName, set()).add(Path(resolvedPathStr))

        return resolvedLibrariesByName

    def __sharedLibraryNamesForPaths(self, iPaths: tuple[Path, ...]) -> set[str]:
        """Returns possible runtime names for shared-library files, including SONAME values when available."""
        sharedLibraryNames: set[str] = set()
        for path in iPaths:
            sharedLibraryNames.add(path.name)
            if path.exists():
                sharedLibraryNames.add(path.resolve().name)

                sonameOutput = Process.runCommand(["readelf", "-d", str(path)], iCaptureOutput=True, iCheck=False)
                assert sonameOutput is not None
                for line in sonameOutput.stdout.splitlines():
                    match = re.search(r"Library soname: \[(.+)\]", line)
                    if match is not None:
                        sharedLibraryNames.add(match.group(1))
                        break

        return sharedLibraryNames

    @staticmethod
    def __pathsForLibraryNames(iLibraryNames: set[str], iPathsByName: dict[str, set[Path]]) -> set[Path]:
        """Returns all paths whose file names match any name from iLibraryNames."""
        matchedPaths: set[Path] = set()
        for libraryName in iLibraryNames:
            matchedPaths.update(iPathsByName.get(libraryName, set()))
        return matchedPaths

    def __setUpBuildVariantEnvironment(self) -> None:
        envSetupScript = self.buildVariant().envSetupScript
        if envSetupScript is None:
            return

        Process.applyEnvFromScript(envSetupScript, self.buildVariant().envSetupArgs)

    @staticmethod
    def _addVarPathTo_CMAKE_PREFIX_PATH(iVarName: str, iCMakePathPostfix: Path | None) -> None:
        """
        If environment variable `iVarName` does not exist - exits.\n
        Otherwise appends {`iVarName`}/`iCMakePathPostfix` to CMAKE_PREFIX_PATH, if the new path is not in CMAKE_PREFIX_PATH already.

        :param iCMakePathPostfix must be formatted as "subdir_1/.../subdir_N.
        """
        varPathStr = os.environ.get(iVarName)
        if not varPathStr:
            if (varPathStr is None):
                Log.error(f"\"{iVarName}\" environment variable is not set.")
            else:
                Log.error(f"\"{iVarName}\" environment variable is empty string.")
        varPath = Path(varPathStr)

        if iCMakePathPostfix:
            pathToAdd = varPath / iCMakePathPostfix
        else:
            pathToAdd = varPath
        pathToAdd.resolve()

        cmakePrefixPaths = os.environ.get("CMAKE_PREFIX_PATH")
        if (cmakePrefixPaths is None):
            os.environ["CMAKE_PREFIX_PATH"] = str(pathToAdd)
            return

        # Append only if pathToAdd is not already in the CMAKE_PREFIX_PATH.
        existingResolvedPaths = [Path(existingPath).resolve() for existingPath in cmakePrefixPaths.split(os.pathsep)]
        if pathToAdd not in existingResolvedPaths:
            os.environ["CMAKE_PREFIX_PATH"] = os.pathsep.join([cmakePrefixPaths, str(pathToAdd)])


    class _GraphvizTargetDependencyGraph(metaclass=ConstMetaClass):
        """
        Handles generation of dotfiles and a picture of the project target dependency graph.
        """

        __GRAPHS_DIR = "graphviz/"
        __GRAPH_NAME = "targets"
        __GRAPH_DOTFILES_SUBDIR = __GRAPH_NAME + "_src/"
        __MAIN_DOTFILE_NAME = __GRAPH_NAME + ".dot"
        __PICTURE_FORMAT = "svg"

        @staticmethod
        def dotfilesDir(iBuildDir: Path) -> Path:
            """
            Returns a path of the directory, where CMake generates dotfiles (graph's sources) of the project target dependency graph.
            """
            return iBuildDir / BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR / BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_DOTFILES_SUBDIR

        @staticmethod
        def mainDotfilePath(iBuildDir: Path) -> Path:
            """
            Returns a path of the main dotfile of the project target dependency graph, generated by CMake.
            """
            return BuildRunner._GraphvizTargetDependencyGraph.dotfilesDir(iBuildDir) / BuildRunner._GraphvizTargetDependencyGraph.__MAIN_DOTFILE_NAME

        @staticmethod
        def argForCMakeToGenerateDotfiles(iBuildDir: Path) -> str:
            """
            Returns argument for "cmake" command to generate dotfiles of the target dependency graph.
            """
            return "--graphviz=" + str(BuildRunner._GraphvizTargetDependencyGraph.mainDotfilePath(iBuildDir))

        @staticmethod
        def generateDotfiles(iBuildDir: Path) -> None:
            """
            Generates dotfiles of the project target dependency graph.\n

            The method Makes CMake to run project configuration stage again: CMake processes the top-level CMakeLists.txt and all included subdirectories to understand the project’s structure, options, and dependencies.\n
            This results in unnecessarily longer build times and cluttered logs.\n
            That's why it is not called in this script. Instead, all BuildRunners should add `argForCMakeToGenerateDotfiles()` result to a CMake generate ("cmake ... -G ...") command.
            """

            # Delete all existing graph files.
            ## Delete dotfiles.
            graphSrcDir = BuildRunner._GraphvizTargetDependencyGraph.dotfilesDir(iBuildDir)
            GoodPath.prepareDir(graphSrcDir)
            # Delete picture.
            pictureFilePath = BuildRunner._GraphvizTargetDependencyGraph.pictureFilePath(iBuildDir)
            if pictureFilePath.exists():
                os.remove(pictureFilePath)

            # Generate dotfiles.
            try:
                command: list[str] = [
                    "cmake",
                    BuildRunner._GraphvizTargetDependencyGraph.argForCMakeToGenerateDotfiles(iBuildDir),
                    str(iBuildDir)
                ]
                Process.runCommand(command)
            except subprocess.CalledProcessError as e:
                Log.warning(f"Can't generate dotfiles of the target dependency graph: {e}")
                return

        @staticmethod
        def pictureFilePath(iBuildDir: Path) -> Path:
            """
            Returns path of a picture, generated by Graphviz, using dotfiles of the project target dependency graph.
            """
            return iBuildDir / BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR / (BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_NAME + "." + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT)

        @staticmethod
        def generatePicture(iBuildDir: Path) -> None:
            """
            If finds Graphviz binaries, generates a picture of the project target dependency graph using existing dotfiles.
            """
            # Set path to Graphviz binaries.
            graphvizBinaryDir: Path | None = None
            graphvizDirStr = os.environ.get("GRAPHVIZ_DIR")
            if (graphvizDirStr):
                graphvizBinaryDir = Path(graphvizDirStr) / "bin/"

            # Generate a picture from dotfiles.
            pictureFilePath = BuildRunner._GraphvizTargetDependencyGraph.pictureFilePath(iBuildDir)
            try:
                command: list[str] = [
                    str((graphvizBinaryDir / "dot")) if graphvizBinaryDir else "dot",
                    "-T" + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT.lower(),
                    str(BuildRunner._GraphvizTargetDependencyGraph.mainDotfilePath(iBuildDir)),
                    "-o",
                    str(pictureFilePath)
                ]
                Process.runCommand(command)
            except subprocess.CalledProcessError as e:
                Log.warning(f"Graphviz can't generate target dependency graph picture: {e}")
                return
            except FileNotFoundError:
                Log.warning("Graphviz is not found. Target dependency graph picture is not generated.")
                return


    @staticmethod
    def generateGrpahvizTargetDependencyGraph(iBuildDir: Path) -> None:
        """
        Generates dotfiles of the project target dependency graph and, if finds Graphviz binaries, generates a picture using the dotfiles.\n

        The method Makes CMake to run project configuration stage again: CMake processes the top-level CMakeLists.txt and all included subdirectories to understand the project’s structure, options, and dependencies.\n
        This results in unnecessarily longer build times and cluttered logs.\n
        That's why it is not called in this script. Instead, all BuildRunners should add `argForCMakeToGenerateDotfiles()` result to a CMake generate ("cmake ... -G ...") command.
        """
        BuildRunner._GraphvizTargetDependencyGraph.generateDotfiles(iBuildDir)
        BuildRunner._GraphvizTargetDependencyGraph.generatePicture(iBuildDir)

    def _syncCompileCommandsFile(self, iBuildDir: Path) -> None:
        """
        Copies `compile_commands.json` from `iBuildDir` into `./build/`.
        """
        compileCommandsSrc = iBuildDir / BuildRunner.CMagneto__COMPILE_COMMANDS__FILE_NAME
        compileCommandsDst = GoodPath.projectRoot() / BuildRunner.CMagneto__SUBDIR_BUILD / BuildRunner.CMagneto__COMPILE_COMMANDS__FILE_NAME

        if compileCommandsSrc.exists():
            shutil.copy2(compileCommandsSrc, compileCommandsDst)
            Log.status(f"Synchronized \"{BuildRunner.CMagneto__COMPILE_COMMANDS__FILE_NAME}\" to project root.")
        elif compileCommandsDst.exists():
            compileCommandsDst.unlink()
            Log.warning(f"\"{compileCommandsSrc}\" was not generated. Removed stale project-root \"{compileCommandsDst.name}\".")
