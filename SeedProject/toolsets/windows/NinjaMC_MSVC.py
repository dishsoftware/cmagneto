from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.cmake.toolset import DependencyPathSpec, Toolset, expectExternalSharedLibrariesOnTargetMachine
from CMagneto.py.cmake.toolset_registry import ToolsetRegistry
from pathlib import Path
import os


VCToolsPath = os.environ.get("VC2022ToolsInstallDir")
if VCToolsPath is not None:
    CLPath = Path(VCToolsPath) / "bin" / "Hostx64" / "x64" / "cl.exe"
    VCVarsPath = Path(VCToolsPath).parent.parent.parent / "Auxiliary" / "Build" / "vcvars64.bat"

    ToolsetRegistry().registerToolset(
        Toolset(
            name="NinjaMC_MSVC2022",
            supportedOSes=frozenset({BuildPlatform.OS.Windows}),
            generatorName="Ninja Multi-Config",
            cppCompilerName=str(CLPath),
            envSetupScript=str(VCVarsPath),
            multiConfig=True,
            dependencyPaths=(
                DependencyPathSpec("QT6_MSVC2022_DIR", Path("lib/cmake")),
                DependencyPathSpec("BOOST_MSVC2022_DIR", Path("cmake"))
            ),
            externalSharedLibraryPolicies=expectExternalSharedLibrariesOnTargetMachine(
                "Qt6::Core",
                "Qt6::Gui",
                "Qt6::Widgets"
            )
        )
    )
