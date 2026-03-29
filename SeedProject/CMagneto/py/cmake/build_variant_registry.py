# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

import importlib
from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant
from typing import Callable


class BuildVariantRegistry():
    __sInstance = None

    def __new__(cls):
        if cls.__sInstance is None:
            cls.__sInstance = super().__new__(cls)
            cls.__sInstance.__initialized = False
        return cls.__sInstance

    def __init__(self):
        if self.__initialized:
            return
        # { buildVariantName, buildVariant }[]
        self.__registeredBuildVariants: dict[str, BuildVariant] = dict()
        importlib.import_module("build_variants")
        self.__initialized = True

    def registerBuildVariant(self, iBuildVariant: BuildVariant) -> None:
        """Call the function after definition of every concrete BuildVariant."""
        registeredBuildVariant = self.__registeredBuildVariants.get(iBuildVariant.name)
        if registeredBuildVariant is not None:
            if registeredBuildVariant == iBuildVariant:
                return
            else:
                raise KeyError(f"Another BuildVariant with the name \"{iBuildVariant.name}\" is already registered.")
        self.__registeredBuildVariants[iBuildVariant.name] = iBuildVariant

    def registeredBuildVariants(self) -> dict[str, BuildVariant]:
        return self.__registeredBuildVariants

    def supportedOSes(self) -> set[BuildPlatform.OS]:
        """Returns supported OSes of all registered build variants."""
        oses: set[BuildPlatform.OS] = set()
        for buildVariant in self.__registeredBuildVariants.values():
            oses.update(buildVariant.supportedOSes)
        return oses

    def availableBuildVariants(self) -> dict[str, BuildVariant]:
        """Returns { buildVariantName, buildVariant }[], with build variants, which support the OS the script is run on."""
        predicate: Callable[[BuildVariant], bool] = lambda iBuildVariant: BuildPlatform().hostOS() in iBuildVariant.supportedOSes
        availableBuildVariants: dict[str, BuildVariant] = {k: v for k, v in self.__registeredBuildVariants.items() if predicate(v)}
        return availableBuildVariants
