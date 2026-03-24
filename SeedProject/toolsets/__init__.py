import importlib
import pathlib
from CMagneto.py.cmake.build_platform import BuildPlatform


def _importModuleByPath(iPackagePath: pathlib.Path, iPath: pathlib.Path) -> None:
    if iPath.name == "__init__.py":
        return
    relativeParts = iPath.relative_to(iPackagePath).with_suffix("").parts
    moduleName = f"{__name__}." + ".".join(relativeParts)
    importlib.import_module(moduleName)


packagePath = pathlib.Path(__file__).parent

# Import root-level shared toolsets, if any.
for path in packagePath.glob("*.py"):
    _importModuleByPath(packagePath, path)

# Import only toolsets for the current host OS.
hostToolsetDirNameByOS = {
    BuildPlatform.OS.Linux: "linux",
    BuildPlatform.OS.Windows: "windows",
}
hostToolsetPath = packagePath / hostToolsetDirNameByOS[BuildPlatform().hostOS()]
for path in hostToolsetPath.rglob("*.py"):
    _importModuleByPath(packagePath, path)
