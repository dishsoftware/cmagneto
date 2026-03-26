from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.toolset import Toolset, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.toolset_registry import ToolsetRegistry


ToolsetRegistry().registerToolset(
    Toolset(
        name="MinGW",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="MinGW Makefiles",
        multiConfig=False,
        externalSharedLibraryPolicies=expectExternalSharedLibrariesOnTargetMachine(
            "Qt6::Core",
            "Qt6::Gui",
            "Qt6::Widgets"
        )
    )
)
