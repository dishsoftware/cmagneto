from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, DependencyPathSpec, bundleExternalSharedLibraries, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry
from pathlib import Path


BuildVariantRegistry().registerBuildVariant(
    BuildVariant(
        name="MinGW",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="MinGW Makefiles",
        multiConfig=False,
        dependencyPaths=(
            DependencyPathSpec("MSYS2_HOME", Path("ucrt64")),
        ),
        externalSharedLibraryPolicies=(
            *expectExternalSharedLibrariesOnTargetMachine(
                "Qt6::Core",
                "Qt6::Gui",
                "Qt6::Widgets"
            ),
            *bundleExternalSharedLibraries(
                "ZLIB::ZLIB"
            )
        ),
    )
)
