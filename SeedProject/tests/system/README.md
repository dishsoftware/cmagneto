# SeedProject System Tests

This directory is reserved for system-level test drivers and scripts.

Typical checks here exercise workflows around the project rather than a single
native test binary, for example:

- configure/build/install smoke checks;
- linking an external fixture project against the installed package;
- runtime packaging checks.

Fixture projects for these scripts belong under `../@TestProjects/`.

Current scripts:

- `RUN_ALL.py`
  Entry point that runs the whole system-test suite against the already built
  and installed primary project. It runs all registered system tests, prints
  per-test `START`/`PASS`/`FAIL` messages with elapsed time, and returns a
  nonzero exit code if any test fails.
- `test__CMakePackageConsumer__build.py`
  Configures and builds the `CMakePackageConsumer` fixture project against the
  installed primary project package.

Example:

```bash
python3 ./tests/system/RUN_ALL.py \
  --primary_project_path /path/to/PrimaryProject/install/<build-variant>/<build-type> \
  --primary_configure_preset Makefiles_GCC__Release \
  --primary_build_preset Makefiles_GCC__Release \
  --primary_package_preset Makefiles_GCC__Release
```

The fixture project now has its own `CMakePresets.json`, and its presets mirror
the compiler/generator/package-discovery setup of the primary project's build
variants:

```bash
cmake --preset Makefiles_GCC__Release
cmake --build --preset Makefiles_GCC__Release
```

`RUN_ALL.py` is the suite driver. It passes the primary project's install dir
and preset names down to the concrete system-test scripts, runs the full suite,
keeps going after individual failures, and prints a final summary.
