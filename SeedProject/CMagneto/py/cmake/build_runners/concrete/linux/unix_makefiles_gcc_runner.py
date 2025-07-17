# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.single_config_build_runner import SingleConfigBuildRunner
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder


class UnixMakefilesGCCRunner(SingleConfigBuildRunner):
    @staticmethod
    def toolsetName() -> str:
        return "UnixMakefiles_GCC"

    @staticmethod
    def supportedOSes() -> set[BuildPlatform.OS]:
        """Returns OS set, the BuildRunner subclass supports."""
        return { BuildPlatform.OS.Linux }

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return UnixMakefilesGCCRunner(iBuildTypes)

    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("Unix Makefiles", "g++", iBuildTypes)


BuildRunnersHolder().registerBuildRunner(UnixMakefilesGCCRunner)