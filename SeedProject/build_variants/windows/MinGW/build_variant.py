from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry


BuildVariantRegistry().registerBuildVariant(
    BuildVariant(
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
