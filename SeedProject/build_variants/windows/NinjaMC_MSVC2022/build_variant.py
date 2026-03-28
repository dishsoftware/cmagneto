from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.build_variant import BuildVariant, DependencyPathSpec, bundleExternalSharedLibraries
from CMagneto.py.cmake.build_variant_registry import BuildVariantRegistry
from pathlib import Path
import os


VCToolsPath = os.environ.get("VC2022ToolsInstallDir")
if VCToolsPath is not None:
    CLPath = Path(VCToolsPath) / "bin" / "Hostx64" / "x64" / "cl.exe"
    VCVarsPath = Path(VCToolsPath).parent.parent.parent / "Auxiliary" / "Build" / "vcvars64.bat"

    BuildVariantRegistry().registerBuildVariant(
        BuildVariant(
            name="NinjaMC_MSVC2022",
            supportedOSes=frozenset({BuildPlatform.OS.Windows}),
            generatorName="Ninja Multi-Config",
            cppCompilerName=str(CLPath),
            envSetupScript=str(VCVarsPath),
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
                #f"-DCMAKE_IGNORE_PREFIX_PATH={"C:/msys64/ucrt64"}",
                "-DCMAKE_IGNORE_PATH=C:/msys64/ucrt64/lib/cmake/GTest",
            )
        )
    )
