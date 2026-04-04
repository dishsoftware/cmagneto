<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This file is part of the CMagneto framework.
It is licensed under the MIT license found in the LICENSE file
located at the root directory of the CMagneto framework.

By default, the CMagneto framework root resides at the root of the project where it is used,
but consumers may relocate it as needed.
-->

![Framework Banner](./doc/assets/header/Header.jpg)
# CMagneto Framework

<!--
Note for developers

Keep this snippet in sync with the same snippets in
- CMagneto project root README.md;
- CMagneto framework root README.md;
- project desciption on GitLab, GitHub, BitBucket etc.
-->
CMagneto is a framework for rapid initialization of C++ projects.<br>
It is designed to set up CMake-backed projects with ease and enforce a unified modular structure, build logic, and tooling integration,<br>
including VS Code, Graphviz, Qt, GoogleTest, LCOV, CPack, Docker and GitLab CI.

🔗 GitLab repository: [gitlab.com/dishsoftware/cmagneto](https://gitlab.com/dishsoftware/cmagneto)<br>
🔗 GitHub mirror: [github.com/dishsoftware/cmagneto](https://github.com/dishsoftware/cmagneto)


---
> **Note:** Paths in the doc are shown relative to the project root.

The framework is shipped with the following major components:
- [`CMagneto CMake modules`](./cmake/) and [`primary coupled Python scripts`](./py/) in the [`./CMagneto/`](.) directory;
    * The [`CMagneto CMake modules`](./cmake/) contain functions to conveniently define CMake targets, generate build stage reports, helper scripts, etc;
    * The [`primary coupled Python scripts`](./py/) provide an optional frontend for preset-driven build and workflow tasks;
- Template configuration files in [`./meta/`](./../meta/);
- Build-variant definitions and accompanying instructions in [`./build_variants/`](./../build_variants/), with one directory per build variant containing `CMakePresets.json` and `Description.md`;
- Optional build frontend [`./build.py`](./../build.py);
- Pre-configured CTest files in [`./tests/`](./../tests/);
- Pre-configured CPack files in [`./packaging/`](./../packaging/) and installation package resource templates in [`./packaging/@resources/`](./../packaging/@resources/);
- Pre-configured [`Dockerfiles`](./../CI/Docker/), one-command [`Docker image build script`](./../CI/Docker/build_image.py) and [`GitLab CI pipeline`](./../CI/GitLab/pipeline.yml) in [`./CI/`](./../CI/);
- Pre-configured VS Code files at [`./.vscode/`](./../.vscode/).


## License
This framework is licensed under the [MIT License](./LICENSE).

### Third-Party Components
- [`./CMagneto/cmake/QtWrappers.cmake`](./cmake/QtWrappers.cmake) is based on [`Salome`](https://www.salome-platform.org/) code and licensed under the GNU LGPL 2.1 or later.<br>
See [the file](./cmake/QtWrappers.cmake) header and [`GNU Lesser General Public License, version 2.1`](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).

### Third-Party Dependencies
The CMagneto Framefork does not include distributable packages or source code,<br>
but integrates with or fetches the following external tools during project builds:
- **Qt** is used under the terms of the GNU LGPL 3.0. See [`Qt Licensing`](https://doc.qt.io/qt-6/licensing.html) for details.
- **Google Test** is used under the terms of the BSD 3-Clause License. See [https://github.com/google/googletest/blob/main/LICENSE](https://github.com/google/googletest/blob/main/LICENSE).

Users are responsible for complying with the licenses of these tools when using them in their own projects.

> **Note:** Users do not need to include the Google Test license in their repositories or distributions,<br>
> if they just use Google Test APIs and not bundle respositories or distributions of the Google Test.


## Git History Policy
Avoid resetting even non-protected branches, except when fixing trivial issues (e.g., typos in recent commits).<br>
Preserving full commit history — including mistakes and work-in-progress — serves several important purposes:
* 🛡 **Protect against fraudulent forks or mirrors**: If history is rewritten, bad actors could replicate the project, strip or rewrite authorship, and falsely claim original ownership or prior invention.
* 🧠 **Document the development process**: Mistakes and revisions are part of real-world software development. Keeping them in the history shows how decisions evolved.
* 📊 **Communicate progress transparently**: The Git log itself reflects the status and evolution of a feature, reducing reliance on external tracking tools.

In short: **commit freely, but rewrite with caution**. Let the repo tell the whole story.


## Documentation Conventions
- Paths, names of variables and options, and their values are `highlighted` and not wrapped in quotes.
- If a path, name or value includes `a {placeholder}, wrapped in curly braces,` the `placeholder` is a required value that must be substituted.
- If `a [{placeholder}] is wrapped in square brackets`, the `placeholder` is optional.
- Always use relative paths, unless an absolute path is genuinely required.


## Project Build Tools
The CMagneto framework needs on the following software to build your project:
- CMake 3.31 or later. Version is bound by the preset schema and the features used by the optional Python frontend.
- C++ 17 (or later) compiler (e.g. GCC, MinGW, MSVC). Version is bound by the GoogleTest CMake module.
- Python 3.10 or later. Version is bound by the coupled Python code.
- Graphviz (optional, for target graph).
- Qt lrelease 6.4.2 or later (if any target in the project has Qt `*.ts` files). Version is bound by the oldest tested version.
- Qt Installer Framework 4.10 or later (optional, for packaging). Version is bound by the oldest tested version.
- GoogleTest (1.17.0 or whatever a package manager provides) (optional, if your project has tests). Downloaded automatically by CMake during project generation.<br>
    Version is bound by the tested version.
- LCOV 2.0-1 (optional, if test coverage estimation is run and compiler is GCC/CLang).<br>
    Version is bound by the tested version.

> **Note:** If CMake target dependency graph picture is desired, Graphviz must be installed.<br>
> Output is located at `./build/{build_variant}/[{build_type}]/graphviz/`.<br>
> If Graphviz is installed, but no image is generated, define the `GRAPHVIZ_DIR` environment variable, e.g. `GRAPHVIZ_DIR=C:\Program Files\Graphviz`.

> **Note:** The easiest way to get Qt Installer Framework - install it using QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source.<br>
> Another option is to compile it from [sources](https://download.qt.io/official_releases/qt-installer-framework/).<br>
> Add the Qt Installer Framework’s `bin/` directory to your system `PATH`, e.g. `C:\Qt\Tools\QtInstallerFramework\4.10\bin`.


## Project Structure
The framework mandates or endorses restrictions on locations of project files.
```text
SeedProject/
├── build.py                               # Optional project build frontend over committed CMake presets.
├── CMakeLists.txt                         # [Project] top-level ([project] root) `CMakeLists.txt`. Define project (call `project()`) here.
├── CMagneto/                              # CMagneto framework core files.
|   ├── LICENSE
|   ├── README.md                          # This file.
|   ├── TODO.md                            # Limitations and known issues.
|   ├── cmake/                             # CMagneto CMake modules root.
|   |   ├── Main.cmake                     # CMagneto CMake entrypoint-module.
|   |   ├── MetaLoader.cmake               # The module must be loaded prior to Main.cmake.
|   |   ├── Packager.cmake                 # Loaded separately.
|   |   └── ...
|   ├── doc/                               # Other documentation.
|   └── py/                                # Coupled Python code.
├── meta/
│   ├── Project.json
│   ├── Packaging.json
│   └── CI.json
├── licenses/                              # Installed/package legal files configuration and checked-in legal resources.
|   ├── bundles/                           # License bundle manifests selected by build variants.
|   ├── components/                        # Reusable license component manifests.
|   └── 3rd-party/                         # Optional checked-in third-party legal files.
├── CMakePresets.json                      # Root preset manifest that includes concrete variant files from ./build_variants/.
├── build_variants/                        # Concrete build variants owned by per-variant CMakePresets files.
│   ├── linux/
|   |   ├── UnixMakefiles_GCC/
|   |   |   ├── CMakePresets.json
|   |   |   ├── Description.md
|   |   |   └── ...
|   |   └── ...
│   └── ...
├── src/                                   # Project source root.
│   └── {CompanyName_SHORT}/               # The nesting is mandated.
│       └── {ProjectNameBase}/             # The nesting is mandated.
│           └── TargetName/                # Target source root. Code of the target can be nested arbitrary under this dir.
|               ├── CMakeLists.txt         # Target top-level (target root) `CMakeLists.txt`. Target Add target here.
│               ├── TargetName_EXPORT.hpp  # Generated automatically if absent for library targets. Defines export/import macro for shared libraries. Added to the target implicitly.
│               ├── TargetName_DEFS.hpp    # Generated automatically if absent. Defines target-specific helper macros such as ASSERT/VERIFY. Added to the target implicitly.
|               ├── Header.hpp
|               ├── Source.cpp
|               ├── Code/
│               |   ├── Header.hpp
│               |   ├── Source.cpp
│               |   ├── Code/
|               |   |   └── ...
│               |   └── ...
|               ├── ...
|               └── @resources/            # Target resources root.
|                   ├── QtRC/              # Resources to embed into target's binary using Qt RCC. Under this dir, the resources can be nested arbitrary.
|                   ├── QtTS/              # Qt `*.ts` files to compile `*.qm` external resource files. Under this dir, `*.ts` files can be nested arbitrary.
|                   └── other/             # Other external resources (loaded dynamically during runtime). Under this dir, the resources can be nested arbitrary.
├── tests/                                 # Project tests' root. Under this dir, headers, sources and resources of unit and integration tests can be nested arbitrary.
|   ├── CMakeLists.txt                     # GoogleTest is set up here. No need to change the file.
│   ├── {CompanyName_SHORT}/               # The nesting is mandated.
│   |   └── {ProjectNameBase}/             # The nesting is mandated.
│   |       ├── TargetName/                # Test target source root.
|   |       |   ├── CMakeLists.txt         # Add test target TESTS_TargetName and call `CMagneto__register_test_target(TESTS_TargetName)` here.
|   |       |   |                          # ^ The naming of test targets is not mandated, but endorsed.
|   |       |   ├── TEST_Header.hpp        # The naming is not mandated, but endorsed.
|   |       |   ├── TEST_Source.cpp        # The naming is not mandated, but endorsed.
│   |       |   └── ...
│   |       └── ...
│   └── ...                                # Tests for external projects can be placed here.
├── packaging/
│   ├── CPackConfig.cmake
│   └── @resources/                        # Package resources root. Under this dir, the resources can be nested arbitrary.
├── CI/
│   ├── Docker/                            # Dockerfiles root. Under this dir Dockerfiles can be nested arbitrary.
|   |   ├── build_image.py                 # One-command Docker image build script.
│   |   └── ...
│   └── GitLab/                            # GitLab `*.yml` files root. Under this dir CI-pipeline-related files can be nested arbitrary.
└── ...
```
> **Note:** Targets can be nested arbitrary, i.e. a target's subdir can contain a target root of another target.


## Code Conventions
Look into [`./CMagneto/doc/CodeConventions.md`](./doc/CodeConventions.md).

## License Management
Look into [`./CMagneto/doc/LicenseManagement.md`](./doc/LicenseManagement.md).

---


## 1. How To Use The CMagneto Framework
### 1.1. Initialize Your Project
1) Copy all content from the [root of the seed project](./../) into the root of your empty project repo.<br>
    Open `./vscode/Project.code-workspace` from your project repository and close everything from the [`CMagneto framework repository`](./../../).<br>
    Open the copy of this file from your repo. <br>
    ⏳...<br>
    Now [this](./../) should be the root of your project.

2) Consider everything in your repo, except [`./CMagneto/`](.) and its contents, as a **ready-to-use CMake C++ project template**.
    You may hop to [`1.2. Build Project`](#12-build-project) section of the doc to verify the build pipeline succeeds.

    > **Note:** Since `CMagneto` is licensed under the MIT License, you're free to use, modify, and extend the framework.<br>
    > If you do make improvements, please consider sharing them on the [CMagneto GitLab repository](https://gitlab.com/dishsoftware/cmagneto) — contributions are always welcome!

3) Configure project.<br>
    The [`./meta/`](./../meta/) directory contains JSON files for high-level project metadata.<br>
    Adjust values in:
    - [`./meta/Project.json`](./../meta/Project.json)
    - [`./meta/Packaging.json`](./../meta/Packaging.json)

    and installation package resources in [`./packaging/@resources/`](./../packaging/@resources/).

4) Define build variants in [`./build_variants/`](./../build_variants/). Each build variant should live in its own directory named after the build variant and contain `CMakePresets.json` and `Description.md`.

5) Change contents of the project's [`./LICENSE`](./../LICENSE), [`./README.md`](./../ReadMe.md), [`./TODO.md`](./../TODO.md) and [`./doc/`](./../doc/). Don't forget to mention the CMagneto framework and its [LICENSE (`./CMagneto/LICENSE`)](./LICENSE)!

6) Proceed to writing code of the project. Adhere to the [project structure](#project-structure).<br>


### 1.2. Use The CMagneto CMake Module.
> **Note:** Functions, variables and constants of the CMagneto module are only intended to be accessed,<br>
> if they are defined (not included) in a `*.cmake` file without `_Internal` suffix in its name.<br>
> Names of such functions, variables and constants start with `CMagneto__`.

> **Note:** Until the end of the list paths are shown relative to the project root.

1) > **Note:** You can skip items [1; 3] of the list. Jist keep [top-level (root) `CMakeLists.txt`](./../CMakeLists.txt) as is.

    Include the [`./CMagneto/cmake/MetaLoader.cmake`](./cmake/MetaLoader.cmake) submodule in the [top-level (root) `CMakeLists.txt`](./../CMakeLists.txt)<br>
    before `project()` command and inclusion of the rest of the `CMagneto` module.<br>
    Use `CMagneto__PROJECT_JSON__*` variables, defined by `CMagneto__parse__project_json()` function of the submodule, in the `project()` command:
    ```cmake
    cmake_minimum_required(VERSION 3.31)
    include("${CMAKE_SOURCE_DIR}/CMagneto/cmake/MetaLoader.cmake")
    CMagneto__parse__project_json()
    project("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}"
        DESCRIPTION "${CMagneto__PROJECT_JSON__PROJECT_DESCRIPTION}"
        HOMEPAGE_URL "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}"
        VERSION "${CMagneto__PROJECT_JSON__PROJECT_VERSION}"
        LANGUAGES CXX
    )
    ```

2) Set project-global options, e.g.:
    ```cmake
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    ```

3) Include the [`./CMagneto/cmake/Main.cmake`](./cmake/Main.cmake) entrypoint-module in the [root `CMakeLists.txt`](./../CMakeLists.txt):
    ```cmake
    include("${CMAKE_SOURCE_DIR}/CMagneto/cmake/Main.cmake")
    ```

4) Add library targets in `CMakeLists.txt` files under subdirectories of [`./src/`](./../src/):
    ```cmake
    # The real target name must equal the path under `./src/` with "/" replaced by "_".
    # Example: `./src/DishSW/ContactHolder/Contacts` -> DishSW_ContactHolder_Contacts
    CMagneto__get_library_type(DishSW_ContactHolder_Contacts _LIB_TYPE)
    add_library(DishSW_ContactHolder_Contacts ${_LIB_TYPE}) # Don't add any files to the target in the command.
    target_link_libraries(DishSW_ContactHolder_Contacts
        ...
        # Aliases are derived from the real target name by replacing "_" with "::":
        # DishSW_ContactHolder_Contacts -> DishSW::ContactHolder::Contacts
    )
    CMagneto__set_up__library(DishSW_ContactHolder_Contacts
        ... # List all target's files here, except resources to embed into the target's binary using Qt RCC.
    )
    ```

5) Add executable targets in `CMakeLists.txt` files under subdirectories of [`./src/`](./../src/):
    ```cmake
    add_executable(DishSW_ContactHolder_GUI) # Don't add any files to the target in the command.
    target_link_libraries(DishSW_ContactHolder_GUI ...)
    CMagneto__set_up__executable(DishSW_ContactHolder_GUI
        ... # List all target's files here, except resources to embed into the target's binary using Qt RCC.
    )
    ```
    The alias is generated automatically from the real target name by replacing each `_` with `::`.

6) If an executable should have a custom file-browser / shell icon, place icon files under the target source root, for example in `@resources/AppIcon/`, and call:
    ```cmake
    CMagneto__bind_icon_to_exe_binary(DishSW_ContactHolder_GUI
        WINDOWS_ICON "@resources/AppIcon/ContactHolder.ico"
        MACOS_ICON "@resources/AppIcon/ContactHolder.icns"
    )
    ```
    Notes:
    - The function must be called after `add_executable(...)`.
    - You may specify only `WINDOWS_ICON`, only `MACOS_ICON`, or both.
    - On Windows, the `.ico` file is embedded into the `.exe` binary.
    - On macOS, the `.icns` file is attached to the app bundle and only takes effect for `MACOSX_BUNDLE` executables.
    - On Linux, the function is currently a no-op because ELF executables do not have a standard embedded desktop icon mechanism.

7) If an executable should also have an icon file placed next to it in the build tree and install tree, call:
    ```cmake
    CMagneto__place_icon_near_executable(DishSW_ContactHolder_GUI
        WINDOWS_ICON "@resources/AppIcon/ContactHolder.ico"
        LINUX_ICON "@resources/AppIcon/ContactHolder.png"
        MACOS_ICON "@resources/AppIcon/ContactHolder.icns"
    )
    ```
    Notes:
    - The function must be called after `add_executable(...)`.
    - You may specify only the platforms you care about.
    - Only the icon matching the current platform is copied.
    - The file is copied next to the built executable and installed into `bin/`, so packages include it too.
    - This function does not bind the icon to the executable binary itself. Use `CMagneto__bind_icon_to_exe_binary(...)` for that.

8) If an executable should appear in the application menu, register it explicitly:
    ```cmake
    CMagneto__add_executable_to_application_menu(DishSW_ContactHolder_GUI
        NAME "Contact Holder"
        WINDOWS_ICON "@resources/AppIcon/ContactHolder.ico"
        LINUX_ICON "@resources/AppIcon/ContactHolder.png"
    )
    ```
    If another installed file should appear there instead, register it by its install-relative path:
    ```cmake
    CMagneto__add_installed_file_to_application_menu("bin/MyHelper.exe"
        NAME "My Helper"
        WINDOWS_ICON "@resources/AppIcon/MyHelper.ico"
    )
    ```
    Notes:
    - `NAME` is the launcher label shown to users.
    - `CMagneto__add_installed_file_to_application_menu(...)` accepts a path relative to the installation prefix.
    - On Windows, registered entries are used by IFW packages to create Start Menu shortcuts.
    - Linux icon metadata can already be registered through `LINUX_ICON`, but a Linux application-menu backend is not wired yet.
    - ZIP packages do not create Start Menu entries.

   Configure the Windows Start Menu folder in `./meta/Packaging.json`, for example:
    ```json
    {
      "PackageID": "org.example.myapp",
      "PackageNamePrefix": "MyApp",
      "PackageMaintainer": "Jane Doe <jane@example.com>",
      "StartMenuDirectory": "DishSW"
    }
    ```
    Notes:
    - If `StartMenuDirectory` is omitted, CMagneto uses `CompanyName_SHORT`.
    - If `StartMenuDirectory` is an empty string, IFW places shortcuts in the Start Menu root.

9) Define runtime-installation policy for imported shared-library dependencies in the active build variant under [`./build_variants/`](./../build_variants/) by setting preset `cacheVariables`:
    ```json
    {
      "cacheVariables": {
        "CMAKE_PREFIX_PATH": "$env{QT6_MSVC2022_DIR}/lib/cmake",
        "CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE": "Qt6::Core;Qt6::Gui;Qt6::Widgets",
        "CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE": "MyPrivateDependency::MyPrivateDependency",
        "CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS": "plugins/imageformats/*",
        "CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS": "libc.so*;ld-linux*.so*"
      }
    }
    ```
    Use `CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE` if the dependency is expected to be installed on the target machine at the same absolute location as on the build machine.
    Use `CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE` if the shared-library binaries must be included into the installation package.
    Use the `CMagneto__BUNDLED_RUNTIME_DEPENDENCY...` and `CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY...` overrides only for low-level exceptions such as plugins, helper libraries, or bundling misdetections that are not represented cleanly by imported shared-library targets.
    When both target-based policy and low-level overrides are used, explicit exclude overrides win over explicit include overrides. Full precedence details are documented in [`./doc/SharedLibraryDeployment.md`](./doc/SharedLibraryDeployment.md).

    The build variant is the preferred place for this decision because the required policy may depend on compiler, package manager, deployment model, or other build-variant details.
    Advanced users may still call `CMagneto__expect_external_shared_libraries_on_target_machine(...)`, `CMagneto__bundle_external_shared_libraries(...)`, `CMagneto__bundle_runtime_dependency_files(...)`, or `CMagneto__exclude_bundled_runtime_dependency_file_patterns(...)` directly in CMake as manual overrides, but this is not the primary workflow.

10) Select engaged packagers in the active build variant with preset `cacheVariables`:
    ```json
    {
      "cacheVariables": {
        "CMagneto__PACKAGE_GENERATORS": "ZIP;IFW"
      }
    }
    ```
    Notes:
    - `CMagneto__PACKAGE_GENERATORS=AUTO` keeps the framework defaults for the current platform.
    - Use a semicolon-separated list such as `ZIP`, `IFW`, `DEB`, or `ZIP;IFW`.
    - Project-side custom generator modules may be added under `./packaging/Packager/{GENERATOR}/` as optional files:
      `./packaging/Packager/{GENERATOR}/{GENERATOR}Config_before_include_CPack.cmake`
      and
      `./packaging/Packager/{GENERATOR}/{GENERATOR}Config.cmake`
    - If a selected generator has no project-side or framework-specific module, CMagneto applies only generic CPack settings and warns.

11) If the project defines an executable target, which is considered as the project entrypoint, call
    ```cmake
    CMagneto__set_project_entrypoint(EntrypointTargetName)
    ```
    to configure the optional `run` helper script (see section [`1.4. Run Project`](#14-run-project)).

12) If a target has resources to embed into its binary, place them under the `@resources/QtRC/` target subdirectory and call:
    ```cmake
    CMagneto__embed_QtRC_resources(TargetName # Must be called from the target root `CMakeLists.txt`.
        ... # List the files to embed here.
    )
    ```

13) Keep [`./tests/CMakeLists.txt`](./../tests/CMakeLists.txt) as is.

14) Add test targets in `CMakeLists.txt` files under subdirectories of [`./tests/`](./../tests/):
    ```cmake
    set(_TESTS_TargetName "TESTS_${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}_TargetName")

    add_executable(${_TESTS_TargetName}
        TEST_Source.cpp
    )

    target_link_libraries(${_TESTS_TargetName}
        PRIVATE
            GTest::gtest_main
            {CompanyName_SHORT}::{ProjectNameBase}::TargetName
    )

    CMagneto__register_test_target(${_TESTS_TargetName})
    ```

15) After all targets are set up, call: `CMagneto__set_up__project()`.
    The function sets up:
    - CMake project package export (`*Config.cmake`, etc);
    - target runtime lookup configuration for build and install trees;
    - installation of build-variant-selected bundled external shared libraries into the package;
    - optional legacy `set_env` and `run` helper scripts in the build tree (see section [`1.4. Run Project`](#14-run-project));
    - Auxilliary files, required by the coupled Python code and VS Code.
    - Unit and integration test compilation and `run_tests` scripts;
    - CPack package configuration files, auxilliary targets, reports, helper scripts, etc.;


### 1.3. Build Project
Use committed CMake presets from [`./CMakePresets.json`](./../CMakePresets.json) directly, or use [`./CMagneto/py/cmake/build.py`](./py/cmake/build.py) and its proxy [`./build.py`](./../build.py) as an optional frontend that selects presets and orchestrates build stages.<br>
To see available options, run:
```bash
python ./build.py --help
```
The presets file is the build source of truth.<br>
The optional Python frontend keeps a consistent `--build_variant/--build_type` UX across single- and multi-config generators and performs a few convenience actions such as Graphviz rendering.

`compile_commands.json` belongs to the preset-selected build directory generated by CMake. This keeps each configured build tree self-contained and allows several development modes to coexist without overwriting one another.

Preset selection follows this rule:
- for single-config generators, `build.py` uses `{build_variant}__{build_type}` as the configure, build, and package preset name;
- for multi-config generators, `build.py` uses `{build_variant}` as the configure preset and `{build_variant}__{build_type}` as the build and package preset name.

Library type policy belongs to configure preset `cacheVariables`:
- `BUILD_SHARED_LIBS` sets the default library type;
- `LIB_<TARGET_NAME_UPPERCASED>_SHARED` overrides a specific target.

Example:
```json
"cacheVariables": {
  "BUILD_SHARED_LIBS": "OFF",
  "LIB_DISHSW_CONTACTHOLDER_CONTACTS_SHARED": "ON"
}
```

Examples:
- `--build_variant Makefiles_GCC --build_type Debug` selects `Makefiles_GCC__Debug`;
- `--build_variant VS2022_MSVC --build_type Debug` selects configure preset `VS2022_MSVC` and build/package preset `VS2022_MSVC__Debug`.


### 1.4. Run Project
CMagneto separates deployment policy from platform-specific runtime mechanics:
- The deployment policy is chosen in the active build variant preset through cache variables such as `CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE` and `CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE`.
- On Linux, executables and shared libraries get `BUILD_RPATH` and `INSTALL_RPATH` values.
- On Linux, imported shared libraries selected as `CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE` contribute their build-machine directories to `INSTALL_RPATH`.
- Bundled imported shared libraries are copied into the install tree on all supported platforms. On Linux they are placed into `lib/`; on Windows they are placed into `bin/`.
- On Windows, runtime DLLs of a target are still copied next to the target binary in the build tree as a local-development convenience.
- For Debian packages, [`CPACK_DEBIAN_PACKAGE_SHLIBDEPS`](./cmake/Packager/DEB/DEBConfig_before_include_CPack.cmake) is enabled, so package dependencies on system-installed shared libraries are computed automatically.

CMagneto CMake function `CMagneto__set_up__project()` also creates helper scripts inside `bin/` subdirectories of `./build/`:
- `set_env` is a legacy development helper for running build-tree binaries with imported shared libraries expected to be present on the target machine;
- `run` executes `set_env` and then runs the project entrypoint executable.

These helper scripts are not meant to be an installation or distribution mechanism. Installed and packaged applications should rely on the build-variant-selected dependency policy and the corresponding platform-specific runtime setup.

For a detailed explanation of how imported 3rd-party shared libraries are deduced, classified, packaged, and resolved on Linux and Windows, see [`./doc/SharedLibraryDeployment.md`](./doc/SharedLibraryDeployment.md).

On Linux, these scripts are usually redundant because build-tree and install-tree runtime lookup is expected to be configured by target properties such as runtime paths and bundled library locations. They are kept mainly for workflow consistency across platforms and for occasional local debugging or experiments.

On Windows, these scripts may still be more useful during local development and debugging because runtime DLL lookup often depends more directly on process environment such as `PATH`.


### 1.5. Engage Continuous Integration (CI)
Adjust values in [`./meta/CI.json`](./../meta/CI.json) before any actions with [Docker images](./../CI/Docker/) and [CI workflow (pipeline triggering rules)](./../CI/GitLab/workflow.yml) and [pipeline](./../CI/GitLab/pipeline.yml).

#### 1.5.1. Build Docker Images
Use [`./CMagneto/py/docker/build_image.py`](./py/docker/build_image.py) or its proxy [`./CI/Docker/build_image.py`](./../CI/Docker/build_image.py) to build [Docker images](./../CI/Docker/):
```bash
python ./build_image.py --help
```
[`./CI/Docker/`](./../CI/Docker/) contains Dockerfiles. They must be fed to [`./CMagneto/py/docker/build_image.py`](./py/docker/build_image.py) every time they are changed before triggering CI pipeline.

#### 1.5.2. GitLab
Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to \"[`CI/GitLab/workflow.yml`](./../CI/GitLab/workflow.yml)\".

##### 1.5.2.1. CI Triggers
The [`./CI/GitLab/workflow.yml`](./../CI/GitLab/workflow.yml) instructs GitLab to trigger (create) a CI pipeline, if the `main` branch is involved or a tag is pushed.<br>
To trigger a pipeline for an untagged commit to another branch, push the commit to the branch with a message, ending with `RUN_CI_PIPELINE`.

##### 1.5.2.2. CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/packages/generic/{DockerRegistrySuffix}/{BranchName_or_Tag}/{Platform}/{build_variant}/{PackageNamePrefix}-{ProjectVersion}.{PackageExtension}`,

where:
- `CI_PROJECT_ID` is a GitLab CI variable, which resolves to a number, e.g. `71534203`;
- `DockerRegistrySuffix` is defined in [`./meta/CI.json`](./../meta/CI.json);
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](./../CI/Docker/Dockerfile.Ubuntu24AMD__build) yields Platform=`Ubuntu24AMD`;
- `build_variant` is the argument, passed to [`./build.py --build_variant`](./py/cmake/build.py);
- `PackageNamePrefix` and `ProjectVersion` are defined in [`./meta/Packaging.json`](./../meta/Packaging.json) and [`./meta/Project.json`](./../meta/Project.json);
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in [`./CMagneto/cmake/Packager.cmake`](./cmake/Packager.cmake) and depends on platform and build variant.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/Makefiles_GCC/DishSW_ContactHolder-0.0.1.deb](https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/Makefiles_GCC/DishSW_ContactHolder-0.0.1.deb) .


## 2. Knowledge Base
This Knowledge Base serves as a centralized collection of technical notes, clarifications, code excerpts, and curated content from books, documentation, and online resources. It is designed for quick reference during development to reduce repetitive searches.

- [CMake](./doc/CMakeKnowledge.md)
- [Third-party shared library deployment](./doc/SharedLibraryDeployment.md)
- [Linux package verification](./doc/LinuxPackageVerification.md)
