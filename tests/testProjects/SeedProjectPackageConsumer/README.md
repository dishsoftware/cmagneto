# SeedProject Package Consumer

This test project verifies that an installed `SeedProject` package can be found
by CMake and linked against from an external consumer project.

It reads the SeedProject install prefix from the environment variable:

`SEEDPROJECT_INSTALL_DIR`

Example:

```bash
export SEEDPROJECT_INSTALL_DIR=/home/dim/Work/Dish/CMagneto/SeedProject/install/Makefiles_GCC/Release
cmake -S . -B build
cmake --build build
```

What it checks:

- `find_package(DishSW_ContactHolder CONFIG REQUIRED)` succeeds
- target `DishSW::ContactHolder::Contacts` is available
- an executable can compile and link against that target
