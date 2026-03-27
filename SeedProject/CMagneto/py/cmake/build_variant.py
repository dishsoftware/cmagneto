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
from enum import Enum
from pathlib import Path

from CMagneto.py.cmake.build_platform import BuildPlatform


@dataclass(frozen=True)
class DependencyPathSpec:
    envVarName: str
    cmakePathPostfix: Path | None = None


class ExternalSharedLibraryInstallMode(Enum):
    EXPECT_ON_TARGET_MACHINE = "EXPECT_ON_TARGET_MACHINE"
    BUNDLE_WITH_PACKAGE = "BUNDLE_WITH_PACKAGE"


@dataclass(frozen=True)
class ExternalSharedLibraryPolicy:
    importedTargetName: str
    installMode: ExternalSharedLibraryInstallMode


def expectExternalSharedLibrariesOnTargetMachine(*iImportedTargetNames: str) -> tuple[ExternalSharedLibraryPolicy, ...]:
    return tuple(
        ExternalSharedLibraryPolicy(importedTargetName, ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE)
        for importedTargetName in iImportedTargetNames
    )


def bundleExternalSharedLibraries(*iImportedTargetNames: str) -> tuple[ExternalSharedLibraryPolicy, ...]:
    return tuple(
        ExternalSharedLibraryPolicy(importedTargetName, ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE)
        for importedTargetName in iImportedTargetNames
    )


def bundleRuntimeDependencyFiles(*iPaths: str) -> tuple[str, ...]:
    return tuple(iPaths)


def bundleRuntimeDependencyFilePatterns(*iPatterns: str) -> tuple[str, ...]:
    return tuple(iPatterns)


def excludeBundledRuntimeDependencyFiles(*iPaths: str) -> tuple[str, ...]:
    return tuple(iPaths)


def excludeBundledRuntimeDependencyFilePatterns(*iPatterns: str) -> tuple[str, ...]:
    return tuple(iPatterns)


@dataclass(frozen=True)
class BuildVariant:
    name: str
    supportedOSes: frozenset[BuildPlatform.OS]
    generatorName: str
    multiConfig: bool
    cppCompilerName: str | None = None
    dependencyPaths: tuple[DependencyPathSpec, ...] = field(default_factory=tuple)
    externalSharedLibraryPolicies: tuple[ExternalSharedLibraryPolicy, ...] = field(default_factory=tuple)
    bundledRuntimeDependencyFiles: tuple[str, ...] = field(default_factory=tuple)
    bundledRuntimeDependencyFilePatterns: tuple[str, ...] = field(default_factory=tuple)
    excludedBundledRuntimeDependencyFiles: tuple[str, ...] = field(default_factory=tuple)
    excludedBundledRuntimeDependencyFilePatterns: tuple[str, ...] = field(default_factory=tuple)
    extraGenerateArgs: tuple[str, ...] = field(default_factory=tuple)
    envSetupScript: str | None = None
    envSetupArgs: tuple[str, ...] = field(default_factory=tuple)
