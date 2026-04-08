# CMake Package Consumer

This test project verifies that an installed primary project CMake package can be found
by CMake and linked against from an external consumer project.

It reads the primary package install prefix from the environment variable:

`PRIMARY_PROJECT_INSTALL_DIR`

Example:

```bash
export PRIMARY_PROJECT_INSTALL_DIR=/path/to/PrimaryProject/install/<build-variant>/<build-type>
cmake -S . -B build
cmake --build build
```

What it checks:

- `find_package(DishSW_ContactHolder CONFIG REQUIRED)` succeeds
- target `DishSW::ContactHolder::Contacts` is available
- an executable can compile and link against that target
