# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.multi_config_build_runner import MultiConfigBuildRunner
from CMagneto.py.cmake.build_runners.single_config_build_runner import SingleConfigBuildRunner
from CMagneto.py.cmake.toolset_registry import ToolsetRegistry


class BuildRunnerFactory:
    @staticmethod
    def createBuildRunner(
        iToolsetName: str,
        iBuildTypes: set[BuildRunner.BuildType],
        iEnableCodeCoverage: bool = False
    ) -> BuildRunner:
        toolset = ToolsetRegistry().availableToolsets()[iToolsetName]
        if toolset.multiConfig:
            return MultiConfigBuildRunner(toolset, iBuildTypes, iEnableCodeCoverage)
        else:
            return SingleConfigBuildRunner(toolset, iBuildTypes, iEnableCodeCoverage)
