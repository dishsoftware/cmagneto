#!/usr/bin/env python3

# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from build_image import DockerImageBuildRunner, mainFor__build_concrete_image


IMAGE_PROPS = DockerImageBuildRunner.ImageProps(
    dockerfilePathRel="./Dockerfile.unit_and_integration_tests",
    dockerFileContextDirRel=".",
    name="unit_and_integration_tests",
    version="1.0.0",
    description="For running unit and integration tests of the CMagneto code itself. Not of seed or test projects.",
    registry="registry.gitlab.com",
    registrySuffix="dishsoftware/cmagneto",
    maintainer="Dim Shvydkoy <dmit.shvyd@gmail.com>"
)

if __name__ == "__main__":
    mainFor__build_concrete_image(IMAGE_PROPS)