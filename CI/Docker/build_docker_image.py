# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
build.py

This one-command Docker image build script is a part of the CMagneto CMake module.

For usage details and available options, run:
```
    python ./build_docker_image.py --help
```
Relative to the project root location must be preserved, but script can be run from any working directory: it uses paths relative to its own location.
"""

from enum import Enum
from pathlib import Path
from typing import Dict, NoReturn, cast
import argparse
import re
import sys

# Add the project root to `sys.path`.
scriptsDir = Path(__file__).resolve().parent.parent.parent
sys.path.append(str(scriptsDir))

from scripts.python_utils import *
from scripts.MetadataHolder import MetadataHolder


class DockerBuildRunner:
    class BuildStage(Enum):
        GenerateEnvFile = 0 # Does not do anything with images, just creates DockerfileDir/.tmp/DockerfileName.env, where "DockerfileDir/DockerfileName" is --file argument value.
        Build = 1
        Push = 2


    class RunPrecedingStages(Enum):
        Run = 0 # Run preceding stages.
        Skip = 1 # Skip preceding stages.


    # Label names, which must be defined in Dockerfiles. Values of these labels must be defined in a single line with "LABEL labelName=".
    ## "version": version of an the image, not the project.
    REQUIRED_LABEL_NAMES = {"version"}

    @staticmethod
    def EXTRACT_REQUIRED_LABELS(iDockerfilePath: Path) -> Dict[str, str]:
        iDockerfilePath = iDockerfilePath.resolve()

        labels: Dict[str, str] = {}
        with iDockerfilePath.open() as textFile:
            for line in textFile:
                for labelName in DockerBuildRunner.REQUIRED_LABEL_NAMES:
                    pattern = r'LABEL\s+' + labelName + r'\s*=\s*"([^"]+)"'
                    if f"LABEL" in line:
                        labelMatch = re.search(pattern, line)
                        if labelMatch:
                            labelValue = labelMatch.group(1)
                            labels[labelName] = labelValue

        missingLabelNames = set()
        for labelName in DockerBuildRunner.REQUIRED_LABEL_NAMES:
            if not labelName in labels:
                missingLabelNames.add(labelName)
        if missingLabelNames:
            error(f"Dockerfile \"${iDockerfilePath}\" does not contain the required label(s): {", ".join(missingLabelNames)}.")
        return labels

    def __init__(self, iDockerfilePath: Path):
        self.__projectDockerRoot = Path(__file__).resolve().parent # Directory where this file is located.
        self.__dockerFilePath = iDockerfilePath.resolve()

        if not self.__dockerFilePath.exists() or not self.__dockerFilePath.is_file():
            error(f"Invalid file: \"${self.__dockerFilePath}\".")

        dockerFileName = str(self.__dockerFilePath.name)
        dockerFileNameSuffix = dockerFileName.removeprefix("Dockerfile.") # E.g. Ubuntu24AMD__build.
        dockerFileNameSuffixSubstrings = dockerFileNameSuffix.split("__")
        getDockerFileNameSuffixSubstring = lambda iIdx: dockerFileNameSuffixSubstrings[iIdx] \
            if len(dockerFileNameSuffixSubstrings) > iIdx and dockerFileNameSuffixSubstrings[iIdx] \
            else error(f"Dockerfile name must be composed as 'Dockerfile.<Platform>__<EnvType>', e.g. 'Dockerfile.Ubuntu24AMD__build'. But filename is '{dockerFileName}'.")

        self.__platform: str = getDockerFileNameSuffixSubstring(0)
        self.__envType: str = getDockerFileNameSuffixSubstring(1)

        companyNameShort = MetadataHolder.GET_METADATA_VALUE(Path("./Project.json"), ["CompanyName_SHORT"])
        projectNameBase = MetadataHolder.GET_METADATA_VALUE(Path("./Project.json"), ["ProjectNameBase"])
        projectVersion = MetadataHolder.GET_METADATA_VALUE(Path("./Project.json"), ["ProjectVersion"])
        if not (isinstance(companyNameShort, str) and isinstance(projectNameBase, str) and isinstance(projectVersion, str)):
            error(f"{__class__.__name__}: can't get required metadata.")

        self.__localImageName = f"{companyNameShort}_{projectNameBase}_{projectVersion}__{dockerFileNameSuffix}".lower()
        self.__imageDescription = f"{self.__platform} image with {self.__envType} environment for {companyNameShort} {projectNameBase} {projectVersion}. Image version is not related to version of {companyNameShort} {projectNameBase}."

        self.__dockerRegistry = MetadataHolder.GET_METADATA_VALUE(Path("./CI.json"), ["DockerRegistry"])
        dockerRegistrySuffix = MetadataHolder.GET_METADATA_VALUE(Path("./CI.json"), ["DockerRegistrySuffix"])
        if not (isinstance(self.__dockerRegistry, str) and isinstance(dockerRegistrySuffix, str)):
            error(f"{__class__.__name__}: can't get required metadata.")

        self.__remoteImageName = f"{self.__dockerRegistry}/{dockerRegistrySuffix}/{self.__localImageName}"

        self.__imageMaintainer = MetadataHolder.GET_METADATA_VALUE(Path("./CI.json"), ["DockerMaintainer"])
        if not isinstance(self.__imageMaintainer, str):
            error(f"{__class__.__name__}: can't get required metadata.")

        requiredLabels = DockerBuildRunner.EXTRACT_REQUIRED_LABELS(self.__dockerFilePath)
        self.__imageVersion = requiredLabels.get("version")
        if (self.__imageVersion is None):
            error(f"'{self.__dockerFilePath}' must contain 'version' label.")

    def projectDockerRoot(self) -> Path:
        return self.__projectDockerRoot

    def dockerFilePath(self) -> Path:
        return self.__dockerFilePath

    def platform(self) -> str:
        return self.__platform

    def envType(self) -> str:
        return self.__envType

    def localImageName(self) -> str:
        """Returns name of image to build in local registry."""
        return self.__localImageName

    def imageDescription(self) -> str:
        return self.__imageDescription

    def dockerRegistry(self) -> str:
        return self.__dockerRegistry

    def remoteImageName(self) -> str:
        """Returns name of image to push into remote registry."""
        return self.__remoteImageName

    def imageMaintainer(self) -> str:
        return self.__imageMaintainer

    def imageVersion(self) -> str:
        """Returns version (tag) of the image to be built."""
        return cast(str, self.__imageVersion)

    def generateEnvFile(self):
        text = f"Generation of .env file"
        status(text + "...")

        envFileContent: str = ""
        envFileContent += f"PLATFORM={self.platform()}\n"
        envFileContent += f"ENV_TYPE={self.envType()}\n"
        envFileContent += f"LOCAL_IMAGE_NAME={self.localImageName()}\n"
        envFileContent += f"REMOTE_IMAGE_NAME={self.remoteImageName()}\n"
        envFileContent += f"IMAGE_VERSION={self.imageVersion()}"

        envFilePath = self.dockerFilePath().parent / ".tmp" / (str(self.dockerFilePath().name) + ".env")

        envFilePath.parent.mkdir(parents=True, exist_ok=True)
        with open(envFilePath, "w", encoding="utf-8") as file:
            file.write(envFileContent)

        status(text + " finished.\n")

    def build(self):
        text = f"Building docker image"
        status(text + "...")

        command = [
            "docker", "build",
            "-f", str(self.dockerFilePath()),
            "-t", f"{self.localImageName()}:{self.imageVersion()}",
            "--label", f"name={self.localImageName()}",
            "--label", f"description={self.imageDescription()}",
            "--label", f"maintainer={self.imageMaintainer()}",
            str(self.dockerFilePath().parent)
        ]
        runCommand(command)

        status(text + " finished.\n")

    def push(self):
        text = f"Pushing docker image"
        status(text + "...")

        commandTag = [
            "docker", "tag",
            f"{self.localImageName()}:{self.imageVersion()}",
            f"{self.remoteImageName()}:{self.imageVersion()}"
        ]
        runCommand(commandTag)

        commandLogin = ["docker", "login", self.dockerRegistry()]
        runCommand(commandLogin)

        commandPush = [
            "docker", "push",
            f"{self.remoteImageName()}:{self.imageVersion()}"
        ]
        runCommand(commandPush)

        status(text + " finished.\n")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages):
        isStageRequiredLamda = lambda iBuildStageOfStage, iBuildStage:  \
            iBuildStage == iBuildStageOfStage or \
            iRunPrecedingStages == DockerBuildRunner.RunPrecedingStages.Run and iBuildStage.value > iBuildStageOfStage.value

        if isStageRequiredLamda(DockerBuildRunner.BuildStage.GenerateEnvFile, iBuildStage):
            self.generateEnvFile()

        if isStageRequiredLamda(DockerBuildRunner.BuildStage.Build, iBuildStage):
            self.build()

        if isStageRequiredLamda(DockerBuildRunner.BuildStage.Push, iBuildStage):
            self.push()


def main():
    parser = argparse.ArgumentParser(
        description=\
f"Builds Docker images.\n\
The build pipeline consists of the following stages: {', '.join([buildStage.name for buildStage in DockerBuildRunner.BuildStage])}.\n\
\n\
NOTE! All file paths in the message are given relative to the project root.\n\
\n\
Image name is generated as {{CompanyName_SHORT}}_{{ProjectNameBase}}_{{ProjectVersion}}__{{DockerFileNameSuffix}},\n\
where CompanyName_SHORT, ProjectNameBase and ProjectVersion are variables from './meta/Project.json';\n\
DockerFileNameSuffix is a substring of a used Dockerfile name: 'Dockerfile.DockerFileNameSuffix'.\n\
DockerFileNameSuffix must be composed as {{Platform}}__{{EnvType}}, e.g. 'Ubuntu24AMD__build'.\n\
\n\
{DockerBuildRunner.__name__} requires Dockerfiles to define the following labels: {', '.join(DockerBuildRunner.REQUIRED_LABEL_NAMES)}.\n\
Values of these labels must be defined in a single line: 'LABEL labelName=\"labelValue\"'.\n\
\n\
Pushes images to {{DockerRegistry}}/{{DockerRegistrySuffix}}/, where DockerRegistry and DockerRegistrySuffix are variables from './meta/CI.json'.\n\
An example of pushed image name: registry.gitlab.com/enowsw/contactholder/enow_contactholder_1.0.0__ubuntu24amd__build.\n\
\n\
Uses other variables from JSON files in 'meta/' to define image labels.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--file", "-f",
        type=Path,
        required=True,
        help="Path to a Dockerfile."
    )
    DEFAULT_BUILD_STAGE = max(DockerBuildRunner.BuildStage, key=lambda e: e.value) # The last stage is the default.
    parser.add_argument(
        "--build_stage",
        type=str,
        choices=[buildStage.name for buildStage in DockerBuildRunner.BuildStage],
        default=DEFAULT_BUILD_STAGE.name,
        help=f"Specify build stage to run. Default is {DEFAULT_BUILD_STAGE.name}."
    )
    DEFAULT_RPS = DockerBuildRunner.RunPrecedingStages.Run
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        type=str,
        choices=[rps.name for rps in DockerBuildRunner.RunPrecedingStages],
        default=DEFAULT_RPS.name,
        help=f"Specify whether to run preceding build stages. Default is {DEFAULT_RPS.name}."
    )

    args = parser.parse_args()

    dockerFilePath = args.file
    buildStage = DockerBuildRunner.BuildStage[args.build_stage]
    runPrecedingStages = DockerBuildRunner.RunPrecedingStages[args.run_preceding_stages]

    buildRunner = DockerBuildRunner(dockerFilePath)
    buildRunner.run(buildStage, runPrecedingStages)


if __name__ == "__main__":
    main()