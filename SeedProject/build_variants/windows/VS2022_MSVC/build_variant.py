from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, DependencyPathSpec, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry
from pathlib import Path


BuildVariantRegistry().registerBuildVariant(
    BuildVariant(
        name="VS2022_MSVC",
        supportedOSes=frozenset({BuildPlatform.OS.Windows}),
        generatorName="Visual Studio 17 2022",
        multiConfig=True,
        dependencyPaths=(
            DependencyPathSpec("QT6_MSVC2022_DIR", Path("lib/cmake")),
            DependencyPathSpec("BOOST_MSVC2022_DIR", Path("cmake"))
        ),
        externalSharedLibraryPolicies=expectExternalSharedLibrariesOnTargetMachine(
            "Qt6::Core",
            "Qt6::Gui",
            "Qt6::Widgets"
        ),
        extraGenerateArgs=("-A", "x64")
    )
)
