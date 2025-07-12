# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
build_image.py

One-command Docker image build script.

For usage details and available options, run:
```
    python ./build_image.py --help
```
The script can be run from any working directory.
The location relative to the project root must be preserved.
"""

from pathlib import Path
import argparse
import sys

# Add project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`,
# even if the script is run not from its parent dir.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
import sys
sys.path.append(str(PROJECT_ROOT))

from CMagneto.py.docker.image_build_runner import ImageBuildRunner


def buildImage():
    parser = argparse.ArgumentParser(
        description=\
f"Builds Docker images.\n\
The build pipeline consists of the following stages: {', '.join([buildStage.name for buildStage in ImageBuildRunner.BuildStage])}.\n\
\n\
NOTE! All relative paths in the doc are given relative to the project root.\n\
\n\
Image name is generated as {{CompanyName_SHORT}}_{{ProjectNameBase}}_{{ProjectVersion}}__{{DockerFileSubdir}}{{DockerFileNameSuffix}},\n\
where:\n\
    CompanyName_SHORT, ProjectNameBase and ProjectVersion are variables from './meta/Project.json'.\n\
    DockerFileSubdir is a path of the Dockerfile directory, relative to the Dockerfiles' root of the project `./CI/Docker/`.\n\
        In the DockerFileSubdir string:\n\
            Separator is \"/\";\n\
            The leading \"./\" is omitted;\n\
            If DockerFileSubdir == \".\", the DockerFileSubdir is replaced with the empty string.\n\
    DockerFileNameSuffix is a substring of a used Dockerfile name: 'Dockerfile.DockerFileNameSuffix'.\n\
    DockerFileNameSuffix must be composed as {{Platform}}__{{EnvType}}, e.g. 'Ubuntu24AMD__build'.\n\
\n\
{ImageBuildRunner.__name__} requires Dockerfiles to define the following labels: {', '.join(ImageBuildRunner.REQUIRED_LABEL_NAMES)}.\n\
Values of these labels must be defined in a single line: 'LABEL labelName=\"labelValue\"'.\n\
\n\
Pushes images to {{DockerRegistry}}/{{DockerRegistrySuffix}}/, where DockerRegistry and DockerRegistrySuffix are variables from './meta/CI.json'.\n\
An example:\n\
    CompanyName_SHORT = Dish\n\
    ProjectNameBase = ContactHolder\n\
    ProjectVersion = 1.0.0\n\
    DockerRegistry = registry.gitlab.com\n\
    DockerRegistrySuffix = dishsoftware/contactholder\n\
    \n\
    1) DockerfilePath = ./Dockerfile.Ubuntu24AMD__build\n\
       Pushed image name: registry.gitlab.com/dishsoftware/contactholder/dish_contactholder_1.0.0__ubuntu24amd__build.\n\
    2) DockerfilePath = ./Test/Coverage/Dockerfile.Ubuntu24AMD__build\n\
       Pushed image name: registry.gitlab.com/dishsoftware/contactholder/dish_contactholder_1.0.0__test/coverage/ubuntu24amd__build.\n\
\n\
Uses other variables from JSON files in './meta/' to define image labels.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--file", "-f",
        type=Path,
        required=True,
        help="Path to a Dockerfile."
    )
    defaultBuildStage = max(ImageBuildRunner.BuildStage, key=lambda e: e.value) # The last stage is the default.
    parser.add_argument(
        "--build_stage",
        type=str,
        choices=[buildStage.name for buildStage in ImageBuildRunner.BuildStage],
        default=defaultBuildStage.name,
        help=f"Specify build stage to run. Default is {defaultBuildStage.name}."
    )
    defaultRPS = ImageBuildRunner.RunPrecedingStages.Run
    parser.add_argument(
        "--run_preceding_stages", "--RPS",
        type=str,
        choices=[rps.name for rps in ImageBuildRunner.RunPrecedingStages],
        default=defaultRPS.name,
        help=f"Specify whether to run preceding build stages. Default is {defaultRPS.name}."
    )

    args = parser.parse_args()

    dockerFilePath = Path(args.file)
    buildStage = ImageBuildRunner.BuildStage[args.build_stage]
    runPrecedingStages = ImageBuildRunner.RunPrecedingStages[args.run_preceding_stages]

    buildRunner = ImageBuildRunner(dockerFilePath)
    buildRunner.run(buildStage, runPrecedingStages)


if __name__ == "__main__":
    buildImage()