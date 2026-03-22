from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from CMagneto.py.cmake.toolset import Toolset


BuildRunnersHolder().registerToolset(
    Toolset(
        name="MinGW",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="MinGW Makefiles",
        multiConfig=False
    )
)
