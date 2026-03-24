#!/usr/bin/env python3

# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from dataclasses import dataclass
from pathlib import Path
from typing import cast
import argparse
import subprocess


class DockerImageBuildRunner:
    @dataclass(frozen=True)
    class ImageProps:
        dockerfilePathRel: str        # Must be relative and under this dir.
        dockerFileContextDirRel: str  # Must be relative and under this dir.
        name: str
        version: str
        description: str
        registry: str        # E.g. 'registry.gitlab.com'.
        registrySuffix: str  # E.g. 'dishsoftware/cmagneto'.
        maintainer: str

        def __post_init__(self):
            dockerfilePathAbs = DockerImageBuildRunner.checkRelPathAndGetAbsPath(self.dockerfilePathRel)
            dockerFileContextDirAbs = DockerImageBuildRunner.checkRelPathAndGetAbsPath(self.dockerFileContextDirRel)
            object.__setattr__(self, "__dockerfilePathAbs", dockerfilePathAbs)
            object.__setattr__(self, "__dockerFileContextDirAbs", dockerFileContextDirAbs)

        @property
        def tag(self) -> str:
            return f"{self.name}:{self.version}"

        @property
        def remoteName(self) -> str:
            return f"{self.registry}/{self.registrySuffix}/{self.name}"

        @property
        def remoteTag(self) -> str:
            return f"{self.remoteName}:{self.version}"

        @property
        def dockerfilePathAbs(self) -> str:
            return getattr(self, "__dockerfilePathAbs")

        @property
        def dockerFileContextDirAbs(self) -> str:
            return getattr(self, "__dockerFileContextDirAbs")

        def describe(self) -> str:
            res = "ImageProps:"
            res += f"\n\tDockerfile path    '{self.dockerfilePathRel}' ('{self.dockerfilePathAbs}');"
            res += f"\n\tDockerfile context '{self.dockerFileContextDirRel}' ('{self.dockerFileContextDirAbs}');"
            res += f"\n\tName '{self.name}';"
            res += f"\n\tVersion '{self.version}';"
            res += f"\n\tDescription '{self.description}';"
            res += f"\n\tTag '{self.tag}';"
            res += f"\n\tRemote tag '{self.remoteTag}';"
            res += "\n"
            return res


    @staticmethod
    def checkDocker():
        try:
            subprocess.run(["docker", "info"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            print("❌ Docker is installed but the daemon is not running. Start Docker Desktop or Docker service.")
            exit(1)
        except FileNotFoundError:
            print("❌ Docker is not installed or not in PATH.")
            exit(1)

    THIS_DIR = Path(__file__).parent

    @staticmethod
    def checkRelPathAndGetAbsPath(iPath: str) -> str:
        if not iPath:
            raise ValueError(f"Path must not be empty.")
        dockerFilePath = Path(iPath)
        if dockerFilePath.is_absolute():
            raise ValueError(f"Path must be relative. Got '{iPath}'.")
        # Resolve the full absolute path.
        dockerFilePath = (DockerImageBuildRunner.THIS_DIR / dockerFilePath).resolve()
        if not dockerFilePath.is_relative_to(DockerImageBuildRunner.THIS_DIR):
            raise ValueError(f"Path must be under '{DockerImageBuildRunner.THIS_DIR}'. Got '{iPath}'.")
        return dockerFilePath.as_posix()

    def __init__(self, iImageProps: ImageProps):
        DockerImageBuildRunner.checkRelPathAndGetAbsPath(iImageProps.dockerfilePathRel)
        DockerImageBuildRunner.checkRelPathAndGetAbsPath(iImageProps.dockerFileContextDirRel)
        if \
            not iImageProps.name or \
            not iImageProps.version or \
            not iImageProps.registry or \
            not iImageProps.registrySuffix:
            raise ValueError("Required property is empty.")
        self.__imageProps = iImageProps

    @property
    def imageProps(self) -> ImageProps:
        return self.__imageProps

    def build(self):
        DockerImageBuildRunner.checkDocker()
        command = [
            "docker", "build",
            "-f", self.__imageProps.dockerfilePathAbs,
            "-t", f"{self.__imageProps.tag}",
            "--label", f"name={self.__imageProps.name}",
            "--label", f"description={self.__imageProps.description}",
            "--label", f"maintainer={self.__imageProps.maintainer}",
            self.__imageProps.dockerFileContextDirAbs
        ]
        subprocess.run(command, check=True)

    def push(self):
        DockerImageBuildRunner.checkDocker()
        commandTag = [
            "docker", "tag",
            f"{self.__imageProps.tag}",
            f"{self.__imageProps.remoteTag}"
        ]
        subprocess.run(commandTag, check=True)

        commandLogin = ["docker", "login", self.__imageProps.registry]
        subprocess.run(commandLogin, check=True)

        commandPush = [
            "docker", "push",
            f"{self.__imageProps.remoteTag}"
        ]
        subprocess.run(commandPush, check=True)

    def run(self, iPush: bool) -> None:
        self.build()
        if iPush:
            self.push()

    @staticmethod
    def createAndRun(iImageProps: ImageProps, iPush: bool) -> None:
        print(iImageProps.describe())
        DockerImageBuildRunner(iImageProps).run(iPush)


def mainFor__build_concrete_image(iImageProps: DockerImageBuildRunner.ImageProps):
    parser = argparse.ArgumentParser(
        description=(
            f"Build an image {iImageProps.tag} using '{iImageProps.dockerfilePathRel}' "
            f"and (optionally) push as '{iImageProps.remoteTag}'."
        ),
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--push",
        action="store_true",
        help=f"After building, push the image as '{iImageProps.remoteTag}'."
    )

    args, _ = parser.parse_known_args()
    DockerImageBuildRunner.createAndRun(iImageProps, args.push)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=f"Build a Docker image and (optionally) push to a Docker image registry.",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--file",
        type=Path,
        required=True,
        help=f"Path to a Dockerfile. The path must be relative and under '{DockerImageBuildRunner.THIS_DIR}'."
    )

    parser.add_argument(
        "--file_context",
        type=Path,
        required=True,
        help=f"Path to a Dockerfile context dir. The path must be relative and under '{DockerImageBuildRunner.THIS_DIR}'."
    )

    parser.add_argument(
        "--name",
        type=str,
        required=True,
        help="Name of a Docker image."
    )

    parser.add_argument(
        "--version",
        type=str,
        required=True,
        help="Version of a Docker image."
    )

    parser.add_argument(
        "--description",
        type=str,
        required=True,
        help="Description of a Docker image."
    )

    parser.add_argument(
        "--registry",
        type=str,
        required=True,
        help="Registry where to push an image. E.g. 'registry.gitlab.com'."
    )

    parser.add_argument(
        "--registry_suffix",
        type=str,
        required=True,
        help="Registry suffix where to push an image. E.g. 'dishsoftware/cmagneto'."
    )

    parser.add_argument(
        "--maintainer",
        type=str,
        required=True,
        help="Maintainer of a Docker image."
    )

    parser.add_argument(
        "--push",
        action="store_true",
        help=f"After building, push the image to the Docker image registry."
    )

    args, _ = parser.parse_known_args()

    imageProps = DockerImageBuildRunner.ImageProps(
        dockerfilePathRel=cast(Path, args.file).as_posix(),
        dockerFileContextDirRel=cast(Path, args.file_context).as_posix(),
        name=args.name,
        version=args.version,
        description=args.description,
        registry=args.registry,
        registrySuffix=args.registry_suffix,
        maintainer=args.maintainer
    )

    DockerImageBuildRunner(imageProps).run(args.push)
