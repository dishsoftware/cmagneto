from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, bundleExternalSharedLibraries, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry


BuildVariantRegistry().registerBuildVariant(
    BuildVariant(
        name="UnixMakefiles_GCC",
        supportedOSes=frozenset({BuildPlatform.OS.Linux}),
        generatorName="Unix Makefiles",
        multiConfig=False,
        cppCompilerName="g++",
        externalSharedLibraryPolicies=(
            *expectExternalSharedLibrariesOnTargetMachine(
                "Qt6::Core",
                "Qt6::Gui",
                "Qt6::Widgets"
            ),
            *bundleExternalSharedLibraries(
                "ZLIB::ZLIB"
            )
        )
    )
)
