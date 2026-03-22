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
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from CMagneto.py.cmake.toolset import DependencyPathSpec, Toolset
from pathlib import Path


BuildRunnersHolder().registerToolset(
    Toolset(
        name="VS2022_MSVC",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="Visual Studio 17 2022",
        multiConfig=True,
        dependencyPaths=(
            DependencyPathSpec("QT6_MSVC2022_DIR", Path("lib/cmake")),
            DependencyPathSpec("BOOST_MSVC2022_DIR", Path("cmake"))
        ),
        extraGenerateArgs=("-A", "x64")
    )
)
