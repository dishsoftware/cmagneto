import os
import sys
import subprocess
import shutil
import platform
import argparse
from enum import Enum


class BuildType(Enum):
    Debug = 0
    Release = 1
    RelWithDebInfo = 2
    MinSizeRel = 3


class RunType(Enum):
    Full = 0, # Generate and compile.
    Generate = 1
    Compile = 2


class BuildRunner:
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iSupportsMultiConfig: bool, iBuildTypes: set):
        if (iToolsetName is None) or (iToolsetName.isspace()):
            raise ValueError("Toolset name cannot be None or empty.")

        if (iGeneratorName is None) or (iGeneratorName.isspace()):
            raise ValueError("Generator name cannot be None or empty.")

        self.__toolsetName = iToolsetName
        self.__generatorName = iGeneratorName
        self.__cppCompilerName = iCPPCompilerName
        self.__supportsMultiConfig = iSupportsMultiConfig
        self.__buildTypes = iBuildTypes
        self.__srcDir     = os.path.abspath(".")
        self.__buildDir   = os.path.join(self.__srcDir, "build",   iToolsetName)
        self.__installDir = os.path.join(self.__srcDir, "install", iToolsetName)

    def __str__(self) -> str:
        return f"Toolset name: \"{self.__toolsetName}\"\n" + \
        f"Generator: \"{self.__generatorName}\"\n" + \
        f"Build directory: \"{os.path.abspath(self.__buildDir)}\"\n" + \
        f"Install directory: \"{os.path.abspath(self.__installDir)}\"" + \
        f"Buid types: {', '.join([buildType.name for buildType in self.__buildTypes])}"

    def toolsetName(self) -> str:
        return self.__toolsetName

    def generatorName(self) -> str:
        return self.__generatorName

    def cppCompilerName(self) -> str | None:
        return self.__cppCompilerName

    def supportsMultiConfig(self) -> bool:
        return self.__supportsMultiConfig

    def buildTypes(self) -> set:
        return self.__buildTypes

    def srcDir(self) -> str:
        """Returns the absolute path to the source directory."""
        return self.__srcDir

    def buildDir(self) -> str:
        """Returns the absolute path to the build directory."""
        return self.__buildDir

    def buildDirForBuildType(self, iBuildType) -> str:
        """Returns the absolute path to the build directory for the specified build type.."""
        if self.__supportsMultiConfig:
            return self.__buildDir
        else:
            return os.path.join(self.__buildDir, iBuildType.name)

    def installDir(self) -> str:
        """Returns the absolute path to the install directory."""
        return self.__installDir

    def installDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to the install directory for the specified build type."""
        return os.path.join(self.__installDir, iBuildType.name)

    def setCMakeFlags(self, iFlags: list[str]) -> None:
        """These flags are passed to CMake on generation stage."""
        self.__cmakeFlags = iFlags

    def cmakeFlags(self) -> list[str] | None:
        return self.__cmakeFlags

    def run(self, iRunType: RunType) -> None:
        print(self)
        print(f"{self.__class__.__name__}.run() is not implemented.")
        sys.exit(1)

    def _set_dependency_paths(self) -> None:
        pass

    @staticmethod
    def _PREPARE_DIR(iDir) -> None:
        """Creates/cleans iDir."""
        if os.path.exists(iDir):
            shutil.rmtree(iDir)

        os.makedirs(iDir, exist_ok=True)

    @staticmethod
    def _ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH(iVarName: str, iCMakePathPostfix: str | None) -> None:
        """
        If environment variable `iVarName` does not exist - exits.
        Otherwise appends {`iVarName`}/`iCMakePathPostfix` to CMAKE_PREFIX_PATH, if the new path is not in CMAKE_PREFIX_PATH already.

        :param iCMakePathPostfix must be formatted as "subdir_1/.../subdir_N.
        """
        varPath = os.environ.get(iVarName)
        if (not varPath):
            if (varPath is None):
                print(f"\"{iVarName}\" environment variable is not set.")
            else:
                print(f"\"{iVarName}\" environment variable is empty string.")
            sys.exit(1)

        pathToAdd = None
        if (iCMakePathPostfix):
            pathToAdd = os.path.join(varPath, *iCMakePathPostfix.split("/"))
        else:
            pathToAdd = os.path.join(varPath)

        cmakePrefixPaths = os.environ.get("CMAKE_PREFIX_PATH")
        if (cmakePrefixPaths is None):
            os.environ["CMAKE_PREFIX_PATH"] = pathToAdd
            return

        # Append only if not already in the path
        if pathToAdd not in cmakePrefixPaths.split(os.pathsep):
            os.environ["CMAKE_PREFIX_PATH"] = os.pathsep.join([cmakePrefixPaths, pathToAdd])

    @staticmethod
    def CREATE_GRAPHVIZ_TARGET_DEPENDENCY_GRAPH(iBuildDir) -> None:
        GRAPHS_DIR = "graphviz"
        GRAPH_NAME = "targets"
        GRAPH_SRC_SUBDIR = GRAPH_NAME + "_src"
        DOT_FILE_NAME = GRAPH_NAME + ".dot"
        PICTURE_FORMAT = "svg"

        graphSrcDir = os.path.join(iBuildDir, GRAPHS_DIR, GRAPH_SRC_SUBDIR)
        pictureFilePath = os.path.join(iBuildDir, GRAPHS_DIR, GRAPH_NAME + "." + PICTURE_FORMAT)

        # Delete existing {GRAPH_NAME} graph files.
        BuildRunner._PREPARE_DIR(graphSrcDir)
        if os.path.exists(pictureFilePath):
            os.remove(pictureFilePath)

        # Create dot files.
        dotFilePath = os.path.join(graphSrcDir, DOT_FILE_NAME)
        try:
            subprocess.run([
                "cmake",
                "--graphviz=" + dotFilePath,
                iBuildDir
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Can't create Graphviz target dependency graph: {e}")
            return

        # Set path to Graphviz binaries.
        graphvizDir = os.environ.get("GRAPHVIZ_DIR")
        if (graphvizDir):
            graphvizDir = os.path.join(graphvizDir, "bin")

        # Create picture from dot files.
        try:
            subprocess.run([
                os.path.join(graphvizDir, "dot"),
                "-T" + PICTURE_FORMAT.lower(),
                dotFilePath,
                "-o",
                pictureFilePath
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Graphviz can't create target dependency graph picture: {e}")
            return
        except FileNotFoundError:
            print("Graphviz is not found. Target dependency graph picture is not created.")
            return


class BuiildRunnerSingleConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set):
        super().__init__(iToolsetName, iGeneratorName, iCPPCompilerName, False, iBuildTypes)

    def run(self, iRunType: RunType) -> None:
        for buildType in self.buildTypes():
            if (
                iRunType == RunType.Full or iRunType == RunType.Generate or
                iRunType == RunType.Compile and not os.path.exists(self.buildDirForBuildType(buildType))
            ):
                self.__generate(buildType)
            if (iRunType == RunType.Full or iRunType == RunType.Compile):
                self.__compile(buildType)
                self.__install(buildType)

    def __generate(self, iBuildType: BuildType) -> None:
        text = f"Project generation ({iBuildType.name})"
        print(text + "...")

        buildDir = self.buildDirForBuildType(iBuildType)
        BuildRunner._PREPARE_DIR(buildDir)
        os.chdir(buildDir)
        self._set_dependency_paths()
        subprocess.run(self.__compose_generate_command(iBuildType), check=True)
        os.chdir(self.srcDir())

        BuildRunner.CREATE_GRAPHVIZ_TARGET_DEPENDENCY_GRAPH(buildDir)

        print(text + " finished.")

    def __compose_generate_command(self, iBuildType: BuildType) -> list[str]:
        command = [ "cmake" ]
        if self.cmakeFlags() is not None:
            command.extend(self.cmakeFlags())

        command.extend([
            "-G", self.generatorName()
        ])

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + self.cppCompilerName())

        command.extend(self._extra_args_for_generate_command(iBuildType))

        command.extend([
            "-DCMAKE_BUILD_TYPE=" + iBuildType.name,
            "-DCMAKE_INSTALL_PREFIX=" + self.installDirForBuildType(iBuildType),
            self.srcDir()
        ])

        return command

    def _extra_args_for_generate_command(self, iBuildType: BuildType) -> list[str]:
        return []

    def __compile(self, iBuildType: BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        print(text + "...")

        # It does not matter from which folder "cmake --build" is called, because the build directory is absolute.
        subprocess.run(["cmake", "--build", self.buildDirForBuildType(iBuildType)], check=True)

        print(text + " finished.")

    def __install(self, iBuildType: BuildType) -> None:
        text = f"Installation ({iBuildType.name})"
        print(text + "...")

        # It does not matter from which folder "cmake --install" is called, because the build directory is absolute.
        subprocess.run(["cmake", "--install", self.buildDirForBuildType(iBuildType)], check=True)

        print(text + " finished.")


class BuildRunnerMultiConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set):
        super().__init__(iToolsetName, iGeneratorName, iCPPCompilerName, True, iBuildTypes)

    def run(self, iRunType: RunType) -> None:
        if (
            iRunType == RunType.Full or iRunType == RunType.Generate or
            iRunType == RunType.Compile and not os.path.exists(self.buildDirForBuildType(buildType))
        ):
            self.__generate()
        if (iRunType == RunType.Full or iRunType == RunType.Compile):
            for buildType in self.buildTypes():
                self.__compile(buildType)
                self.__install(buildType)

    def __generate(self) -> None:
        text = "Project generation (multi-config)"
        print(text + "...")

        BuildRunner._PREPARE_DIR(self.buildDir())
        os.chdir(self.buildDir())
        self._set_dependency_paths()
        subprocess.run(self.__compose_generate_command(), check=True)
        os.chdir(self.srcDir())

        BuildRunner.CREATE_GRAPHVIZ_TARGET_DEPENDENCY_GRAPH(self.buildDir())

        print(text + " finished.")

    def __compose_generate_command(self) -> list[str]:
        command = [ "cmake" ]
        if self.cmakeFlags() is not None:
            command.extend(self.cmakeFlags())

        command.extend([
            "-G", self.generatorName()
        ])

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + self.cppCompilerName())

        command.extend(self._extra_args_for_generate_command())

        command.extend([
            # Install directory is overriden in __install.
            # It is set here in case installation is started not using "cmake --install", but from IDE's UI.
            "-DCMAKE_INSTALL_PREFIX=" +  os.path.join(self.installDir(), "/INSTALLED_USING_IDE"),
            self.srcDir()
        ])

        return command

    def _extra_args_for_generate_command(self) -> list[str]:
        return []

    def __compile(self, iBuildType: BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        print(text + "...")

        # It does not matter from which folder "cmake --build" is called, because the build directory is absolute.
        subprocess.run([
            "cmake",
            "--build", self.buildDir(),
            "--config", iBuildType.name
        ], check=True)

        print(text + " finished.")

    def __install(self, iBuildType: BuildType) -> None:
        text = f"Installation ({iBuildType.name})"
        print(text + "...")

        # It does not matter from which folder "cmake --install" is called, because the build directory is absolute.
        subprocess.run([
            "cmake",
            "--install", self.buildDir(),
            "--config", iBuildType.name,
            "--prefix", self.installDirForBuildType(iBuildType)
        ], check=True)

        print(text + " finished.")


class UnixMakefilesGCCRunner(BuiildRunnerSingleConfig):
    def __init__(self, iBuildTypes: set):
        super().__init__("UnixMakefiles_GCC", "Unix Makefiles", "g++", iBuildTypes)


class MinGWMakefilesMinGWRunner(BuiildRunnerSingleConfig):
    def __init__(self, iBuildTypes: set):
        super().__init__("MinGW", "MinGW Makefiles", None, iBuildTypes)


class VS2022MSVCRunner(BuildRunnerMultiConfig):
    def __init__(self, iBuildTypes: set):
        super().__init__("VS2022_MSVC", "Visual Studio 17 2022", None, iBuildTypes)

    def _set_dependency_paths(self) -> None:
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("QT6_MSVC2022_DIR", "lib/cmake")
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("BOOST_MSVC2022_DIR", "cmake")

    def _extra_args_for_generate_command(self) -> list[str]:
        return [
            "-A", "x64"
        ]


def main():
    class LinuxToolset(Enum):
        UnixMakefiles_GCC = 0

    LINUX_BUILD_RUNNERS = {
        LinuxToolset.UnixMakefiles_GCC: UnixMakefilesGCCRunner
    }

    class WindowsToolset(Enum):
        MinGWMakefiles_MinGW = 0
        VS2022_MSVC = 1

    WINDOWS_BUILD_RUNNERS = {
        WindowsToolset.MinGWMakefiles_MinGW: MinGWMakefilesMinGWRunner,
        WindowsToolset.VS2022_MSVC: VS2022MSVCRunner
    }

    class AppleToolset(Enum):
        pass

    APPLE_BUILD_RUNNERS = {}
    ######################################################################

    OS_NAME = platform.system()
    print("Identified OS: " + OS_NAME)
    ToolsetEnum = None
    BUILD_RUNNERS = None
    if OS_NAME == "Linux":
        ToolsetEnum = LinuxToolset
        BUILD_RUNNERS = LINUX_BUILD_RUNNERS
    elif OS_NAME == "Windows":
        ToolsetEnum = WindowsToolset
        BUILD_RUNNERS = WINDOWS_BUILD_RUNNERS
    elif OS_NAME == "Darwin":
        ToolsetEnum = AppleToolset
        BUILD_RUNNERS = APPLE_BUILD_RUNNERS

    if len(ToolsetEnum) == 0:
        print("No toolsets are supportted for the OS. Exiting.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Builds and compiles (optionally) the project.")
    toolsetChoices = [toolset.name for toolset in ToolsetEnum]
    defaultToolset = list(ToolsetEnum)[0].name
    parser.add_argument(
        "--toolset",
        choices=toolsetChoices,
        default=defaultToolset,
        help=f"Select a toolset. Default is {defaultToolset}."
    )
    parser.add_argument(
        "--build_types",
        type=str,
        choices=[buildType.name for buildType in BuildType],
        nargs="+",  # Allow one or more values
        default=[BuildType.Release.name],
        help=f"Specifies the build type(s). Example: \"--build_types Debug Release\". Default is {BuildType.Release.name}."
    )
    parser.add_argument(
        "--run_type",
        type=str,
        choices=[runType.name for runType in RunType],
        default=RunType.Full.name,
        help=f"Specifies run type. Full is default and triggers both generation and compilation."
    )
    parser.add_argument("--lib-contacts-shared", action="store_true", help="Build Contacts library as shared.")
    args = parser.parse_args()

    toolset = ToolsetEnum[args.toolset]
    if toolset not in BUILD_RUNNERS:
        print(f"{toolset} is not supported yet.")
        sys.exit(1)

    buildTypes = {BuildType[buildType] for buildType in args.build_types}
    runType = RunType[args.run_type]
    lib_contacts_shared_flag = "-DLIB_CONTACTS_SHARED=ON" if args.lib_contacts_shared else "-DLIB_CONTACTS_SHARED=OFF"
    cmakeFlags = [lib_contacts_shared_flag]

    buildRunner = BUILD_RUNNERS[toolset](buildTypes)
    buildRunner.setCMakeFlags(cmakeFlags)
    buildRunner.run(runType)


if __name__ == "__main__":
    main()
