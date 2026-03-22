from pathlib import Path

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from CMagneto.py.cmake.toolset import DependencyPathSpec, Toolset


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
