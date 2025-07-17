# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from enum import Enum
from pathlib import Path
from typing import cast
import re

from CMagneto.py.docker.check_docker import checkDocker
from CMagneto.py.metadata_holder import MetadataHolder
from CMagneto.py.utils import Utils


class ImageBuildRunner:
    """
    Properly calls "docker" commands. Coupled with the CMagneto CMake module.
    """


    class BuildStage(Enum):
        GenerateEnvFile = 0 # Does not do anything with images, just creates DockerfileDir/.tmp/DockerfileName.env, where "DockerfileDir/DockerfileName" is --file argument value.
        Build = 1
        Push = 2


    class RunPrecedingStages(Enum):
        Run = 0 # Run preceding stages.
        Skip = 1 # Skip preceding stages.


    __PROJECT_DOCKERFILES_ROOT: Path = Utils.projectRoot() / "CI" / "Docker"

    # Label names, which must be defined in Dockerfiles. Values of these labels must be defined in a single line with "LABEL labelName=".
    ## "version": version of an the image, not the project.
    REQUIRED_LABEL_NAMES: set[str] = {"version"}

    @staticmethod
    def projectDockerfilesRoot() -> Path:
        """
        Absolute path to the base dir with Dockerfiles of the project.
        """
        return ImageBuildRunner.__PROJECT_DOCKERFILES_ROOT

    @staticmethod
    def extractRequiredLabels(iDockerfilePath: Path) -> dict[str, str]:
        iDockerfilePath = iDockerfilePath.resolve()

        labels: dict[str, str] = dict()
        with iDockerfilePath.open() as textFile:
            for line in textFile:
                for labelName in ImageBuildRunner.REQUIRED_LABEL_NAMES:
                    pattern = r'LABEL\s+' + labelName + r'\s*=\s*"([^"]+)"'
                    if f"LABEL" in line:
                        labelMatch = re.search(pattern, line)
                        if labelMatch:
                            labelValue = labelMatch.group(1)
                            labels[labelName] = labelValue

        missingLabelNames = set()
        for labelName in ImageBuildRunner.REQUIRED_LABEL_NAMES:
            if not labelName in labels:
                missingLabelNames.add(labelName)
        if missingLabelNames:
            Utils.error(f"Dockerfile \"${iDockerfilePath}\" does not contain the required label(s): {", ".join(missingLabelNames)}.")
        return labels

    def __init__(self, iDockerfilePath: Path):
        dockerFileAbsolutePath: Path | None = None
        goodPath = Utils.GoodPath(iDockerfilePath.as_posix())
        if goodPath.isAbsolute:
            dockerFileAbsolutePath = Path(goodPath.posixNormalized)
        else:
            dockerFileAbsolutePath = (ImageBuildRunner.projectDockerfilesRoot() / iDockerfilePath).resolve()

        if not dockerFileAbsolutePath.is_relative_to(ImageBuildRunner.projectDockerfilesRoot()):
            Utils.error(
f"Dockerfile path must be under the Dockerfiles' root of the project \"{ImageBuildRunner.projectDockerfilesRoot()}\".\
Input Dockerfile path: \"{iDockerfilePath}\".\
            ")

        self.__dockerFilePath = dockerFileAbsolutePath
        if not self.__dockerFilePath.exists() or not self.__dockerFilePath.is_file():
            Utils.error(f"Invalid file: \"{self.__dockerFilePath}\".")

        dockerFileSubdirStr = str(dockerFileAbsolutePath.parent.relative_to(ImageBuildRunner.projectDockerfilesRoot()).as_posix())
        dockerFileName = str(self.__dockerFilePath.name)
        dockerFileNameSuffix = dockerFileName.removeprefix("Dockerfile.") # E.g. Ubuntu24AMD__build.
        dockerFileNameSuffixSubstrings = dockerFileNameSuffix.split("__")
        getDockerFileNameSuffixSubstring = lambda iIdx: dockerFileNameSuffixSubstrings[iIdx] \
            if len(dockerFileNameSuffixSubstrings) > iIdx and dockerFileNameSuffixSubstrings[iIdx] \
            else Utils.error(f"Dockerfile name must be composed as 'Dockerfile.{{Platform}}__{{EnvType}}', e.g. 'Dockerfile.Ubuntu24AMD__build'. But filename is '{dockerFileName}'.")

        self.__platform: str = getDockerFileNameSuffixSubstring(0)
        self.__envType: str = getDockerFileNameSuffixSubstring(1)

        companyNameShort = MetadataHolder().getMetadataValue(Path("./Project.json"), ["CompanyName_SHORT"])
        projectNameBase = MetadataHolder().getMetadataValue(Path("./Project.json"), ["ProjectNameBase"])
        projectVersion = MetadataHolder().getMetadataValue(Path("./Project.json"), ["ProjectVersion"])
        if not (isinstance(companyNameShort, str) and isinstance(projectNameBase, str) and isinstance(projectVersion, str)):
            Utils.error(f"{__class__.__name__}: can't get required metadata.")

        self.__localImageName = f"{companyNameShort}_{projectNameBase}_{projectVersion}__{"" if dockerFileSubdirStr == "." else (dockerFileSubdirStr + "/")}{dockerFileNameSuffix}".lower()
        self.__imageDescription = f"{self.__platform} image with {self.__envType} environment for {companyNameShort} {projectNameBase} {projectVersion}. Image version is not related to version of {companyNameShort} {projectNameBase}."

        self.__dockerRegistry = MetadataHolder().getMetadataValue(Path("./CI.json"), ["DockerRegistry"])
        dockerRegistrySuffix = MetadataHolder().getMetadataValue(Path("./CI.json"), ["DockerRegistrySuffix"])
        if not (isinstance(self.__dockerRegistry, str) and isinstance(dockerRegistrySuffix, str)):
            Utils.error(f"{__class__.__name__}: can't get required metadata.")

        self.__remoteImageName = f"{self.__dockerRegistry}/{dockerRegistrySuffix}/{self.__localImageName}"

        self.__imageMaintainer = MetadataHolder().getMetadataValue(Path("./CI.json"), ["DockerMaintainer"])
        if not isinstance(self.__imageMaintainer, str):
            Utils.error(f"{__class__.__name__}: can't get required metadata.")

        requiredLabels = ImageBuildRunner.extractRequiredLabels(self.__dockerFilePath)
        self.__imageVersion = requiredLabels.get("version")
        if (self.__imageVersion is None):
            Utils.error(f"'{self.__dockerFilePath}' must contain 'version' label.")

    def dockerfilePath(self) -> Path:
        """
        Absolute path to the Dockerfile.
        """
        return self.__dockerFilePath

    def platform(self) -> str:
        """The base operating system of the image."""
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
        Utils.status(text + "...")

        envFileContent: str = ""
        envFileContent += f"PLATFORM={self.platform()}\n"
        envFileContent += f"ENV_TYPE={self.envType()}\n"
        envFileContent += f"LOCAL_IMAGE_NAME={self.localImageName()}\n"
        envFileContent += f"REMOTE_IMAGE_NAME={self.remoteImageName()}\n"
        envFileContent += f"IMAGE_VERSION={self.imageVersion()}"

        envFilePath = self.dockerfilePath().parent / ".tmp" / (str(self.dockerfilePath().name) + ".env")

        envFilePath.parent.mkdir(parents=True, exist_ok=True)
        with open(envFilePath, "w", encoding="utf-8") as file:
            file.write(envFileContent)

        Utils.message(f"\"{envFilePath}\" has been created.")
        Utils.message(f"File content:\n{Utils.makeIndented(envFileContent, "\t")}")
        Utils.status(text + " finished.\n")

    def build(self):
        text = f"Building docker image"
        Utils.status(text + "...")

        command = [
            "docker", "build",
            "-f", str(self.dockerfilePath()),
            "-t", f"{self.localImageName()}:{self.imageVersion()}",
            "--label", f"name={self.localImageName()}",
            "--label", f"description={self.imageDescription()}",
            "--label", f"maintainer={self.imageMaintainer()}",
            str(self.dockerfilePath().parent)
        ]
        Utils.runCommand(command)

        Utils.status(text + " finished.\n")

    def push(self):
        text = f"Pushing docker image"
        Utils.status(text + "...")

        commandTag = [
            "docker", "tag",
            f"{self.localImageName()}:{self.imageVersion()}",
            f"{self.remoteImageName()}:{self.imageVersion()}"
        ]
        Utils.runCommand(commandTag)

        commandLogin = ["docker", "login", self.dockerRegistry()]
        Utils.runCommand(commandLogin)

        commandPush = [
            "docker", "push",
            f"{self.remoteImageName()}:{self.imageVersion()}"
        ]
        Utils.runCommand(commandPush)

        Utils.status(text + " finished.\n")

    def run(self, iBuildStage: BuildStage, iRunPrecedingStages: RunPrecedingStages):
        isStageRequiredLamda = lambda iBuildStageOfStage, iBuildStage:  \
            iBuildStage == iBuildStageOfStage or \
            iRunPrecedingStages == ImageBuildRunner.RunPrecedingStages.Run and iBuildStage.value > iBuildStageOfStage.value

        if isStageRequiredLamda(ImageBuildRunner.BuildStage.GenerateEnvFile, iBuildStage):
            self.generateEnvFile()

        if isStageRequiredLamda(ImageBuildRunner.BuildStage.Build, iBuildStage):
            checkDocker()
            self.build()

        if isStageRequiredLamda(ImageBuildRunner.BuildStage.Push, iBuildStage):
            checkDocker()
            self.push()