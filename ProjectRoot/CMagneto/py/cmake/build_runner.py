# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
build_runner.py

The location relative to the project root must be preserved.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.utils import ConstMetaClass, Utils
from enum import Enum
from pathlib import Path
from typing import cast
import inspect
import os
import platform
import shutil
import subprocess


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

    @staticmethod
    @abstractmethod
    def toolsetName() -> str:
        """Toolset name should be composed as {BuildSystemName}_{CompilerName}.\n
           Toolset names are used to register concrete BuildRunner subclasses in BuildRunnerHolder and must be unique."""

    @staticmethod
    @abstractmethod
    def supportedOSes() -> set[BuildPlatform.OS]:
        """Returns OS set, the BuildRunner subclass supports."""

    @staticmethod
    @abstractmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        """Creates an instance of the BuildRunner subclass."""

    def __init__(self, iGeneratorName: str, iMultiConfig: bool, iCPPCompilerName: str | None, iBuildTypes: set[BuildType]):
        assert Utils.isDirNamePortable(type(self).toolsetName())
        assert not iGeneratorName.isspace()

        self.__generatorName = iGeneratorName
        self.__multiConfig = iMultiConfig
        self.__cppCompilerName = iCPPCompilerName
        self.__buildTypes = iBuildTypes
        self.__cmakeFlagsFor__generate__command: list[str] = list()
        os.chdir(Utils.projectRoot())
        self.__buildDir    = Utils.projectRoot() / "build" / type(self).toolsetName()
        self.__installDir  = Utils.projectRoot() / "install" / type(self).toolsetName()

    def __str__(self) -> str:
        text = \
        f"Toolset name: \"{type(self).toolsetName()}\"\n" + \
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
        f"Project root:      \"{Utils.projectRoot()}\"\n" + \
        f"Build directory:   \"{self.__buildDir}\"\n" + \
        f"Install directory: \"{self.__installDir}\"\n"
        return text

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

    def buildDir(self) -> Path:
        """Returns the absolute path to the build directory."""
        return self.__buildDir

    def buildSubDirForBuildType(self, iSubDir: Path, iBuildType: BuildType) -> Path:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Utils.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

    def buildDirForBuildType(self, iBuildType: BuildType) -> Path:
        """Returns the absolute path to the build directory for the specified build type."""
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Utils.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

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
        Utils.status(text + "...")

        run_tests__scriptDir = self.exeDirForBuildType(iBuildType)
        run_tests__scriptName = BuildRunner.findInDirFileWithNameWE(run_tests__scriptDir, BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE)
        if run_tests__scriptName is None:
            Utils.warning(f"Script \"{BuildRunner.CMagneto__RUN_TESTS__SCRIPT_NAME_WE}\" was not found in \"{run_tests__scriptDir}\". Tests have not been run. Call CMagnetoInternal__set_up__run_tests__script() in the root CMakeLists.txt to set up the script.")
        else:
            run_tests__scriptPath = run_tests__scriptDir / run_tests__scriptName
            BuildRunner.runScript(run_tests__scriptPath)

        Utils.status(text + " finished.\n")

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
                Utils.error(f"Invalid logics of {__file__}: unknown build stage: {iBuildStageOfStage}.")

    def _package(self, iBuildType: BuildType) -> None:
        text = f"Packaging ({iBuildType.name})"
        Utils.status(text + "...")
        Utils.runCommand(["cpack"], self.buildDirForBuildType(iBuildType))
        Utils.status(text + " finished.\n")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        frame = inspect.currentframe()
        methodName = frame.f_code.co_name if frame is not None else "<unknown>"
        Utils.error(f"{self.__class__.__qualname__}.{methodName} is not implemented.")

    def _setDependencyPaths(self) -> None:
        pass

    @staticmethod
    def _prepareDir(iDir: Path) -> None:
        """Creates/cleans iDir."""
        if iDir.exists():
            shutil.rmtree(iDir)

        os.makedirs(iDir, exist_ok=True)

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
                Utils.error(f"\"{iVarName}\" environment variable is not set.")
            else:
                Utils.error(f"\"{iVarName}\" environment variable is empty string.")
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
            BuildRunner._prepareDir(graphSrcDir)
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
                Utils.runCommand(command)
            except subprocess.CalledProcessError as e:
                Utils.warning(f"Can't generate dotfiles of the target dependency graph: {e}")
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
                Utils.runCommand(command)
            except subprocess.CalledProcessError as e:
                Utils.warning(f"Graphviz can't generate target dependency graph picture: {e}")
                return
            except FileNotFoundError:
                Utils.warning("Graphviz is not found. Target dependency graph picture is not generated.")
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

    @staticmethod
    def findInDirFileWithNameWE(iDir: Path, iFileNameWE: str) -> Path | None:
        """
        Returns fileName of a file with the iFileNameWE (name without extension), which is found first in the iDir (non-recursively).
        """
        for item in iDir.iterdir():
            if item.is_file() and iFileNameWE == item.stem:
                return Path(item.name)
        return None

    @staticmethod
    def runScript(iScriptPath: Path, iArgs: list[str] | None = None) -> None:
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
            currentFrame = inspect.currentframe()
            Utils.error(f"Method \"{currentFrame.f_code.co_name if currentFrame else "runScript"}\" does not support scripts with extension \"{dotExt}\" on OS \"{OS_NAME}\". \"{iScriptPath} has not been run.")
        else:
            if iArgs is not None:
                command.extend(iArgs)
            Utils.runCommand(command)