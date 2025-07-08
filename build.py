# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
build.py

This one-command build script is a part of the CMagneto CMake module.

For usage details and available options, run:
```
    python ./build.py --help
```
Relative to the project root location must be preserved, but script can be run from any working directory: it uses paths relative to its own location.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from enum import Enum
from pathlib import Path
from scripts.python_utils import *
from typing import cast
import argparse
import inspect
import os
import platform
import re
import subprocess
import shutil


class BuildRunner(ABC):
    """
    Properly calls "cmake" commands. Works in coordination with the CMagneto CMake module.
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
    CMagneto__SUBDIR_STATIC = Path("lib/")
    CMagneto__SUBDIR_SHARED = Path("lib/")
    CMagneto__SUBDIR_EXECUTABLE = Path("bin/")
    CMagneto__SUBDIR_SUMMARY = Path("summary/")
    CMagneto__SUBDIR_PACKAGES = Path("packages/")

    CMagneto__BUILD_SUMMARY__FILE_NAME = "build_summary.txt"
    CMagneto__TEST_BUILD_SUMMARY__FILE_NAME = "test_build_summary.txt"
    CMagneto__RUN_TESTS__SCRIPT_NAME_WE = "run_tests"
    CMagneto__TEST_REPORT__FILE_NAME = "test_report.xml"
    ##################################################################################################

    def __init__(self, iToolsetName: str, iGeneratorName: str, iMultiConfig: bool, iCPPCompilerName: str | None, iBuildTypes: set[BuildType]):
        if (iToolsetName is None) or (iToolsetName.isspace()):
            raise ValueError("Toolset name cannot be None or empty.")

        if (iGeneratorName is None) or (iGeneratorName.isspace()):
            raise ValueError("Generator name cannot be None or empty.")

        self.__toolsetName = iToolsetName
        self.__generatorName = iGeneratorName
        self.__multiConfig = iMultiConfig
        self.__cppCompilerName = iCPPCompilerName
        self.__buildTypes = iBuildTypes
        self.__cmakeFlagsFor__generate__command: list[str] = list()
        self.__projectRoot = Path(__file__).resolve().parent # Directory where this file is located.
        self.__buildDir    = self.__projectRoot / "build" / iToolsetName
        self.__installDir  = self.__projectRoot / "install" / iToolsetName

    @staticmethod
    @abstractmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        error(f"Static method \"{methodName}\" is not implemented by this subclass of the {BuildRunner.__qualname__}.")

    def __str__(self) -> str:
        text = \
        f"Toolset name: \"{self.__toolsetName}\"\n" + \
        f"Generator: \"{self.__generatorName}\"\n" + \
        f"Generator is multi-config: {self.__multiConfig}\n"

        if self.__cppCompilerName is not None:
            text += f"C++ compiler: \"{self.__cppCompilerName}\"\n"
        else:
            text += f"C++ compiler: default\n"

        text += \
        f"Build types: {', '.join([buildType.name for buildType in self.__buildTypes])}\n"

        if self.__cmakeFlagsFor__generate__command:
            text += "CMake flags for `generate` command: \"" + " ".join(self.__cmakeFlagsFor__generate__command) + "\"\n"

        text += \
        f"Project root:      \"{self.__projectRoot}\"\n" + \
        f"Build directory:   \"{self.__buildDir}\"\n" + \
        f"Install directory: \"{self.__installDir}\"\n"
        return text

    def toolsetName(self) -> str:
        return self.__toolsetName

    def generatorName(self) -> str:
        return self.__generatorName

    def cppCompilerName(self) -> str | None:
        return self.__cppCompilerName

    def multiConfig(self) -> bool:
        return self.__multiConfig

    def buildTypes(self) -> set[BuildType]:
        return self.__buildTypes

    def setCMakeFlagsFor__generate__command(self, iFlags: list[str]) -> None:
        """These flags are passed to CMake on generation stage."""
        self.__cmakeFlagsFor__generate__command = iFlags

    def cmakeFlagsFor__generate__command(self) -> list[str]:
        return self.__cmakeFlagsFor__generate__command

    def projectRoot(self) -> Path:
        """Returns the absolute path to the project root directory."""
        return self.__projectRoot

    def buildDir(self) -> Path:
        """Returns the absolute path to the build directory."""
        return self.__buildDir

    def buildSubDirForBuildType(self, iSubDir: Path, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        error(f"{self.__class__.__name__}.{methodName} is not implemented.")

    def buildDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        error(f"{self.__class__.__name__}.{methodName} is not implemented.")

    def exeDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with executables in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.CMagneto__SUBDIR_EXECUTABLE, iBuildType)

    def sharedLibDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory with shared libs in the build directory for the specified build type.
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
        status(text + "...")

        run_tests__scriptDir = self.exeDirForBuildType(iBuildType)
        run_tests__scriptName = BuildRunner.FIND_IN_DIR_FILE_WITH_NAME_WE(run_tests__scriptDir, BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE)
        if run_tests__scriptName is None:
            warning(f"Script \"{BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE}\" was not found in \"{run_tests__scriptDir}\". Tests have not been run. Call CMagnetoInternal__set_up__run_tests__script() in the root CMakeLists.txt to set up the script.")
        else:
            run_tests__scriptPath = run_tests__scriptDir / run_tests__scriptName
            BuildRunner.RUN_SCRIPT(run_tests__scriptPath)

        status(text + " finished.\n")

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
        for root, _, files in os.walk(packagesDir):
            if files:
                return True
        return False

    def isStageRequired(self, iBuildStageOfStage: BuildStage, iBuildType: BuildType, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> bool:
        """Checks if the build stage (iBuildStageOfStage) is required to run based on existence of its artifacts for the iBuildType,
           requested iBuildStage and iRunPrecedingStages option."""

        isStageRequiredLambda = lambda iBuildStageOfStage, iArtifactExistenceChecker, iBuildType, iBuildStage: \
            iBuildStage == iBuildStageOfStage or \
            iBuildStage.value > iBuildStageOfStage.value and \
            (iRunPrecedingStages == BuildRunner.RunPrecedingStages.Rerun or (iRunPrecedingStages == BuildRunner.RunPrecedingStages.Run and not iArtifactExistenceChecker(iBuildType)))

        match iBuildStageOfStage:
            case BuildRunner.BuildStage.Generate:
                return isStageRequiredLambda(BuildRunner.BuildStage.Generate, self.isBuildDirExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Compile:
                return isStageRequiredLambda(BuildRunner.BuildStage.Compile, self.isBuildSummaryExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.CompileTests:
                return isStageRequiredLambda(BuildRunner.BuildStage.CompileTests, self.isCompiledTestsFileExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.RunTests:
                return isStageRequiredLambda(BuildRunner.BuildStage.RunTests, self.isTestReportExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Install:
                return isStageRequiredLambda(BuildRunner.BuildStage.Install, self.isInstallDirExistForBuildType, iBuildType, iBuildStage)
            case BuildRunner.BuildStage.Package:
                return isStageRequiredLambda(BuildRunner.BuildStage.Package, self.isPackageExistForBuildType, iBuildType, iBuildStage)
            case _:
                error(f"Invalid logics of {__file__}: unknown build stage: {iBuildStageOfStage}.")

    def _package(self, iBuildType: BuildType) -> None:
        text = f"Packaging ({iBuildType.name})"
        status(text + "...")

        os.chdir(self.buildDirForBuildType(iBuildType))
        command: list[str] = ["cpack"]
        runCommand(command)
        os.chdir(self.projectRoot())

        status(text + " finished.\n")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        error(f"{self.__class__.__name__}.{methodName} is not implemented.")

    def _setDependencyPaths(self) -> None:
        pass

    @staticmethod
    def _PREPARE_DIR(iDir: Path) -> None:
        """Creates/cleans iDir."""
        if iDir.exists():
            shutil.rmtree(iDir)

        os.makedirs(iDir, exist_ok=True)

    @staticmethod
    def _ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH(iVarName: str, iCMakePathPostfix: Path | None) -> None:
        """
        If environment variable `iVarName` does not exist - exits.
        Otherwise appends {`iVarName`}/`iCMakePathPostfix` to CMAKE_PREFIX_PATH, if the new path is not in CMAKE_PREFIX_PATH already.

        :param iCMakePathPostfix must be formatted as "subdir_1/.../subdir_N.
        """
        varPathStr = os.environ.get(iVarName)
        if not varPathStr:
            if (varPathStr is None):
                error(f"\"{iVarName}\" environment variable is not set.")
            else:
                error(f"\"{iVarName}\" environment variable is empty string.")
        varPath = Path(cast(str, varPathStr))

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
        Handles creation of dotfiles and a picture of the project target dependency graph.
        """

        __GRAPHS_DIR = "graphviz/"
        __GRAPH_NAME = "targets"
        __GRAPH_DOTFILES_SUBDIR = __GRAPH_NAME + "_src/"
        __MAIN_DOTFILE_NAME = __GRAPH_NAME + ".dot"
        __PICTURE_FORMAT = "svg"

        @staticmethod
        def GRAPH_DOTFILES_DIR(iBuildDir: Path) -> Path:
            """
            Returns a path of the directory, where CMake generates dotfiles (graph's sources) of the project target dependency graph.
            """
            return iBuildDir / BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR / BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_DOTFILES_SUBDIR

        @staticmethod
        def MAIN_DOTFILE_PATH(iBuildDir: Path) -> Path:
            """
            Returns a path of the main dotfile of the project target dependency graph, generated by CMake.
            """
            return BuildRunner._GraphvizTargetDependencyGraph.GRAPH_DOTFILES_DIR(iBuildDir) / BuildRunner._GraphvizTargetDependencyGraph.__MAIN_DOTFILE_NAME

        @staticmethod
        def ARG_FOR_CMAKE_TO_GENERATE_DOTFILES(iBuildDir: Path) -> str:
            """
            Returns argument for "cmake" command to generate dotfiles of the target dependency graph.
            """
            return "--graphviz=" + str(BuildRunner._GraphvizTargetDependencyGraph.MAIN_DOTFILE_PATH(iBuildDir))

        @staticmethod
        def CREATE_DOT_FILES(iBuildDir: Path) -> None:
            """
            Creates dotfiles of the project target dependency graph.

            The method Makes CMake to run project configuration stage again: CMake processes the top-level CMakeLists.txt and all included subdirectories to understand the project’s structure, options, and dependencies.
            This results in unnecessarily longer build times and cluttered logs.
            That's why it is not called in this script. Instead, all BuildRunners should add ARG_FOR_CMAKE_TO_GENERATE_DOTFILES() result to a CMake generate ("cmake ... -G ...") command.
            """

            # Delete all existing graph files.
            ## Delete dotfiles.
            graphSrcDir = BuildRunner._GraphvizTargetDependencyGraph.GRAPH_DOTFILES_DIR(iBuildDir)
            BuildRunner._PREPARE_DIR(graphSrcDir)
            # Delete picture.
            pictureFilePath = BuildRunner._GraphvizTargetDependencyGraph.PICTURE_FILE_PATH(iBuildDir)
            if pictureFilePath.exists():
                os.remove(pictureFilePath)

            # Create dotfiles.
            try:
                command: list[str] = [
                    "cmake",
                    BuildRunner._GraphvizTargetDependencyGraph.ARG_FOR_CMAKE_TO_GENERATE_DOTFILES(iBuildDir),
                    str(iBuildDir)
                ]
                runCommand(command)
            except subprocess.CalledProcessError as e:
                warning(f"Can't create dotfiles of the target dependency graph: {e}")
                return

        @staticmethod
        def PICTURE_FILE_PATH(iBuildDir: Path) -> Path:
            """
            Returns path of a picture, generated by Graphviz, using dotfiles of the project target dependency graph.
            """
            return iBuildDir / BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR / (BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_NAME + "." + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT)

        @staticmethod
        def CREATE_PICTURE(iBuildDir: Path) -> None:
            """
            If finds Graphviz binaries, creates a picture of the project target dependency graph using existing dotfiles.
            """
            # Set path to Graphviz binaries.
            graphvizBinaryDir: Path | None = None
            graphvizDirStr = os.environ.get("GRAPHVIZ_DIR")
            if (graphvizDirStr):
                graphvizBinaryDir = Path(graphvizDirStr) / "bin/"

            # Create a picture from dotfiles.
            pictureFilePath = BuildRunner._GraphvizTargetDependencyGraph.PICTURE_FILE_PATH(iBuildDir)
            try:
                command: list[str] = [
                    str((graphvizBinaryDir / "dot")) if graphvizBinaryDir else "dot",
                    "-T" + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT.lower(),
                    str(BuildRunner._GraphvizTargetDependencyGraph.MAIN_DOTFILE_PATH(iBuildDir)),
                    "-o",
                    str(pictureFilePath)
                ]
                runCommand(command)
            except subprocess.CalledProcessError as e:
                warning(f"Graphviz can't create target dependency graph picture: {e}")
                return
            except FileNotFoundError:
                warning("Graphviz is not found. Target dependency graph picture is not created.")
                return


    @staticmethod
    def CREATE_GRAPHVIZ_TARGET_DEPENDENCY_GRAPH(iBuildDir: Path) -> None:
        """
        Creates dotfiles of the project target dependency graph and, if finds Graphviz binaries, creates a picture using the dotfiles.

        The method Makes CMake to run project configuration stage again: CMake processes the top-level CMakeLists.txt and all included subdirectories to understand the project’s structure, options, and dependencies.
        This results in unnecessarily longer build times and cluttered logs.
        That's why it is not called in this script. Instead, all BuildRunners should add ARG_FOR_CMAKE_TO_GENERATE_DOTFILES() result to a CMake generate ("cmake ... -G ...") command.
        """
        BuildRunner._GraphvizTargetDependencyGraph.CREATE_DOT_FILES(iBuildDir)
        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(iBuildDir)

    @staticmethod
    def FIND_IN_DIR_FILE_WITH_NAME_WE(iDir: Path, iFileNameWE: str) -> Path | None:
        """
        Returns fileName of a file with the iFileNameWE (name without extension), which is found first in the iDir (non-recursively).
        """
        for item in iDir.iterdir():
            if item.is_file() and iFileNameWE == item.stem:
                return Path(item.name)
        return None

    @staticmethod
    def RUN_SCRIPT(iScriptPath: Path, iArgs: list[str] | None = None) -> None:
        OS_NAME = platform.system()
        dotExt = iScriptPath.suffix
        command: list[str] | None = None
        if OS_NAME == "Windows":
            if dotExt == ".bat":
                command = [str(iScriptPath)]
        else: # Linux, MacOS
            if dotExt == ".sh":
                command = [str(iScriptPath)]

        if command is None:
            error(f"Method \"RUN_SCRIPT\" does not support scripts with extension \"{dotExt}\" on OS \"{OS_NAME}\". \"{iScriptPath} has not been run.")
        else:
            if iArgs is not None:
                command.extend(iArgs)
            runCommand(command)


class BuildRunnerSingleConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__(iToolsetName, iGeneratorName, False, iCPPCompilerName, iBuildTypes)

    def __str__(self) -> str:
        text = super().__str__()

        for buildType in self.buildTypes():
            extraArgsFor__generate__command = self._extraArgsFor__generate__command(buildType)
            if not extraArgsFor__generate__command:
                continue
            text += f"Extra args for `generate` ${buildType} command: \"" + " ".join(extraArgsFor__generate__command) + "\"\n"

        return text

    def buildDirForBuildType(self, iBuildType) -> Path:
        """Returns the absolute path to the build directory for the specified build type.."""
        return self.buildDir() / iBuildType.name

    def buildSubDirForBuildType(self, iSubDir: Path, iBuildType: BuildRunner.BuildType) -> Path:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        return self.buildDirForBuildType(iBuildType) / iSubDir

    def run(self, iBuildStage: BuildRunner.BuildStage, iRunPrecedingStages: BuildRunner.RunPrecedingStages) -> None:
        for buildType in self.buildTypes():
            if (self.isStageRequired(BuildRunner.BuildStage.Generate, buildType, iBuildStage, iRunPrecedingStages)):
                self.__generate(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.Compile, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compile(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.CompileTests, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compileTests(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.RunTests, buildType, iBuildStage, iRunPrecedingStages)):
                self._runTests(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.Install, buildType, iBuildStage, iRunPrecedingStages)):
                self.__install(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.Package, buildType, iBuildStage, iRunPrecedingStages)):
                self._package(buildType)

    def __generate(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Generation of build system files ({iBuildType.name})"
        status(text + "...")

        buildDir = self.buildDirForBuildType(iBuildType)
        BuildRunner._PREPARE_DIR(buildDir)
        os.chdir(buildDir)
        self._setDependencyPaths()
        command: list[str] = self.__compose__generate__command(iBuildType)
        runCommand(command)
        os.chdir(self.projectRoot())

        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(buildDir)

        status(text + " finished.\n")

    def __compose__generate__command(self, iBuildType: BuildRunner.BuildType) -> list[str]:
        command: list[str] = [ "cmake" ]
        command.extend(self.cmakeFlagsFor__generate__command())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.ARG_FOR_CMAKE_TO_GENERATE_DOTFILES(self.buildDirForBuildType(iBuildType)))

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + str(self.cppCompilerName()))

        command.extend(self._extraArgsFor__generate__command(iBuildType))

        command.extend([
            "-DCMAKE_BUILD_TYPE=" + iBuildType.name,
            "-DCMAKE_INSTALL_PREFIX=" + str(self.installDirForBuildType(iBuildType)),
            str(self.projectRoot())
        ])

        return command

    def _extraArgsFor__generate__command(self, iBuildType: BuildRunner.BuildType) -> list[str]:
        return []

    def __compile(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType))]
        runCommand(command)

        status(text + " finished.\n")

    def __compileTests(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling tests ({iBuildType.name})"
        status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType)), "--target", "build_tests"]
        runCommand(command)

        status(text + " finished.\n")

    def __install(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.installDirForBuildType(iBuildType))

        command: list[str] = ["cmake", "--install", str(self.buildDirForBuildType(iBuildType))]
        runCommand(command)

        status(text + " finished.\n")


class BuildRunnerMultiConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__(iToolsetName, iGeneratorName, True, iCPPCompilerName, iBuildTypes)

    def __str__(self) -> str:
        text = super().__str__()

        extraArgsFor__generate__command = self._extraArgsFor__generate__command()
        if extraArgsFor__generate__command:
            text += f"Extra args for `generate` command: \"" + " ".join(extraArgsFor__generate__command) + "\"\n"

        return text

    def buildDirForBuildType(self, iBuildType) -> Path:
        """Returns the absolute path to the build directory for the specified build type.."""
        return self.buildDir()

    def buildSubDirForBuildType(self, iSubDir: Path, iBuildType: BuildRunner.BuildType) -> Path:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        return self.buildDirForBuildType(iBuildType) / iSubDir / iBuildType.name

    def run(self, iBuildStage: BuildRunner.BuildStage, iRunPrecedingStages: BuildRunner.RunPrecedingStages) -> None:
        if (self.isStageRequired(BuildRunner.BuildStage.Generate, BuildRunner.BuildType.Release, iBuildStage, iRunPrecedingStages)):
            # ^ BuildType.Release can be replaced with any build type, because the build directory is the same for all build types in multi-config mode.
            self.__generate()

        for buildType in self.buildTypes():
            if (self.isStageRequired(BuildRunner.BuildStage.Compile, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compile(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.CompileTests, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compileTests(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.RunTests, buildType, iBuildStage, iRunPrecedingStages)):
                self._runTests(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.Install, buildType, iBuildStage, iRunPrecedingStages)):
                self.__install(buildType)

            if (self.isStageRequired(BuildRunner.BuildStage.Package, buildType, iBuildStage, iRunPrecedingStages)):
                self._package(buildType)

    def __generate(self) -> None:
        text = "Generation of build system files (multi-config)"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.buildDir())
        os.chdir(str(self.buildDir()))
        self._setDependencyPaths()
        command: list[str] = self.__compose__generate__command()
        runCommand(command)
        os.chdir(str(self.projectRoot()))

        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(self.buildDir())
        # Graphviz creates a target dependecy graph during generation time.
        # If a single-config generator is used, the graph is unambiguously created for CMAKE_BUILD_TYPE.
        # But what is going on, if a multi-config generator is used and linking logics depends on $<CONFIG>?
        #
        # With Multi-config generator, CMake does not know which configuration will be built during generation.
        # It generates build rules for all configurations (Debug, Release, etc.).
        # Generator expressions like $<CONFIG> are preserved as expressions in the generated build system files.
        # So, at generation time, CMake cannot fully resolve conditional logics based on $<CONFIG>.
        # This has a direct impact on --graphviz=... output:
        # 1) The dependency graph, created by Graphviz, will reflect a union of targets and dependencies across all configurations;
        # 2) If certain targets or libraries are only linked in some configurations (e.g., $<CONFIG:Debug>), they might:
        #    appear in the graph as "possible" dependencies,
        #    or be omitted altogether, depending on how conditional linking logics is and how CMake interprets the generator expressions during graph creation.
        # The graph may be ambiguous or incomplete, compared to what actually gets built under a specific configuration like Release.

        status(text + " finished.\n")

    def __compose__generate__command(self) -> list[str]:
        command: list[str] = [ "cmake" ]
        command.extend(self.cmakeFlagsFor__generate__command())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.ARG_FOR_CMAKE_TO_GENERATE_DOTFILES(self.buildDir()))

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + str(self.cppCompilerName()))

        command.extend(self._extraArgsFor__generate__command())

        command.extend([
            # Install directory is overriden in __install.
            # It is set here in case installing is started not using "cmake --install", but from IDE's UI.
            "-DCMAKE_INSTALL_PREFIX=" +  os.path.join(self.installDir(), "INSTALLED_USING_IDE"),
            str(self.projectRoot())
        ])

        return command

    def _extraArgsFor__generate__command(self) -> list[str]:
        return []

    def __compile(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        status(text + "...")

        command: list[str] = [
            "cmake",
            "--build", str(self.buildDir()),
            "--config", iBuildType.name
        ]
        runCommand(command)

        status(text + " finished.\n")

    def __compileTests(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling tests ({iBuildType.name})"
        status(text + "...")

        command: list[str] = [
            "cmake",
            "--build", str(self.buildDir()),
            "--target", "build_tests",
            "--config", iBuildType.name
        ]
        runCommand(command)

        status(text + " finished.\n")

    def __install(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.installDirForBuildType(iBuildType))

        command: list[str] = [
            "cmake",
            "--install", str(self.buildDir()),
            "--config", iBuildType.name,
            "--prefix", str(self.installDirForBuildType(iBuildType))
        ]
        runCommand(command)

        status(text + " finished.\n")


class UnixMakefilesGCCRunner(BuildRunnerSingleConfig):
    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("UnixMakefiles_GCC", "Unix Makefiles", "g++", iBuildTypes)

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return UnixMakefilesGCCRunner(iBuildTypes)


class MinGWMakefilesMinGWRunner(BuildRunnerSingleConfig):
    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("MinGW", "MinGW Makefiles", None, iBuildTypes)

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return UnixMakefilesGCCRunner(iBuildTypes)


class VS2022MSVCRunner(BuildRunnerMultiConfig):
    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("VS2022_MSVC", "Visual Studio 17 2022", None, iBuildTypes)

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return VS2022MSVCRunner(iBuildTypes)

    def _setDependencyPaths(self) -> None:
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("QT6_MSVC2022_DIR", Path("lib/cmake"))
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("BOOST_MSVC2022_DIR", Path("cmake"))

    def _extraArgsFor__generate__command(self) -> list[str]:
        return [
            "-A", "x64"
        ]


class BuildToolsetHolder(metaclass=ConstMetaClass):
    __OS_NAME = platform.system()


    class LinuxToolset(Enum):
        UnixMakefiles_GCC = 0

    LINUX_BUILD_RUNNERS: dict[LinuxToolset, type[BuildRunner]] = {
        LinuxToolset.UnixMakefiles_GCC: UnixMakefilesGCCRunner
    }


    class WindowsToolset(Enum):
        MinGW = 0 # MinGW Makefiles and MinGW compiler.
        # The MinGW name does not follow the accepted naming convention {BuildSystem}_{Compiler}, because for this case the conventional name is too long.
        VS2022_MSVC = 1 # Visual Studio 2022 with MSVC compiler.

    WINDOWS_BUILD_RUNNERS: dict[WindowsToolset, type[BuildRunner]] = {
        WindowsToolset.MinGW: MinGWMakefilesMinGWRunner,
        WindowsToolset.VS2022_MSVC: VS2022MSVCRunner
    }


    @staticmethod
    def AVAILABLE_TOOLSETS() -> type[Enum]:
        if BuildToolsetHolder.__OS_NAME == "Linux":
            return BuildToolsetHolder.LinuxToolset
        elif BuildToolsetHolder.__OS_NAME == "Windows":
            return BuildToolsetHolder.WindowsToolset
        else: # E.g. "Darwin":
            error(f"OS \"{BuildToolsetHolder.__OS_NAME}\" is not supported.")

    @staticmethod
    def AVAILABLE_BUILD_RUNNNERS() -> dict[Enum, type[BuildRunner]]:
        if BuildToolsetHolder.__OS_NAME == "Linux":
            return BuildToolsetHolder.LINUX_BUILD_RUNNERS  # type: ignore
        elif BuildToolsetHolder.__OS_NAME == "Windows":
            return BuildToolsetHolder.WINDOWS_BUILD_RUNNERS  # type: ignore
        else: # E.g. "Darwin":
            error(f"OS \"{BuildToolsetHolder.__OS_NAME}\" is not supported.")


def main():
    TOOLSET_ENUM = BuildToolsetHolder.AVAILABLE_TOOLSETS()
    BUILD_RUNNERS = BuildToolsetHolder.AVAILABLE_BUILD_RUNNNERS()

    if len(TOOLSET_ENUM) == 0:
        error("No toolsets are supportted for the OS. Exiting.")

    parser = argparse.ArgumentParser(
        description=\
f"Builds the CMake project.\n\
The build pipeline consists of the following stages: {', '.join([buildStage.name for buildStage in BuildRunner.BuildStage])}.\n\
Supported OSes: Linux, Windows.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    DEFAULT_TOOLSET = list(TOOLSET_ENUM)[0]
    parser.add_argument(
        "--toolset",
        choices=[toolset.name for toolset in TOOLSET_ENUM],
        default=DEFAULT_TOOLSET.name,
        help=\
f"Select a toolset. Default is {DEFAULT_TOOLSET.name}.\n\
Note: the set of available toolsets depends on the OS the script is run on."
    )
    DEFAULT_BUILD_TYPE = BuildRunner.BuildType.Release
    parser.add_argument(
        "--build_types",
        type=str,
        choices=[buildType.name for buildType in BuildRunner.BuildType],
        nargs="+",  # Allow one or more values
        default=[DEFAULT_BUILD_TYPE.name],
        help=\
f"Specify build types. Default is {DEFAULT_BUILD_TYPE.name}.\n\
Example: \"--build_types {BuildRunner.BuildType.Debug.name} {BuildRunner.BuildType.Release.name}\"."
    )
    DEFAULT_BUILD_STAGE = max(BuildRunner.BuildStage, key=lambda e: e.value) # The last stage is the default.
    parser.add_argument(
        "--build_stage",
        type=str,
        choices=[buildStage.name for buildStage in BuildRunner.BuildStage],
        default=DEFAULT_BUILD_STAGE.name,
        help=f"Specify a build stage to run. Default is {DEFAULT_BUILD_STAGE.name}."
    )
    DEFAULT_RPS = BuildRunner.RunPrecedingStages.Run
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        type=str,
        choices=[rps.name for rps in BuildRunner.RunPrecedingStages],
        default=DEFAULT_RPS.name,
        help=\
f"Specify whether to run preceding build stages. Default is {DEFAULT_RPS.name}.\n\
{BuildRunner.RunPrecedingStages.Run.name}: if artifacts of preceding build stages, left from a previous build, do not exist, the stages are run too.\n\
{BuildRunner.RunPrecedingStages.Rerun.name}: run preceding build stages even if their artifacts exist.\n\
{BuildRunner.RunPrecedingStages.Skip.name}: skip preceding build stages, even if their artifacts do not exist.\n\
Artifact of {BuildRunner.BuildStage.Generate.name} stage is a corresponding subdirectory of \"./build/\".\n\
Artifact of {BuildRunner.BuildStage.Compile.name} stage is a \"{BuildRunner.CMagneto__BUILD_SUMMARY__FILE_NAME}\".\n\
Artifact of {BuildRunner.BuildStage.CompileTests.name} stage is a \"{BuildRunner.CMagneto__TEST_BUILD_SUMMARY__FILE_NAME}\".\n\
Artifact of {BuildRunner.BuildStage.RunTests.name} stage is a \"{BuildRunner.CMagneto__TEST_REPORT__FILE_NAME}\".\n\
Artifact of {BuildRunner.BuildStage.Install.name} stage is a corresponding subdirectory of \"./install/\".\n\
Atrifact of {BuildRunner.BuildStage.Package.name} stage is any file in a \"{BuildRunner.CMagneto__SUBDIR_PACKAGES}\" subdirectory (recursively).\n\
Note: only the presence of preceding stage artifacts is checked, not the success of execution of a previous build.\n\
Note: {BuildRunner.BuildStage.CompileTests.name} stage does not check, whether {BuildRunner.BuildStage.Compile.name} stage was rerun;\n\
     \"{BuildRunner.CMagneto__TEST_REPORT__FILE_NAME}\" is not deleted automatically, if tests are recompiled.\n\
If a build stage fails during current build, the next stages are not run."
    )
    parser.add_argument(
        "--BUILD_SHARED_LIBS",
        action="store_true",
        help=\
f"Build implicit type (DEFAULT) libraries as shared.\n\
It is possible to override this option for each library, using --LIB_{{LibTargetName}}_SHARED=ON|OFF|DEFAULT. Library name must be typed in uppercase."
    )

    args, unknownArgs = parser.parse_known_args()
    # Parse unknown arguments that are in the form of LIB_{LibTargetName}_SHARED=ON|OFF|DEFAULT.
    libSharedOptions = {}
    for arg in unknownArgs[:]:
        if not arg.startswith("--"):
            continue

        # Remove leading "--".
        processedArg = arg[2:]

        # Check if the argument is in the form of LIB_{LibTargetName}_SHARED=ON|OFF|DEFAULT.
        optionAndVal = processedArg.split("=")
        if len(optionAndVal) != 2:
            continue

        option = optionAndVal[0]
        optionVal = optionAndVal[1]

        if not option.startswith("LIB_") or not option.endswith("_SHARED"):
            continue

        if optionVal not in ["ON", "OFF", "DEFAULT"]:
            continue

        # Remove "LIB_" prefix and "_SHARED" suffix.
        libTargetName = option[4:-7]

        # Check if the library name is valid.
        if re.match(r"^_+$", libTargetName):
            warning(f"Invalid library name \"{libTargetName}\". It must not be composed only of underscores.")
            continue

        if not re.match(r"^[A-Z_][A-Z0-9_]*$", libTargetName):
            warning(f"Invalid library name \"{libTargetName}\". Expected letters, digits and underscores. Must start with a letter or underscore.")
            continue

        libSharedOptions[libTargetName] = optionVal
        unknownArgs.remove(arg)

    toolset = TOOLSET_ENUM[args.toolset]
    if toolset not in BUILD_RUNNERS:
        error(f"{toolset} is not supported yet.")

    buildTypes: set[BuildRunner.BuildType] = {BuildRunner.BuildType[argBuildType] for argBuildType in args.build_types}
    buildStage: BuildRunner.BuildStage = BuildRunner.BuildStage[args.build_stage]
    runPrecedingStages: BuildRunner.RunPrecedingStages = BuildRunner.RunPrecedingStages[args.run_preceding_stages]

    flag__BUILD_SHARED_LIBS = "-DBUILD_SHARED_LIBS=ON" if args.BUILD_SHARED_LIBS else "-DBUILD_SHARED_LIBS=OFF"
    cmakeFlags = [flag__BUILD_SHARED_LIBS]

    for lib, sharedOption in libSharedOptions.items():
        if sharedOption == "ON":
            cmakeFlags.append(f"-DLIB_{lib}_SHARED=ON")
        elif sharedOption == "OFF":
            cmakeFlags.append(f"-DLIB_{lib}_SHARED=OFF")
        elif sharedOption == "DEFAULT":
            # Do nothing.
            pass
        else:
            error(f"Invalid logics of \"{__file__}\": LIB_{lib}_SHARED is of invalid value \"{sharedOption}\". \"ON\", \"OFF\" or \"DEFAULT\" are expected.")

    for processedArg in unknownArgs:
        warning(f"Unknown argument: \"{processedArg}\". Ignored.")

    buildRunner: BuildRunner = BUILD_RUNNERS[toolset].create(buildTypes)
    buildRunner.setCMakeFlagsFor__generate__command(cmakeFlags)
    message(str(buildRunner))
    buildRunner.run(buildStage, runPrecedingStages)


if __name__ == "__main__":
    main()
