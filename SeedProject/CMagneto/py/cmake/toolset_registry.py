# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.toolset import Toolset
from typing import Callable


class ToolsetRegistry():
    __sInstance = None

    def __new__(cls):
        if cls.__sInstance is None:
            cls.__sInstance = super().__new__(cls)
            cls.__sInstance.__initialized = False
        return cls.__sInstance

    def __init__(self):
        if self.__initialized:
            return
        # { toolsetName, toolset }[]
        self.__registeredToolsets: dict[str, Toolset] = dict()
        self.__initialized = True

    def registerToolset(self, iToolset: Toolset) -> None:
        """Call the function after definition of every concrete Toolset."""
        registeredToolset = self.__registeredToolsets.get(iToolset.name)
        if registeredToolset is not None:
            if registeredToolset == iToolset:
                return
            else:
                raise KeyError(f"Another Toolset with the name \"{iToolset.name}\" is already registered.")
        self.__registeredToolsets[iToolset.name] = iToolset

    def registeredToolsets(self) -> dict[str, Toolset]:
        return self.__registeredToolsets

    def supportedOSes(self) -> set[BuildPlatform.OS]:
        """Returns supported OSes of all registered toolsets."""
        oses: set[BuildPlatform.OS] = set()
        for toolset in self.__registeredToolsets.values():
            oses.update(toolset.supportedOSes)
        return oses

    def availableToolsets(self) -> dict[str, Toolset]:
        """Returns { toolsetName, toolset }[], with toolsets, which support the OS the script is run on."""
        predicate: Callable[[Toolset], bool] = lambda iToolset: BuildPlatform().hostOS() in iToolset.supportedOSes
        availableToolsets: dict[str, Toolset] = {k: v for k, v in self.__registeredToolsets.items() if predicate(v)}
        return availableToolsets


# Import project toolsets. The import is required.
import toolsets
