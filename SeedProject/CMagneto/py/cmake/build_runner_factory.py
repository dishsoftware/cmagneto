# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
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
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry


class BuildRunnerFactory:
    @staticmethod
    def createBuildRunner(
        iBuildVariantName: str,
        iBuildTypes: set[BuildRunner.BuildType],
        iEnableCodeCoverage: bool = False
    ) -> BuildRunner:
        buildVariant = BuildVariantRegistry().availableBuildVariants()[iBuildVariantName]
        if buildVariant.multiConfig:
            return MultiConfigBuildRunner(buildVariant, iBuildTypes, iEnableCodeCoverage)
        else:
            return SingleConfigBuildRunner(buildVariant, iBuildTypes, iEnableCodeCoverage)
