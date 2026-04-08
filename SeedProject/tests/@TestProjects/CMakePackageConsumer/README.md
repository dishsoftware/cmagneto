# CMake Package Consumer

This test project verifies that an installed primary project CMake package can be found
by CMake and linked against from an external consumer project.

When this fixture is driven by the system-test suite, the driver script sets the
primary package install prefix through the environment variable:

`PRIMARY_PROJECT_INSTALL_DIR`

Manual example:

```bash
export PRIMARY_PROJECT_INSTALL_DIR=/path/to/PrimaryProject/install/<build-variant>/<build-type>
cmake --preset Makefiles_GCC__Release
cmake --build --preset Makefiles_GCC__Release
```

The local `CMakePresets.json` mirrors the primary project's build-variant
environment setup for:

- `Makefiles_GCC`
- `MinGW`
- `Ninja_MSVC2022`
- `VS2022_MSVC`

What it checks:

- `find_package(DishSW_ContactHolder CONFIG REQUIRED)` succeeds
- target `DishSW::ContactHolder::Contacts` is available
- an executable can compile and link against that target
