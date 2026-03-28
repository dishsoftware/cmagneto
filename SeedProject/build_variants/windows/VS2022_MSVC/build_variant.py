from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, DependencyPathSpec, bundleExternalSharedLibraries
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
            DependencyPathSpec("BOOST_MSVC2022_DIR", Path("cmake")),
            DependencyPathSpec("ZLIB_MSVC2022_DIR", Path("lib/cmake/zlib"))
        ),
        externalSharedLibraryPolicies=bundleExternalSharedLibraries(
            "Qt6::Core",
            "Qt6::Gui",
            "Qt6::Widgets",
            "ZLIB::ZLIB"
        ),
        extraGenerateArgs=(
            "-A", "x64",
            #f"-DCMAKE_IGNORE_PREFIX_PATH={"C:/msys64/ucrt64"}",
            "-DCMAKE_IGNORE_PATH=C:/msys64/ucrt64/lib/cmake/GTest"
        )
    )
)
