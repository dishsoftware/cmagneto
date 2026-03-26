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
from CMagneto.py.cmake.build_variant import BuildVariant
from CMagneto.py.utils.good_path import GoodPath
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process
from pathlib import Path
import os


class MultiConfigBuildRunner(BuildRunner):
    def __init__(self,
            iBuildVariant: BuildVariant,
            iBuildTypes: set[BuildRunner.BuildType],
            iEnableCodeCoverage: bool = False
        ):
        super().__init__(
                    iBuildVariant,
                    iBuildTypes,
                    iEnableCodeCoverage
                )

    def __str__(self) -> str:
        text = super().__str__()

        extraArgsFor__generate__command = self._extraArgsFor__generate__command()
        if extraArgsFor__generate__command:
            text += f"Extra args for `generate` command: \"" + " ".join(extraArgsFor__generate__command) + "\"\n"

        return text

    def buildDirForBuildType(self, iBuildType: BuildRunner.BuildType) -> Path:
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
        Log.status(text + "...")

        GoodPath.prepareDir(self.buildDir())
        self._setDependencyPaths()
        command: list[str] = self.__compose__generate__command()
        Process.runCommand(command, self.buildDir())
        self._syncCompileCommandsFile(self.buildDir())

        BuildRunner._GraphvizTargetDependencyGraph.generatePicture(self.buildDir())
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

        Log.status(text + " finished.\n")

    def __compose__generate__command(self) -> list[str]:
        command: list[str] = [ "cmake" ]
        command.extend(self.cmakeFlagsFor__generate__command())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.argForCMakeToGenerateDotfiles(self.buildDir()))

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + str(self.cppCompilerName()))

        command.extend(self._extraArgsFor__generate__command())

        if BuildRunner.BuildType.Debug in self.buildTypes() and self.enableCodeCoverage():
            command.append("-DENABLE_COVERAGE=ON")

        command.extend(self._cmakeFlagsFor__externalSharedLibraryPolicies())

        command.extend([
            # Install directory is overriden in __install.
            # It is set here in case installing is started not using "cmake --install", but from IDE's UI.
            "-DCMAKE_INSTALL_PREFIX=" +  os.path.join(self.installDir(), "INSTALLED_USING_IDE"),
            str(GoodPath.projectRoot())
        ])

        return command

    def _extraArgsFor__generate__command(self) -> list[str]:
        return list(self.buildVariant().extraGenerateArgs)

    def __compile(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        Log.status(text + "...")

        command: list[str] = [
            "cmake",
            "--build", str(self.buildDir()),
            "--config", iBuildType.name
        ]
        Process.runCommand(command)
        self._syncCompileCommandsFile(self.buildDir())

        Log.status(text + " finished.\n")

    def __compileTests(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Compiling tests ({iBuildType.name})"
        Log.status(text + "...")

        command: list[str] = [
            "cmake",
            "--build", str(self.buildDir()),
            "--target", "build_tests",
            "--config", iBuildType.name
        ]
        Process.runCommand(command)

        Log.status(text + " finished.\n")

    def __install(self, iBuildType: BuildRunner.BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        Log.status(text + "...")

        GoodPath.prepareDir(self.installDirForBuildType(iBuildType))

        command: list[str] = [
            "cmake",
            "--install", str(self.buildDir()),
            "--config", iBuildType.name,
            "--prefix", str(self.installDirForBuildType(iBuildType))
        ]
        Process.runCommand(command)

        Log.status(text + " finished.\n")
