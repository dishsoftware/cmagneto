# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.toolset import Toolset
from CMagneto.py.utils.good_path import GoodPath
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process
from pathlib import Path
import os


class SingleConfigBuildRunner(BuildRunner):
    def __init__(self,
            iToolset: Toolset,
            iBuildTypes: set[BuildRunner.BuildType],
            iEnableCodeCoverage: bool = False
        ):
        super().__init__(
                    iToolset,
                    iBuildTypes,
                    iEnableCodeCoverage
                )

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
        Log.status(text + "...")

        buildDir = self.buildDirForBuildType(iBuildType)
        GoodPath.prepareDir(buildDir)
        self._setDependencyPaths()
        command: list[str] = self.__compose__generate__command(iBuildType)
        Process.runCommand(command, buildDir)
        self._syncCompileCommandsFile(buildDir)

        BuildRunner._GraphvizTargetDependencyGraph.generatePicture(buildDir)

        Log.status(text + " finished.\n")

    def __compose__generate__command(self, iBuildType: BuildRunner.BuildType) -> list[str]:
        command: list[str] = [ "cmake" ]
        command.extend(self.cmakeFlagsFor__generate__command())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.argForCMakeToGenerateDotfiles(self.buildDirForBuildType(iBuildType)))

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + str(self.cppCompilerName()))

        command.extend(self._extraArgsFor__generate__command(iBuildType))

        if iBuildType == BuildRunner.BuildType.Debug and self.enableCodeCoverage():
            command.append("-DENABLE_COVERAGE=ON")

        command.extend([
            "-DCMAKE_BUILD_TYPE=" + iBuildType.name,
            "-DCMAKE_INSTALL_PREFIX=" + str(self.installDirForBuildType(iBuildType)),
            str(GoodPath.projectRoot())
        ])

        return command

    def _extraArgsFor__generate__command(self, iBuildType: BuildRunner.BuildType) -> list[str]:
        return list(self.toolset().extraGenerateArgs)

    def __compile(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        Log.status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType))]
        Process.runCommand(command)
        self._syncCompileCommandsFile(self.buildDirForBuildType(iBuildType))

        Log.status(text + " finished.\n")

    def __compileTests(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling tests ({iBuildType.name})"
        Log.status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType)), "--target", "build_tests"]
        Process.runCommand(command)

        Log.status(text + " finished.\n")

    def __install(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        Log.status(text + "...")

        GoodPath.prepareDir(self.installDirForBuildType(iBuildType))

        command: list[str] = ["cmake", "--install", str(self.buildDirForBuildType(iBuildType))]
        Process.runCommand(command)

        Log.status(text + " finished.\n")
