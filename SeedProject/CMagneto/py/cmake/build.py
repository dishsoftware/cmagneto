# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
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

One-command project build script.

For usage details and available options, run:
```
    python ./build.py --help
```
The script can be run from any working directory.
The location relative to the project root must be preserved.
"""

# Add project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`,
# even if the script is run not from its parent dir.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
import sys
sys.path.append(str(PROJECT_ROOT))

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from CMagneto.py.utils.log import Log
import argparse
import re


def buildProject():
    Log.status(f"Host OS: {BuildPlatform().hostOS().value}")
    buildRunners = BuildRunnersHolder().availableBuildRunners()
    toolsetNames = buildRunners.keys()

    parser = argparse.ArgumentParser(
        description=\
f"Builds the CMake project.\n\
The build pipeline consists of the following stages: {', '.join([buildStage.name for buildStage in BuildRunner.BuildStage])}.\n\
Supported OSes: {', '.join(os.name for os in BuildRunnersHolder().supportedOSes())}.\n\
\n\
NOTE! All relative paths in the doc are given relative to the project root.\n\
\n",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--toolset",
        choices=toolsetNames,
        required=True,
        help=\
f"Select a toolset. The parameter is reqired.\n\
Note: the set of available toolsets depends on the OS the script is run on." \
        if len(toolsetNames) > 0 else Log.makeColored("No toolsets available for the OS!", Log.PrintColor.Yellow)
    )
    defaultBuildType = BuildRunner.BuildType.Release
    parser.add_argument(
        "--build_types",
        type=str,
        choices=[buildType.name for buildType in BuildRunner.BuildType],
        nargs="+", # Allow one or more values
        default=[defaultBuildType.name],
        help=\
f"Specify build types. Default is {defaultBuildType.name}.\n\
Example: \"--build_types {BuildRunner.BuildType.Debug.name} {BuildRunner.BuildType.Release.name}\"."
    )
    defaultBuildStage = max(BuildRunner.BuildStage, key=lambda e: e.value) # The last stage is the default.
    parser.add_argument(
        "--build_stage",
        type=str,
        choices=[buildStage.name for buildStage in BuildRunner.BuildStage],
        default=defaultBuildStage.name,
        help=f"Specify a build stage to run. Default is {defaultBuildStage.name}."
    )
    defaultRPS = BuildRunner.RunPrecedingStages.Run
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        type=str,
        choices=[rps.name for rps in BuildRunner.RunPrecedingStages],
        default=defaultRPS.name,
        help=\
f"Specify whether to run preceding build stages. Default is {defaultRPS.name}.\n\
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
    libSharedOptions: dict[str, str] = dict()
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
            Log.warning(f"Invalid library name \"{libTargetName}\". It must not be composed only of underscores.")
            continue

        if not re.match(r"^[A-Z_][A-Z0-9_]*$", libTargetName):
            Log.warning(f"Invalid library name \"{libTargetName}\". Expected letters, digits and underscores. Must start with a letter or underscore.")
            continue

        libSharedOptions[libTargetName] = optionVal
        unknownArgs.remove(arg)

    toolsetName = args.toolset
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
            Log.error(f"Invalid logics of \"{__file__}\": LIB_{lib}_SHARED is of invalid value \"{sharedOption}\". \"ON\", \"OFF\" or \"DEFAULT\" are expected.")

    if (len(unknownArgs) > 0):
        Log.error(f"Unknown arguments: {', '.join(unknownArgs)}.")

    buildRunner: BuildRunner = buildRunners[toolsetName].create(buildTypes)
    buildRunner.setCMakeFlagsFor__generate__command(cmakeFlags)
    Log.message(str(buildRunner))
    buildRunner.run(buildStage, runPrecedingStages)


if __name__ == "__main__":
    buildProject()
