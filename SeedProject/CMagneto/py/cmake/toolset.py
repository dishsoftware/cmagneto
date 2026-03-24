# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations
from dataclasses import dataclass, field
from pathlib import Path

from CMagneto.py.cmake.build_platform import BuildPlatform


@dataclass(frozen=True)
class DependencyPathSpec:
    envVarName: str
    cmakePathPostfix: Path | None = None


@dataclass(frozen=True)
class Toolset:
    name: str
    supportedOSes: frozenset[BuildPlatform.OS]
    generatorName: str
    multiConfig: bool
    cppCompilerName: str | None = None
    dependencyPaths: tuple[DependencyPathSpec, ...] = field(default_factory=tuple)
    extraGenerateArgs: tuple[str, ...] = field(default_factory=tuple)
    envSetupScript: str | None = None
    envSetupArgs: tuple[str, ...] = field(default_factory=tuple)
