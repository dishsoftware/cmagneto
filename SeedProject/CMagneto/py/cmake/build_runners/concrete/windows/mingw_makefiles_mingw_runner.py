# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations
from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.single_config_build_runner import SingleConfigBuildRunner
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder


class MinGWMakefilesMinGWRunner(SingleConfigBuildRunner):
    @staticmethod
    def toolsetName() -> str:
        return "MinGW"

    @staticmethod
    def supportedOSes() -> set[BuildPlatform.OS]:
        return { BuildPlatform.OS.Windows }

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return MinGWMakefilesMinGWRunner(iBuildTypes)

    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("MinGW Makefiles", None, iBuildTypes)


BuildRunnersHolder().registerBuildRunner(MinGWMakefilesMinGWRunner)