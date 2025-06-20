![Project Banner](assets/header/Header.jpg)
# CMagneto. C++ Project Template with CMake

A ready-to-use C++ project template powered by CMake, designed for cross-platform development.
This template features:
- Modular source layout
- Integrated unit testing (GoogleTest)
- Preconfigured Visual Studio Code settings
- Docker support for reproducible environments
- GitLab CI integration for automated building and packaging

## License
This project is licensed under the [MIT License](LICENSE).
---

# Configuration

The project is designed to be easily configurable.

The `./meta/` directory contains JSON files for high-level project metadata.
Before building the project locally, adjust values in:
- `./meta/Project.json`
- `./meta/Packaging.json`

Then proceed to the [Build](#build) section.


# Build
To see available options, run:
```bash
python ./build.py --help
```

## Build Tools
- CMake 3.28 or later
- C++ 17 (or later) compiler (GCC, MinGW, MSVC)
- Python 3.10 or later
- Graphviz (optional, for target graph)
- Qt Installer Framework 4.10 or later (optional, for packaging)

### Notes:
- If CMake target dependency graph is desired, Graphviz must be installed.
Output is located at `./build/{toolset}/[{build_type}]/graphviz/`.
If Graphviz is installed but no image is generated, define the `GRAPHVIZ_DIR` environment variable.
Example: `GRAPHVIZ_DIR=C:\Program Files\Graphviz`.

- Add the Qt Installer Framework’s bin directory to your system `PATH`.
Example: `C:\Qt\Tools\QtInstallerFramework\4.10\bin`.

## Dependencies
- Qt 6
- Boost
- GoogleTest (downloaded automatically by CMake during project generation)

## Ubuntu 24 GCC
Use the `UnixMakefiles_GCC` toolset.<br>
To install the required dependencies, run:
```bash
sudo apt update && sudo apt-get install -y \
  dpkg-dev \
  qt6-base-dev \
  libboost-all-dev
```
### VS Code:
Use the `Linux` configuration in the "C/C++ Configuration" settings.<br>
**Caveat:** `.vscode/launch.json` contains a hardcoded path to an entrypoint-executable. If you edit files in `./meta/`, the path may break.

## Windows MinGW UCRT
Use the `MinGWMakefiles_MinGW` toolset.<br>
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6 mingw-w64-ucrt-x86_64-boost-libs
```
### VS Code:
Define the environment variable `MSYS2_HOME=C:\msys64`.<br>
Use the `Windows_MinGW_UCRT` configuration in the "C/C++ Configuration" settings.<br>
**Caveat:** `.vscode/launch.json` contains a hardcoded path to an entrypoint-executable. If you edit files in `./meta/`, the path may break.

## Windows MSVC 2022
Use the `VS2022_MSVC` toolset.<br>
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.

Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.

### VS Code:
Define the environment variable `VC2022ToolsInstallDir`. <br>
E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.<br>
Use the `Windows_MSVC2022` configuration in the "C/C++ Configuration" settings.<br>
**Caveat:** `.vscode/launch.json` contains a hardcoded path to an entrypoint-executable. If you edit files in `./meta/`, the path may break.


# Run
If the project is built using "Ubuntu 24.04 GCC" or "Windows MinGW UCRT", and all dependecies are installed using corresponding package managers,
output executables can be run without any additional steps.
Otherwise it may be required to set paths to shared libraries of the dependecies before execution.
`./cmake/modules/SetUpTargets.cmake` creates "set_env" and "run" scripts in "bin" subdirectories of ./build and ./install.
Look for `set_up__set_env__script()` and `set_up__run__script()` functions.

For builds made with:
- Ubuntu 24 GCC
- Windows MinGW UCRT

If project dependencies are installed via the recommended package managers, executables can be run directly.<br>
For other configurations (e.g., Windows MSVC 2022), it may be required to set paths to shared libraries of the dependecies before running.<br>
<br>
CMake module `CMagneto` creates helper scripts inside "bin" subdirectories of ./build and ./install:
- `set_env` script sets environment variables for runtime.
- `run` script executes the entrypoint-executable.

Look for `set_up__set_env__script()` and `set_up__run__script()` functions of the `CMagneto` CMake module.


# CI
Adjust values in `./meta/CI.json` before any actions with Docker images and CI pipelines.

## Docker
Build Docker images:
```bash
python ./CI/Docker/build_docker_image.py --help
```

## GitLab
- `./CI/Docker/` contains Dockerfiles. These must be passed to `./CI/Docker/build_docker_image.py` before triggering CI.
- Go to GitLab_Project_Page → Settings → CI/CD → General Pipelines and set "CI/CD configuration file" to `CI/GitLab/pipeline.yml`.

### CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/packages/generic/{DockerRegistrySuffix}/{BranchName_or_Tag}/{Platform}/{toolset}/{PackageNameBase}-{ProjectVersion}.{PackageExtension}`,

where:
- `CI_PROJECT_ID` is a GitLab CI variable, which resolves to a number, e.g. 67161006;
- `DockerRegistrySuffix` is defined in `./meta/CI.json`;
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. `Dockerfile.Debian12AMD__build` yields Platform==`Debian12AMD`;
- `toolset` is the argument, passed to `./build.py --toolset`.
- `PackageNameBase` and `ProjectVersion` are defined in `./meta/Packaging.json` and `./meta/Project.json`.
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in `./packaging/CPackConfig.cmake` and depends on platform and toolset.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/67161006/packages/generic/enowsw/contacts/v1.0.0/Debian12AMD/UnixMakefiles_GCC/EnowContacts-1.0.0.deb](https://gitlab.com/api/v4/projects/67161006/packages/generic/enowsw/contacts/v1.0.0/Debian12AMD/UnixMakefiles_GCC/EnowContacts-1.0.0.deb) .

### CI Triggers
CI pipeline is created, if "main" branch is involved or tag is pushed.<br>
To run the GitLab CI pipeline for other branch, push a commit to the branch with a message, ending with `RUN_CI_PIPELINE`.