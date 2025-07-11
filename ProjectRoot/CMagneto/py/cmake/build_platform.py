# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from enum import Enum
import platform


class BuildPlatform:


    class OS(Enum):
        Linux = "LinuxAMD"
        Windows = "WindowsAMD"


    __sInstance = None

    def __new__(cls):
        if cls.__sInstance is None:
            cls.__sInstance = super().__new__(cls)
            cls.__sInstance.__initialized = False
        return cls.__sInstance

    def __init__(self):
        if self.__initialized:
            return
        self.__HOST_OS = BuildPlatform.OS[platform.system()]
        self.__initialized = True

    def hostOS(self) -> OS:
        """
        The host OS, on the which the script is run on.
        """
        return self.__HOST_OS