# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from CMagneto.py.cmake.build_runner import BuildRunner
from CMagneto.py.cmake.build_runners.linux.unix_makefiles_gcc_runner import UnixMakefilesGCCRunner
from CMagneto.py.cmake.build_runners.windows.mingw_makefiles_mingw_runner import MinGWMakefilesMinGWRunner
from CMagneto.py.cmake.build_runners.windows.vs2022_msvc_runner import VS2022MSVCRunner
from CMagneto.py.utils import *
from enum import Enum
import platform


class BuildRunnersHolder(metaclass=ConstMetaClass):
    __OS_NAME = platform.system()


    class LinuxToolset(Enum):
        UnixMakefiles_GCC = 0

    LINUX_BUILD_RUNNERS: dict[LinuxToolset, type[BuildRunner]] = {
        LinuxToolset.UnixMakefiles_GCC: UnixMakefilesGCCRunner
    }


    class WindowsToolset(Enum):
        MinGW = 0 # MinGW Makefiles and MinGW compiler.
        # The MinGW name does not follow the accepted naming convention {BuildSystem}_{Compiler}, because for this case the conventional name is too long.
        VS2022_MSVC = 1 # Visual Studio 2022 with MSVC compiler.

    WINDOWS_BUILD_RUNNERS: dict[WindowsToolset, type[BuildRunner]] = {
        WindowsToolset.MinGW: MinGWMakefilesMinGWRunner,
        WindowsToolset.VS2022_MSVC: VS2022MSVCRunner
    }


    @staticmethod
    def AVAILABLE_TOOLSETS() -> type[Enum]:
        """
        Returns platfom-dependent list of toolset names. A toolset is a pair [build system; compiler].
        """
        if BuildRunnersHolder.__OS_NAME == "Linux":
            return BuildRunnersHolder.LinuxToolset
        elif BuildRunnersHolder.__OS_NAME == "Windows":
            return BuildRunnersHolder.WindowsToolset
        else: # E.g. "Darwin":
            error(f"OS \"{BuildRunnersHolder.__OS_NAME}\" is not supported.")

    @staticmethod
    def AVAILABLE_BUILD_RUNNNERS() -> dict[Enum, type[BuildRunner]]:
        """
        Returns platfom-dependent map [toolset name; BuildRunner class]
        """
        if BuildRunnersHolder.__OS_NAME == "Linux":
            return BuildRunnersHolder.LINUX_BUILD_RUNNERS  # type: ignore
        elif BuildRunnersHolder.__OS_NAME == "Windows":
            return BuildRunnersHolder.WINDOWS_BUILD_RUNNERS  # type: ignore
        else: # E.g. "Darwin":
            error(f"OS \"{BuildRunnersHolder.__OS_NAME}\" is not supported.")