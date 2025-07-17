# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from CMagneto.py.utils import Utils
from enum import Enum
from pathlib import Path
import inspect
import platform


class BuildPlatform:


    class OS(Enum):
        Linux = "Linux"
        Windows = "Windows"


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

    def runScript(self, iScriptPath: Path, iArgs: list[str] | None = None) -> None:
        hostOS = self.hostOS().value
        dotExt = iScriptPath.suffix
        command: list[str] | None = None
        if hostOS == "Windows":
            if dotExt == ".bat":
                command = [str(iScriptPath)]
        else: # Linux, MacOS
            if dotExt == ".sh":
                command = [str(iScriptPath)]

        if command is None:
            currentFrame = inspect.currentframe()
            Utils.error(f"Method '{currentFrame.f_code.co_name if currentFrame else 'runScript'}' does not support scripts with extension '{dotExt}' on OS '{hostOS}'. '{iScriptPath}' has not been run.")
        else:
            if iArgs is not None:
                command.extend(iArgs)
            Utils.runCommand(command)