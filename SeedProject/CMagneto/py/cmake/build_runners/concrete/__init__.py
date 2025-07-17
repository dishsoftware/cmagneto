import importlib
import pathlib


# Import all .py files in this dir (concrete) recursively.
packagePath = pathlib.Path(__file__).parent # This package path.
for path in packagePath.rglob("*.py"): # Recursive search.
    if path.name == "__init__.py": # Don't import itself.
        continue
    # Convert file path into dotted module name.
    relativeParts = path.relative_to(packagePath).with_suffix("").parts
    moduleName = f"{__name__}." + ".".join(relativeParts)
    importlib.import_module(moduleName)