from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.toolset import Toolset
from CMagneto.py.cmake.toolset_registry import ToolsetRegistry


ToolsetRegistry().registerToolset(
    Toolset(
        name="MinGW",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="MinGW Makefiles",
        multiConfig=False
    )
)