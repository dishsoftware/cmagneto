# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.single_config_build_runner import SingleConfigBuildRunner


class UnixMakefilesGCCRunner(SingleConfigBuildRunner):
    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("UnixMakefiles_GCC", "Unix Makefiles", "g++", iBuildTypes)

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return UnixMakefilesGCCRunner(iBuildTypes)