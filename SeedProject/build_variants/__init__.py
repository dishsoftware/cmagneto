import importlib
import pathlib
from CMagneto.py.cmake.build_platform import BuildPlatform


def _importModuleByPath(iPackagePath: pathlib.Path, iPath: pathlib.Path) -> None:
    if iPath.name != "build_variant.py":
        return
    relativeParts = iPath.relative_to(iPackagePath).with_suffix("").parts
    moduleName = f"{__name__}." + ".".join(relativeParts)
    importlib.import_module(moduleName)


packagePath = pathlib.Path(__file__).parent

# Import root-level shared build variants, if any.
for path in sorted(packagePath.glob("*/build_variant.py")):
    _importModuleByPath(packagePath, path)

# Import only build variants for the current host OS.
hostBuildVariantDirNameByOS = {
    BuildPlatform.OS.Linux: "linux",
    BuildPlatform.OS.Windows: "windows",
}
hostBuildVariantPath = packagePath / hostBuildVariantDirNameByOS[BuildPlatform().hostOS()]
for path in sorted(hostBuildVariantPath.rglob("build_variant.py")):
    _importModuleByPath(packagePath, path)
