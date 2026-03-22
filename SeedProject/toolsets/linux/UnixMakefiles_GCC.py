from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_runners_holder import BuildRunnersHolder
from CMagneto.py.cmake.toolset import Toolset


BuildRunnersHolder().registerToolset(
    Toolset(
        name="UnixMakefiles_GCC",
        supportedOSes=frozenset({BuildPlatform.OS.Linux}),
        generatorName="Unix Makefiles",
        multiConfig=False,
        cppCompilerName="g++"
    )
)
