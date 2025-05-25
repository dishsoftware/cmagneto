import os
import sys
import subprocess
import shutil
import platform
import argparse
import re
import shlex
from enum import Enum


class BuildType(Enum):
    Debug = 0
    Release = 1
    RelWithDebInfo = 2
    MinSizeRel = 3


class BuildStage(Enum):
    Generate = 0 # Generate project files.
    Compile = 1 # Compile the project (populate build directory with artifacts).
    RunTests = 2
    Install = 3 # Install the project (copy artifacts to install directory).


class RunPrecedingStages(Enum):
    Run = 0 # Run preceding stages, if their artifacts do not exist.
    Rerun = 1 # Rerun preceding stages, even if their artifacts exist.
    Skip = 2 # Skip preceding stages, even if their artifacts do not exist.


# Prohibits modification of class attributes after they are set.
class ConstMetaClass(type):
    def __setattr__(cls, key, value):
        if key in cls.__dict__:
            raise AttributeError(f"Cannot modify const member '{key}'")
        super().__setattr__(key, value)


class PrintColor(Enum):
    Red = "\033[91m"
    Green = "\033[92m"
    Yellow = "\033[93m"
    Blue = "\033[94m"
    Magenta = "\033[95m"
    Cyan = "\033[96m"
    White = "\033[97m"

def printColored(iText: str, iColor: PrintColor) -> None:
    """ Prints text in the specified color."""
    RESET_STR = "\033[0m"
    print(f"{iColor.value}{iText}{RESET_STR}")

def makeColored(iText: str, iColor: PrintColor) -> str:
    """ Returns text in the specified color."""
    RESET_STR = "\033[0m"
    return f"{iColor.value}{iText}{RESET_STR}"

def warning(iText: str) -> None:
    """ Prints a warning message in yellow color. Adds "Warning: " prefix."""
    printColored(f"Warning: {iText}", PrintColor.Yellow)

def error(iText: str) -> None:
    """ Prints an error message in red color and exits the program. Adds "Error: " prefix."""
    printColored(f"Error: {iText}", PrintColor.Red)
    sys.exit(1)

def status(iText: str) -> None:
    """ Prints an informational message in green color."""
    printColored(iText, PrintColor.Green)


def runCommand(iCommand: list[str]) -> None:
    print(makeColored("Running command: ", PrintColor.Cyan) + makeColored(f"{os.getcwd()}> ", PrintColor.Magenta) + makeColored(shlex.join(iCommand), PrintColor.Blue))
    subprocess.run(iCommand, check=True)


class BuildRunner:
    # Build/install sibdirectory names.
    SUBDIR_STATIC = "lib"
    SUBDIR_SHARED = "lib"
    SUBDIR_EXECUTABLE = "bin"
    SUBDIR_SUMMARY = "summary"

    RUN_TESTS__FILE_NAME_WE = "run_tests"
    BUILD_SUMMARY__FILE_NAME = "build_summary.txt"
    TEST_REPORT__FILE_NAME = "test_report.xml"

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

    def buildSubDirForBuildType(self, iSubDir: str, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        printColored(self, PrintColor.Red)
        error(f"{self.__class__.__name__}.run() is not implemented.")

    def buildDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to the build directory for the specified build type."""
        printColored(self, PrintColor.Red)
        error(f"{self.__class__.__name__}.run() is not implemented.")

    def exeDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory with executables in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.SUBDIR_EXECUTABLE, iBuildType)

    def sharedLibDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory with shared libs in the build directory for the specified build type.
           Note: on Windows, .dll files are the shared libraries, but CMake treats them as runtime artifacts, not library artifacts."""
        return self.buildSubDirForBuildType(BuildRunner.SUBDIR_SHARED, iBuildType)

    def staticLibDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory with static libs in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.SUBDIR_STATIC, iBuildType)

    def summaryDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory with summary files in the build directory for the specified build type."""
        return self.buildSubDirForBuildType(BuildRunner.SUBDIR_SUMMARY, iBuildType)

    def isBuildDirExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the build directory exists for the specified build type."""
        return os.path.exists(self.buildDirForBuildType(iBuildType))

    def isBuildSummaryExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the build summary file exists for the specified build type."""
        buildSummaryFilePath = os.path.join(self.summaryDirForBuildType(iBuildType), BuildRunner.BUILD_SUMMARY__FILE_NAME)
        return os.path.exists(buildSummaryFilePath)

    def _runTests(self, iBuildType: BuildType) -> None:
        text = f"Running tests ({iBuildType.name})"
        status(text + "...")

        run_tests__scriptDir = self.exeDirForBuildType(iBuildType)
        run_tests__scriptName = BuildRunner.FIND_IN_DIR_FILE_WITH_NAME_WE(run_tests__scriptDir, BuildRunner.RUN_TESTS__FILE_NAME_WE)
        if run_tests__scriptName is None:
            warning(f"Script \"{BuildRunner.RUN_TESTS__FILE_NAME_WE}\" not found in \"{run_tests__scriptDir}\". Tests have not been run. Use set_up__run_tests__script() in the root CMakeLists.txt to set up the script.")
        else:
            run_tests__scriptPath = os.path.join(run_tests__scriptDir, run_tests__scriptName)
            BuildRunner.RUN_SCRIPT(run_tests__scriptPath)

        status(text + " finished.\n")

    def isTestReportExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the test report file exists for the specified build type."""
        testReportFilePath = os.path.join(self.summaryDirForBuildType(iBuildType), BuildRunner.TEST_REPORT__FILE_NAME)
        return os.path.exists(testReportFilePath)

    def installDir(self) -> str:
        """Returns the absolute path to the install directory."""
        return self.__installDir

    def installDirForBuildType(self, iBuildType: BuildType) -> str:
        """Returns the absolute path to the install directory for the specified build type."""
        return os.path.join(self.__installDir, iBuildType.name)

    def isInstallDirExistForBuildType(self, iBuildType: BuildType) -> bool:
        """Returns True if the install directory exists for the specified build type."""
        return os.path.exists(self.installDirForBuildType(iBuildType))

    def setCMakeFlags(self, iFlags: list[str]) -> None:
        """These flags are passed to CMake on generation stage."""
        self.__cmakeFlags = iFlags

    def cmakeFlags(self) -> list[str] | None:
        return self.__cmakeFlags

    def isStageRequired(self, iBuildStageOfStage: BuildStage, iBuildType: BuildType, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> bool:
        """Checks if the build stage (iBuildStageOfStage) is required to run based on existence of its artifacts for the iBuildType,
           requested iBuildStage and iRunPrecedingStages option."""

        isStageRequiredLambda = lambda iBuildStageOfStage, iArtifactExistenceChecker, iBuildType, iBuildStage: \
            iBuildStage == iBuildStageOfStage or \
            iBuildStage.value > iBuildStageOfStage.value and (iRunPrecedingStages == RunPrecedingStages.Rerun or (iRunPrecedingStages == RunPrecedingStages.Run and not iArtifactExistenceChecker(iBuildType)))

        match iBuildStageOfStage:
            case BuildStage.Generate:
                return isStageRequiredLambda(BuildStage.Generate, self.isBuildDirExistForBuildType, iBuildType, iBuildStage)
            case BuildStage.Compile:
                return isStageRequiredLambda(BuildStage.Compile, self.isBuildSummaryExistForBuildType, iBuildType, iBuildStage)
            case BuildStage.RunTests:
                return isStageRequiredLambda(BuildStage.RunTests, self.isTestReportExistForBuildType, iBuildType, iBuildStage)
            case BuildStage.Install:
                return isStageRequiredLambda(BuildStage.Install, self.isInstallDirExistForBuildType, iBuildType, iBuildStage)
            case _:
                error(f"Invalid logics of {__file__}: unknown build stage: {iBuildStageOfStage}.")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        printColored(self, PrintColor.Red)
        error(f"{self.__class__.__name__}.run() is not implemented.")

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
                error(f"\"{iVarName}\" environment variable is not set.")
            else:
                error(f"\"{iVarName}\" environment variable is empty string.")

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

    class _GraphvizTargetDependencyGraph(metaclass=ConstMetaClass):
        __GRAPHS_DIR = "graphviz"
        __GRAPH_NAME = "targets"
        __GRAPH_SRC_SUBDIR = __GRAPH_NAME + "_src"
        __DOT_FILE_NAME = __GRAPH_NAME + ".dot"
        __PICTURE_FORMAT = "svg"

        @staticmethod
        def GRAPH_SRC_DIR(iBuildDir: str) -> str:
            """
            Returns path to the directory where Graphviz source files are generated.
            """
            return os.path.join(iBuildDir, BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR, BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_SRC_SUBDIR)

        @staticmethod
        def DOT_FILE_PATH(iBuildDir: str) -> str:
            """
            Returns path to the generated dot file.
            """
            return os.path.join(BuildRunner._GraphvizTargetDependencyGraph.GRAPH_SRC_DIR(iBuildDir), BuildRunner._GraphvizTargetDependencyGraph.__DOT_FILE_NAME)

        @staticmethod
        def ARGS_TO_CMAKE_GENERATE_CMD(iBuildDir: str) -> str:
            """
            Returns arguments for CMake's "generate" command to generate Graphviz dependency graph.
            """
            return "--graphviz=" + BuildRunner._GraphvizTargetDependencyGraph.DOT_FILE_PATH(iBuildDir)

        @staticmethod
        def CREATE_PICTURE(iBuildDir: str) -> None:
            """
            Creates graph picture using existing dot files.
            """
            # Set path to Graphviz binaries.
            graphvizDir = os.environ.get("GRAPHVIZ_DIR")
            if (graphvizDir):
                graphvizDir = os.path.join(graphvizDir, "bin")

            # Create picture from dot files.
            pictureFilePath = os.path.join(iBuildDir, BuildRunner._GraphvizTargetDependencyGraph.__GRAPHS_DIR, BuildRunner._GraphvizTargetDependencyGraph.__GRAPH_NAME + "." + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT)
            try:
                command = [
                    os.path.join(graphvizDir, "dot") if graphvizDir else "dot",
                    "-T" + BuildRunner._GraphvizTargetDependencyGraph.__PICTURE_FORMAT.lower(),
                    BuildRunner._GraphvizTargetDependencyGraph.DOT_FILE_PATH(iBuildDir),
                    "-o",
                    pictureFilePath
                ]
                runCommand(command)
            except subprocess.CalledProcessError as e:
                warning(f"Graphviz can't create target dependency graph picture: {e}")
                return
            except FileNotFoundError:
                warning("Graphviz is not found. Target dependency graph picture is not created.")
                return

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
            command = [
                "cmake",
                "--graphviz=" + dotFilePath,
                iBuildDir
            ]
            runCommand(command)
        except subprocess.CalledProcessError as e:
            warning(f"Can't create Graphviz target dependency graph: {e}")
            return

        # Set path to Graphviz binaries.
        graphvizDir = os.environ.get("GRAPHVIZ_DIR")
        if (graphvizDir):
            graphvizDir = os.path.join(graphvizDir, "bin")

        # Create picture from dot files.
        try:
            command = [
                os.path.join(graphvizDir, "dot") if graphvizDir else "dot",
                "-T" + PICTURE_FORMAT.lower(),
                dotFilePath,
                "-o",
                pictureFilePath
            ]
            runCommand(command)
        except subprocess.CalledProcessError as e:
            warning(f"Graphviz can't create target dependency graph picture: {e}")
            return
        except FileNotFoundError:
            warning("Graphviz is not found. Target dependency graph picture is not created.")
            return

    @staticmethod
    def FIND_IN_DIR_FILE_WITH_NAME_WE(iDir: str, iFileNameWE: str) -> str | None:
        """
        Returns file_name_with_extension of a file with the name_without_extension iFileNameWE in the directory iDir. Search is non-recursive.
        """
        for fileName in os.listdir(iDir):
            fileNameWE, ext = os.path.splitext(fileName)
            if fileNameWE == iFileNameWE and os.path.isfile(os.path.join(iDir, fileName)):
                return fileName

        return None

    @staticmethod
    def RUN_SCRIPT(iScriptPath: str, iArgs: list[str] | None = None) -> None:
        OS_NAME = platform.system()
        filePathWE, ext = os.path.splitext(iScriptPath)
        command = None
        if OS_NAME == "Windows":
            if ext == ".bat":
                command = [iScriptPath]
        else: # Linux, MacOS
            if ext == ".sh":
                command = [iScriptPath]

        if command is None:
            error(f"Method \"RUN_SCRIPT\" does not support scripts with extension \"{ext}\" on OS \"{OS_NAME}\". \"{iScriptPath} has not been run.")
        else:
            if iArgs is not None:
                command.extend(iArgs)

            runCommand(command)


class BuiildRunnerSingleConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set):
        super().__init__(iToolsetName, iGeneratorName, iCPPCompilerName, False, iBuildTypes)

    def buildDirForBuildType(self, iBuildType) -> str:
        """Returns the absolute path to the build directory for the specified build type.."""
        return os.path.join(self.buildDir(), iBuildType.name)

    def buildSubDirForBuildType(self, iSubDir: str, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        return os.path.join(self.buildDirForBuildType(iBuildType), iSubDir)

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        for buildType in self.buildTypes():
            if (self.isStageRequired(BuildStage.Generate, buildType, iBuildStage, iRunPrecedingStages)):
                self.__generate(buildType)

            if (self.isStageRequired(BuildStage.Compile, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compile(buildType)

            if (self.isStageRequired(BuildStage.RunTests, buildType, iBuildStage, iRunPrecedingStages)):
                self._runTests(buildType)

            if (self.isStageRequired(BuildStage.Install, buildType, iBuildStage, iRunPrecedingStages)):
                self.__install(buildType)

    def __generate(self, iBuildType: BuildType) -> None:
        text = f"Project generation ({iBuildType.name})"
        status(text + "...")

        buildDir = self.buildDirForBuildType(iBuildType)
        BuildRunner._PREPARE_DIR(buildDir)
        os.chdir(buildDir)
        self._set_dependency_paths()
        command = self.__compose_generate_command(iBuildType)
        runCommand(command)
        os.chdir(self.srcDir())

        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(buildDir)

        status(text + " finished.\n")

    def __compose_generate_command(self, iBuildType: BuildType) -> list[str]:
        command = [ "cmake" ]
        if self.cmakeFlags() is not None:
            command.extend(self.cmakeFlags())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.ARGS_TO_CMAKE_GENERATE_CMD(self.buildDirForBuildType(iBuildType)))

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
        status(text + "...")

        # It does not matter from which folder "cmake --build" is called, because the build directory is absolute.
        command = ["cmake", "--build", self.buildDirForBuildType(iBuildType)]
        runCommand(command)

        status(text + " finished.\n")

    def __install(self, iBuildType: BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.installDirForBuildType(iBuildType))

        # It does not matter from which folder "cmake --install" is called, because the build directory is absolute.
        command = ["cmake", "--install", self.buildDirForBuildType(iBuildType)]
        runCommand(command)

        status(text + " finished.\n")


class BuildRunnerMultiConfig(BuildRunner):
    def __init__(self, iToolsetName: str, iGeneratorName: str, iCPPCompilerName: str | None, iBuildTypes: set):
        super().__init__(iToolsetName, iGeneratorName, iCPPCompilerName, True, iBuildTypes)

    def buildDirForBuildType(self, iBuildType) -> str:
        """Returns the absolute path to the build directory for the specified build type.."""
        return self.buildDir()

    def buildSubDirForBuildType(self, iSubDir: str, iBuildType: BuildType) -> str:
        """Returns the absolute path to a subdirectory in the build directory for the specified build type."""
        return os.path.join(self.buildDirForBuildType(iBuildType), iSubDir, iBuildType.name)

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages) -> None:
        if (self.isStageRequired(BuildStage.Generate, BuildType.Release, iBuildStage, iRunPrecedingStages)):
            # ^ BuildType.Release can be replaced with any build type, because the build directory is the same for all build types in multi-config mode.
            self.__generate()

        for buildType in self.buildTypes():
            if (self.isStageRequired(BuildStage.Compile, buildType, iBuildStage, iRunPrecedingStages)):
                self.__compile(buildType)

            if (self.isStageRequired(BuildStage.RunTests, buildType, iBuildStage, iRunPrecedingStages)):
                self._runTests(buildType)

            if (self.isStageRequired(BuildStage.Install, buildType, iBuildStage, iRunPrecedingStages)):
                self.__install(buildType)

    def __generate(self) -> None:
        text = "Project generation (multi-config)"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.buildDir())
        os.chdir(self.buildDir())
        self._set_dependency_paths()
        command = self.__compose_generate_command()
        runCommand(command)
        os.chdir(self.srcDir())

        BuildRunner._GraphvizTargetDependencyGraph.CREATE_PICTURE(self.buildDir())

        status(text + " finished.\n")

    def __compose_generate_command(self) -> list[str]:
        command = [ "cmake" ]
        if self.cmakeFlags() is not None:
            command.extend(self.cmakeFlags())

        command.extend([
            "-G", self.generatorName()
        ])

        command.append(BuildRunner._GraphvizTargetDependencyGraph.ARGS_TO_CMAKE_GENERATE_CMD(self.buildDir()))

        if self.cppCompilerName() is not None:
            command.append("-DCMAKE_CXX_COMPILER=" + self.cppCompilerName())

        command.extend(self._extra_args_for_generate_command())

        command.extend([
            # Install directory is overriden in __install.
            # It is set here in case installing is started not using "cmake --install", but from IDE's UI.
            "-DCMAKE_INSTALL_PREFIX=" +  os.path.join(self.installDir(), "INSTALLED_USING_IDE"),
            self.srcDir()
        ])

        return command

    def _extra_args_for_generate_command(self) -> list[str]:
        return []

    def __compile(self, iBuildType: BuildType) -> None:
        text = f"Compiling ({iBuildType.name})"
        status(text + "...")

        # It does not matter from which folder "cmake --build" is called, because the build directory is absolute.
        command = [
            "cmake",
            "--build", self.buildDir(),
            "--config", iBuildType.name
        ]
        runCommand(command)

        status(text + " finished.\n")

    def __install(self, iBuildType: BuildType) -> None:
        text = f"Installing ({iBuildType.name})"
        status(text + "...")

        BuildRunner._PREPARE_DIR(self.installDirForBuildType(iBuildType))

        # It does not matter from which folder "cmake --install" is called, because the build directory is absolute.
        command = [
            "cmake",
            "--install", self.buildDir(),
            "--config", iBuildType.name,
            "--prefix", self.installDirForBuildType(iBuildType)
        ]
        runCommand(command)

        status(text + " finished.\n")


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
    else: # E.g. "Darwin":
        error(f"OS \"{OS_NAME}\" is not supported.")

    if len(ToolsetEnum) == 0:
        error("No toolsets are supportted for the OS. Exiting.")

    parser = argparse.ArgumentParser(
        description=\
f"Builds the CMake project.\n\
Build pipeline consists of the following stages: {", ".join([buildStage.name for buildStage in BuildStage])}.\n\
Supported OSes: Linux, Windows.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    DEFAULT_TOOLSET = list(ToolsetEnum)[0]
    parser.add_argument(
        "--toolset",
        choices=[toolset.name for toolset in ToolsetEnum],
        default=DEFAULT_TOOLSET.name,
        help=\
f"Select a toolset. Default is {DEFAULT_TOOLSET.name}.\n\
Note: the set of available toolsets depends on the OS the script is run on."
    )
    DEFAULT_BUILD_TYPE = BuildType.Release
    parser.add_argument(
        "--build_types",
        type=str,
        choices=[buildType.name for buildType in BuildType],
        nargs="+",  # Allow one or more values
        default=[DEFAULT_BUILD_TYPE.name],
        help=\
f"Specifies the build type(s). Default is {DEFAULT_BUILD_TYPE.name}.\n\
Example: \"--build_types {BuildType.Debug.name} {BuildType.Release.name}\"."
    )
    DEFAULT_BUILD_STAGE = max(BuildStage, key=lambda e: e.value) # The last stage is the default.
    parser.add_argument(
        "--build_stage",
        type=str,
        choices=[buildStage.name for buildStage in BuildStage],
        default=DEFAULT_BUILD_STAGE.name,
        help=f"Specifies build stage to run. Default is {DEFAULT_BUILD_STAGE.name}."
    )
    DEFAULT_RPS = RunPrecedingStages.Run
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        type=str,
        choices=[rps.name for rps in RunPrecedingStages],
        default=DEFAULT_RPS.name,
        help=\
f"Specifies whether to run preceding build stages. Default is {DEFAULT_RPS.name}.\n\
{RunPrecedingStages.Run.name}: if artifacts of preceding build stages, left from a previous build, do not exist, the stages are run too.\n\
{RunPrecedingStages.Rerun.name}: run preceding build stages even if their artifacts exist.\n\
{RunPrecedingStages.Skip.name}: skip preceding build stages, even if their artifacts do not exist.\n\
Artifact of {BuildStage.Generate.name} stage is the build directory.\n\
Artifact of {BuildStage.Compile.name} stage is \"{BuildRunner.BUILD_SUMMARY__FILE_NAME}\".\n\
Artifact of {BuildStage.RunTests.name} stage is \"{BuildRunner.TEST_REPORT__FILE_NAME}\".\n\
Artifact of {BuildStage.Install.name} stage is the install directory.\n\
Note: only the presence of preceding stage artifacts is checked, not the success of execution of a previous build.\n\
Note: \"{BuildRunner.TEST_REPORT__FILE_NAME}\" is not deleted, if project is recompiled.\n\
If a build stage fails during current build, the next stages are not run."
    )
    parser.add_argument(
        "--BUILD_SHARED_LIBS",
        action="store_true",
        help="Build implicit type (DEFAULT) libraries as shared. It is possible to override this option for each library, using --LIB_<NAME>_SHARED=ON|OFF|DEFAULT. " \
        "Library name must be typed in uppercase."
    )

    args, unknownArgs = parser.parse_known_args()
    # Parse unknown arguments that are in the form of LIB_<name>_SHARED=ON|OFF|DEFAULT.
    libSharedOptions = {}
    for arg in unknownArgs[:]:
        if not arg.startswith("--"):
            continue

        # Remove leading "--".
        processedArg = arg[2:]

        # Check if the argument is in the form of LIB_<name>_SHARED=ON|OFF|DEFAULT.
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
        libName = option[4:-7]

        # Check if the library name is valid.
        if re.match(r"^_+$", libName):
            warning(f"Invalid library name \"{libName}\". It must not be composed only of underscores.")
            continue

        if not re.match(r"^[A-Z_][A-Z0-9_]*$", libName):
            warning(f"Invalid library name \"{libName}\". Expected letters, digits and underscores. Must start with a letter or underscore.")
            continue

        libSharedOptions[libName] = optionVal
        unknownArgs.remove(arg)

    toolset = ToolsetEnum[args.toolset]
    if toolset not in BUILD_RUNNERS:
        error(f"{toolset} is not supported yet.")

    buildTypes = {BuildType[buildType] for buildType in args.build_types}
    buildStage = BuildStage[args.build_stage]
    runPrecedingStages = RunPrecedingStages[args.run_preceding_stages]

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

    buildRunner = BUILD_RUNNERS[toolset](buildTypes)
    buildRunner.setCMakeFlags(cmakeFlags)
    buildRunner.run(buildStage, runPrecedingStages)


if __name__ == "__main__":
    main()
