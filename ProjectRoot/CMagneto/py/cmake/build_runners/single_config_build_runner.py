# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.utils import Utils
from pathlib import Path
import os


class SingleConfigBuildRunner(BuildRunner):
    def __init__(self, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__(iGeneratorName, False, iCPPCompilerName, iBuildTypes)

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
        Utils.status(text + "...")

        buildDir = self.buildDirForBuildType(iBuildType)
        BuildRunner._PREPARE_DIR(buildDir)
        os.chdir(buildDir)
        self._setDependencyPaths()
        command: list[str] = self.__compose__generate__command(iBuildType)
        Utils.runCommand(command)
        os.chdir(self.projectRoot())

        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(buildDir)

        Utils.status(text + " finished.\n")

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
        Utils.status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType))]
        Utils.runCommand(command)

        Utils.status(text + " finished.\n")

    def __compileTests(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling tests ({iBuildType.name})"
        Utils.status(text + "...")

        command: list[str] = ["cmake", "--build", str(self.buildDirForBuildType(iBuildType)), "--target", "build_tests"]
        Utils.runCommand(command)

        Utils.status(text + " finished.\n")

    def __install(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        Utils.status(text + "...")

        BuildRunner._PREPARE_DIR(self.installDirForBuildType(iBuildType))

        command: list[str] = ["cmake", "--install", str(self.buildDirForBuildType(iBuildType))]
        Utils.runCommand(command)

        Utils.status(text + " finished.\n")