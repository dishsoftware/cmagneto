# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.multi_config_build_runner import MultiConfigBuildRunner
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from pathlib import Path


class VS2022MSVCRunner(MultiConfigBuildRunner):
    @staticmethod
    def toolsetName() -> str:
        return "VS2022_MSVC"

    @staticmethod
    def supportedOSes() -> set[BuildPlatform.OS]:
        return { BuildPlatform.OS.Windows }

    @staticmethod
    def create(iBuildTypes: set[BuildRunner.BuildType]) -> BuildRunner:
        return VS2022MSVCRunner(iBuildTypes)

    def __init__(self, iBuildTypes: set[BuildRunner.BuildType]):
        super().__init__("Visual Studio 17 2022", None, iBuildTypes)

    def _setDependencyPaths(self) -> None:
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("QT6_MSVC2022_DIR", Path("lib/cmake"))
        BuildRunner._ADD_VAR_PATH_TO_CMAKE_PREFIX_PATH("BOOST_MSVC2022_DIR", Path("cmake"))

    def _extraArgsFor__generate__command(self) -> list[str]:
        return [
            "-A", "x64"
        ]


BuildRunnersHolder().registerBuildRunner(VS2022MSVCRunner)