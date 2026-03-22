from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.toolset import Toolset
from CMagneto.py.cmake.toolset_registry import ToolsetRegistry


ToolsetRegistry().registerToolset(
    Toolset(
        name="UnixMakefiles_GCC",
        supportedOSes=frozenset({BuildPlatform.OS.Linux}),
        generatorName="Unix Makefiles",
        multiConfig=False,
        cppCompilerName="g++"
    )
)
