# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runner import BuildRunner
from typing import Callable


class BuildRunnersHolder():
    __sInstance = None

    def __new__(cls):
        if cls.__sInstance is None:
            cls.__sInstance = super().__new__(cls)
            cls.__sInstance.__initialized = False
        return cls.__sInstance

    def __init__(self):
        if self.__initialized:
            return
        # { buildRunnerToolsetName, buildRunnerClass }[]
        self.__registeredBuildRunners: dict[str, type[BuildRunner]] = dict()
        self.__initialized = True

    def registerBuildRunner(self, iBuildRunnerClass: type[BuildRunner]) -> None:
        """Call the function after definition of every concrete BuildRunner subclass."""
        registeredBuildRunner = self.__registeredBuildRunners.get(iBuildRunnerClass.toolsetName())
        if registeredBuildRunner is not None:
            if registeredBuildRunner == iBuildRunnerClass:
                return
            else:
                raise KeyError(f"Another BuildRunner subclass with the toolset name \"{iBuildRunnerClass.toolsetName()}\" is already registered.")
        self.__registeredBuildRunners[iBuildRunnerClass.toolsetName()] = iBuildRunnerClass

    def registeredBuildRunners(self) -> dict[str, type[BuildRunner]]:
        return self.__registeredBuildRunners

    def supportedOSes(self) -> set[BuildPlatform.OS]:
        """Returns supported OSes of all registered concrete BuildRunner subclasses."""
        oses: set[BuildPlatform.OS] = set()
        for runner in self.__registeredBuildRunners.values():
            oses.update(runner.supportedOSes())
        return oses

    def availableBuildRunners(self) -> dict[str, type[BuildRunner]]:
        """Returns { buildRunnerToolsetName, buildRunnerClass }[], with BuildRunner subclasses, which support the OS the script is run on."""
        predicate: Callable[[type[BuildRunner]], bool] = lambda iBuildRunnerClass: BuildPlatform().hostOS() in iBuildRunnerClass.supportedOSes()
        availableRunners: dict[str, type[BuildRunner]] = {k: v for k, v in self.__registeredBuildRunners.items() if predicate(v)}
        return availableRunners


# Import all concrete BuildRunners. The import is requried.
from CMagneto.py.cmake.build_runners import concrete