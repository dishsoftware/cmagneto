<!--
Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

![Framework Banner](./doc/assets/header/Header.jpg)
# CMagneto Framework
🔗 GitLab repository: [https://gitlab.com/dishsoftware/cmagneto](https://gitlab.com/dishsoftware/cmagneto)

The CMagneto framework is designed to set up CMake C++ projects with ease and enforce a unified modular structure, build logic, and tooling integration.<br>

> **Note:** Paths in the doc are shown relative to the project root.

The framework is shipped with the following major components:
- [`CMagneto CMake modules`](./cmake/) and [`primary coupled Python scripts`](./py/) in the [`./CMagneto/`](.) directory;
    * The [`CMagneto CMake modules`](./cmake/) contain functions to conveniently define CMake targets, generate build stage reports, helper scripts, etc;
    * The [`primary coupled Python scripts`](./py/) streamline the build process into a single command;
- Template configuration files in [`./meta/`](./../meta/);
- One-command build script [`./build.py`](./../build.py);
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


## Documentation Conventions
- Paths, names of variables and options, and their values are `highlighted` and not wrapped in quotes.
- If a path, name or value includes `a {placeholder}, wrapped in curly braces,` the `placeholder` is a required value that must be substituted.
- If `a [{placeholder}] is wrapped in square brackets`, the `placeholder` is optional.
- Always use relative paths, unless an absolute path is genuinely required.


## Project Build Tools
The CMagneto framework needs on the following software to build your project:
- CMake 3.28 or later. Version bound by the oldest tested version.
- C++ 17 (or later) compiler (e.g. GCC, MinGW, MSVC). Version bound by the GoogleTest CMake module.
- Python 3.10 or later. Version bound by the coupled Python code.
- Graphviz (optional, for target graph).
- Qt lrelease 6.4.2 or later (if any target in the project has Qt `*.ts` files). Version bound by the oldest tested version.
- Qt Installer Framework 4.10 or later (optional, for packaging). Version bound by the oldest tested version.

> **Note:** If CMake target dependency graph picture is desired, Graphviz must be installed.<br>
> Output is located at `./build/{toolset}/[{build_type}]/graphviz/`.<br>
> If Graphviz is installed, but no image is generated, define the `GRAPHVIZ_DIR` environment variable, e.g. `GRAPHVIZ_DIR=C:\Program Files\Graphviz`.

> **Note:** The easiest way to get Qt Installer Framework - install it using QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source.<br>
> Another option is to compile it from [sources](https://download.qt.io/official_releases/qt-installer-framework/).<br>
> Add the Qt Installer Framework’s `bin/` directory to your system `PATH`, e.g. `C:\Qt\Tools\QtInstallerFramework\4.10\bin`.


## Project Structure
The framework mandates or endorses restrictions on locations of project files.
```text
ProjectRoot/
├── build.py                         # One-command project build script.
├── CMakeLists.txt                   # [Project] top-level ([project] root) `CMakeLists.txt`. Define project (call `project()`) here.
├── CMagneto/                        # CMagneto framework core files.
|   ├── LICENSE
|   ├── README.md                    # This file.
|   ├── TODO.md                      # Limitations and known issues.
|   ├── cmake/                       # CMagneto CMake modules root.
|   |   ├── Main.cmake               # CMagneto CMake entrypoint-module.
|   |   ├── MetaLoader.cmake         # The module must be loaded prior to Main.cmake.
|   |   ├── Packager.cmake           # Loaded separately.
|   |   └── ...
|   ├── doc/                         # Other documentation.
|   └── py/                          # Coupled Python code.
├── meta/
│   ├── Project.json
│   ├── Packaging.json
│   └── CI.json
├── src/                             # Project source root.
│   └── {CompanyName_SHORT}/         # The nesting is not mandated, but endorsed.
│       └── {ProjectNameBase}/       # ^
│           └── TargetName/          # Target source root. Code of the target can be nested arbitrary under this dir.
|               ├── CMakeLists.txt   # Target top-level (target root) `CMakeLists.txt`. Target Add target here.
|               ├── Header.hpp
|               ├── Source.cpp
|               ├── Code/
│               |   ├── Header.hpp
│               |   ├── Source.cpp
│               |   ├── Code/
|               |   |   └── ...
│               |   └── ...
|               ├── ...
|               └── @resources/      # Target resources root.
|                   ├── QtRC/        # Resources to embed into target's binary using Qt RCC. Under this dir, the resources can be nested arbitrary.
|                   ├── QtTS/        # Qt `*.ts` files to compile `*.qm` external resource files. Under this dir, `*.ts` files can be nested arbitrary.
|                   └── other/       # Other external resources (loaded dynamically during runtime). Under this dir, the resources can be nested arbitrary.
├── tests/                           # Project tests' root. Under this dir, headers, sources and resources of unit and integration tests can be nested arbitrary.
|   ├── CMakeLists.txt               # GoogleTest is set up here. No need to change the file.
│   ├── {CompanyName_SHORT}/         # The nesting is not mandated, but endorsed.
│   |   └── {ProjectNameBase}/       # ^
│   |       ├── TargetName/          # Test target source root.
|   |       |   ├── CMakeLists.txt   # Add test target TESTS_TargetName and call `CMagneto__register_test_target(TESTS_TargetName)` here.
|   |       |   |                    # ^ The naming of test targets is not mandated, but endorsed.
|   |       |   ├── TEST_Header.hpp  # The naming is not mandated, but endorsed.
|   |       |   ├── TEST_Source.cpp  # The naming is not mandated, but endorsed.
│   |       |   └── ...
│   |       └── ...
│   └── ...                          # Tests for external projects can be placed here.
├── packaging/
│   ├── CPackConfig.cmake
│   └── @resources/                  # Package resources root. Under this dir, the resources can be nested arbitrary.
├── CI/
│   ├── Docker/                      # Dockerfiles root. Under this dir Dockerfiles can be nested arbitrary.
|   |   ├── build_image.py           # One-command Docker image build script.
│   |   └── ...
│   └── GitLab/                      # GitLab `*.yml` files root. Under this dir CI-pipeline-related files can be nested arbitrary.
└── ...
```
> **Note:** Targets can be nested arbitrary, i.e. a target's subdir can contain a target root of another target.


## Code Conventions
Look into [`./CMagneto/doc/CodeConventions.md`](./doc/CodeConventions.md).

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

3) Change contents of the project's [`./LICENSE`](./../LICENSE), [`./README.md`](./../ReadMe.md), [`./TODO.md`](./../TODO.md) and [`./doc/`](./../doc/). Don't forget to mention the CMagneto framework and its [LICENSE (`./CMagneto/LICENSE`)](./LICENSE)!

4) Proceed to writing code of the project. Adhere to the [project structure](#project-structure).<br>


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
    cmake_minimum_required(VERSION 3.28)
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
    CMagneto__get_library_type(TargetName _LIB_TYPE)
    add_library(TargetName ${_LIB_TYPE}) # Don't add any files to the target in the command.
    target_link_libraries(TargetName ...)
    CMagneto__set_up__library(TargetName
        ... # List all target's files here, except resources to embed into the target's binary using Qt RCC.
    )
    ```

5) Add executable targets in `CMakeLists.txt` files under subdirectories of [`./src/`](./../src/):
    ```cmake
    add_executable(TargetName) # Don't add any files to the target in the command.
    target_link_libraries(TargetName ...)
    CMagneto__set_up__executable(TargetName
        ... # List all target's files here, except resources to embed into the target's binary using Qt RCC.
    )
    ```

6) If the project defines an executable target, which is considered as the project entrypoint, call
    ```cmake
    CMagneto__set_project_entrypoint(EntrypointTargetName)
    ```
    to configure `run` scripts (see section [`1.3. Run Project`](#13-run-project)).

7) If a target has resources to embed into its binary, place them under the `@resources/QtRC/` target subdirectory and call:
    ```cmake
    CMagneto__embed_QtRC_resources(TargetName # Must be called from the target root `CMakeLists.txt`.
        ... # List the files to embed here.
    )
    ```

8) Keep [`./tests/CMakeLists.txt`](./../tests/CMakeLists.txt) as is,<br>
   or change `add_subdirectory("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")` command arguments, if you don't stick to the endorsed `{CompanyName_SHORT}/{ProjectNameBase}/{TargetName}/` nesting scheme.
    ```

9) Add test targets in `CMakeLists.txt` files under subdirectories of [`./tests/`](./../tests/):
    ```cmake
    set(_TESTS_TargetName "TESTS_${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}_TargetName")

    add_executable(${_TESTS_TargetName}
        TEST_Source.cpp
    )

    target_link_libraries(${_TESTS_TargetName}
        PRIVATE
            GTest::gtest_main
            TargetName
    )

    CMagneto__register_test_target(${_TESTS_TargetName})
    ```

10) After all targets are set up, call: `CMagneto__set_up__project()`.
    The function sets up:
    - CMake project package export (`*Config.cmake`, etc);
    - `set_env` and `run` scripts (see section [`1.3. Run Project`](#13-run-project));
    - Auxilliary files, required by the coupled Python code and VS Code.
    - Unit and integration test compilation and `run_tests` scripts;
    - CPack package configuration files, auxilliary targets, reports, helper scripts, etc.;


### 1.2. Build Project
Use [`./CMagneto/py/cmake/build.py`](./py/cmake/build.py) or its proxy [`./build.py`](./../build.py) to generate build system files (e.g. MakeFiles or MSVS solution), compile, test, install the project and generate installation packages.<br>
To see available options, run:
```bash
python ./build.py --help
```
The [`./CMagneto/py/cmake/build.py`](./py/cmake/build.py) supports multiple toolsets (pairs of a build system and a compiler). The toolsets were tested on the following platforms:
- [Ubuntu 24 with Make and GCC](#121-ubuntu-24-with-make-and-gcc);
- [Windows 11 with Make and MinGW UCRT](#122-windows-11-with-make-and-mingw-ucrt);
- [Windows 11 with MSVS2022 and MSVC](#123-windows-11-with-msvs-2022-and-msvc).


#### 1.2.1. Ubuntu 24 With Make And GCC
Use the `UnixMakefiles_GCC` toolset.
##### 1.2.1.1. Installation Of Dependecies
To install most of build tools and dependencies (all, but Qt Installer Framework), run:
```bash
sudo apt update && sudo apt-get install -y \
  dpkg-dev \
  qt6-base-dev \
  qt6-tools-dev
```
##### 1.2.1.2. VS Code
Use the `Linux` configuration in the `C/C++ Configuration` settings.<br>
[`./.vscode/launch.json`](./../.vscode/launch.json) contains a hardcoded path to a project entrypoint-executable. Adjust it.


#### 1.2.2. Windows 11 With Make And MinGW UCRT
Use the `MinGW` toolset.
##### 1.2.2.1. Installation Of Dependecies
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6
```
##### 1.2.2.2. VS Code
Define the environment variable `MSYS2_HOME=C:\msys64`.<br>
Use the `Windows_MinGW_UCRT` configuration in the `C/C++ Configuration` settings.<br>
[`./.vscode/launch.json`](./../.vscode/launch.json) contains a hardcoded path to a project entrypoint-executable. Adjust it.


#### 1.2.3. Windows 11 With MSVS 2022 and MSVC
Use the `VS2022_MSVC` toolset.
##### 1.2.3.1. Installation Of Dependecies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.

Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
##### 1.2.3.2. VS Code
Define the environment variable `VC2022ToolsInstallDir`.<br>
E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.<br>
Use the `Windows_MSVC2022` configuration in the `C/C++ Configuration` settings.<br>
[`./.vscode/launch.json`](./../.vscode/launch.json) contains a hardcoded path to a project entrypoint-executable. Adjust it.


### 1.3. Run Project
For builds made on:
- [Ubuntu 24 with Make and GCC](#121-ubuntu-24-with-make-and-gcc);
- [Windows 11 with Make and MinGW UCRT](#122-windows-11-with-make-and-mingw-ucrt);

compiled (in `./build/`) and installed (in `./install/`) executables can be run directly, if dependencies are installed via the recommended package managers.<br>
For other configurations (e.g., [Windows 11 with MSVS2022 and MSVC](#123-windows-11-with-msvs-2022-and-msvc)), it may be required to set paths to shared libraries of the dependecies before running.<br>

CMagneto CMake function `CMagneto__set_up__project()` creates helper scripts inside `bin/` subdirectories of `./build/` and `./install/`:
- `set_env` script sets environment variables for runtime, including paths to directories with 3rd-party shared libs;
- `run` script executes a `set_env` script and the runs the project entrypoint-executable.


### 1.4. Engage Continuous Integration (CI)
Adjust values in [`./meta/CI.json`](./../meta/CI.json) before any actions with [Docker images](./../CI/Docker/) and [CI pipeline](./../CI/GitLab/pipeline.yml).

#### 1.4.1. Build Docker Images
Use [`./CMagneto/py/docker/build_image.py`](./py/docker/build_image.py) or its proxy [`./CI/Docker/build_image.py`](./../CI/Docker/build_image.py) to build [Docker images](./../CI/Docker/):
```bash
python ./build_image.py --help
```
[`./CI/Docker/`](./../CI/Docker/) contains Dockerfiles. They must be fed to [`./CMagneto/py/docker/build_image.py`](./py/docker/build_image.py) every time they are changed before triggering CI pipeline.

#### 1.4.2. GitLab
Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to \"[`CI/GitLab/pipeline.yml`](./../CI/GitLab/pipeline.yml)\".

##### 1.4.2.1. CI Triggers
The [`./CI/GitLab/pipeline.yml`](./../CI/GitLab/pipeline.yml) instructs GitLab to create a CI pipeline, if the `main` branch is involved or a tag is pushed.<br>
To create the pipeline for an untagged commit to another branch, push the commit to the branch with a message, ending with `RUN_CI_PIPELINE`.

##### 1.4.2.2. CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/packages/generic/{DockerRegistrySuffix}/{BranchName_or_Tag}/{Platform}/{toolset}/{PackageNamePrefix}-{ProjectVersion}.{PackageExtension}`,

where:
- `CI_PROJECT_ID` is a GitLab CI variable, which resolves to a number, e.g. `71534203`;
- `DockerRegistrySuffix` is defined in [`./meta/CI.json`](./../meta/CI.json);
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](./../CI/Docker/Dockerfile.Ubuntu24AMD__build) yields Platform=`Ubuntu24AMD`;
- `toolset` is the argument, passed to [`./build.py --toolset`](./py/cmake/build.py);
- `PackageNamePrefix` and `ProjectVersion` are defined in [`./meta/Packaging.json`](./../meta/Packaging.json) and [`./meta/Project.json`](./../meta/Project.json);
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in [`./CMagneto/cmake/Packager.cmake`](./cmake/Packager.cmake) and depends on platform and toolset.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-1.0.0.deb](https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-1.0.0.deb) .


## 2. Knowledge Base
This Knowledge Base serves as a centralized collection of technical notes, clarifications, code excerpts, and curated content from books, documentation, and online resources. It is designed for quick reference during development to reduce repetitive searches.

- [CMake](./doc/CMakeKnowledge.md)