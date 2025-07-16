# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from check_docker import checkDocker
from pathlib import Path
import argparse
import subprocess


DOCKERFILE_CONTEXT_DIR  = str(Path(__file__).parent)
DOCKERFILE_PATH = str(Path(__file__).parent / "Dockerfile.for_repo_shenanigans")
DOCKERIMAGE_NAME = "for_repo_shenanigans"
DOCKERIMAGE_VER  = "1.0.0"
DOCKERIMAGE_TAG  = f"{DOCKERIMAGE_NAME}:{DOCKERIMAGE_VER}"
DOCKERIMAGE_DESCRIPTION = "Provides tools to authenticate and work with Git repos."
DOCKERIMAGE_REGISTRY = "registry.gitlab.com"
DOCKERIMAGE_REGISTRY_SUFFIX = "dishsoftware/cmagneto"
DOCKERIMAGE_REMOTE_NAME = f"{DOCKERIMAGE_REGISTRY}/{DOCKERIMAGE_REGISTRY_SUFFIX}/{DOCKERIMAGE_NAME}"
DOCKERIMAGE_REMOTE_TAG  = f"{DOCKERIMAGE_REMOTE_NAME}:{DOCKERIMAGE_VER}"
DOCKERIMAGE_MAINTAINER = "Dim Shvydkoy <dmit.shvyd@gmail.com>"

def buildImage__for_repo_shenanigans(iPush: bool = False):
    def build():
        command = [
            "docker", "build",
            "-f", DOCKERFILE_PATH,
            "-t", f"{DOCKERIMAGE_TAG}",
            "--label", f"name={DOCKERIMAGE_NAME}",
            "--label", f"description={DOCKERIMAGE_DESCRIPTION}",
            "--label", f"maintainer={DOCKERIMAGE_MAINTAINER}",
            DOCKERFILE_CONTEXT_DIR
        ]
        subprocess.run(command, check=True)

    def push():
        commandTag = [
            "docker", "tag",
            f"{DOCKERIMAGE_TAG}",
            f"{DOCKERIMAGE_REMOTE_TAG}"
        ]
        subprocess.run(commandTag, check=True)

        commandLogin = ["docker", "login", DOCKERIMAGE_REGISTRY]
        subprocess.run(commandLogin, check=True)

        commandPush = [
            "docker", "push",
            f"{DOCKERIMAGE_REMOTE_TAG}"
        ]
        subprocess.run(commandPush, check=True)

    checkDocker()
    build()
    if iPush:
        push()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=f"Build '{DOCKERIMAGE_TAG}' image using '{DOCKERFILE_PATH}' and (optionally) push as '{DOCKERIMAGE_REMOTE_TAG}'.",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--push",
        action="store_true",
        help=f"After building, push the image as '{DOCKERIMAGE_REMOTE_TAG}'."
    )

    args, unknownArgs = parser.parse_known_args()
    buildImage__for_repo_shenanigans(args.push)