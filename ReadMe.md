![Project Banner](assets/header/Header.jpg)
# CMagneto. C++ Project Template with CMake

A ready-to-use CMake C++ project template, designed for cross-platform development.
The template features:
- Modular source layout
- Integrated unit testing (GoogleTest)
- Preconfigured Visual Studio Code settings
- Docker support for reproducible environments
- GitLab CI integration for automated building and packaging

## License
This project is licensed under the [MIT License](./LICENSE).

## Documentation Conventions
- Paths, names of variables and options, and their values are `highlighted` and not wrapped in quotes.
- If a path, name or value includes `a {placeholder}, wrapped in curly braces,` the `placeholder` is a required value that must be substituted.
- If `a [{placeholder}] is wrapped in square brackets`, the `placeholder` is optional.
- Always use relative paths, unless an absolute path is explicitly required.
---

# Configuration

The project is designed to be easily configurable.

The [`./meta/`](./meta/) directory contains JSON files for high-level project metadata.
Before building the project locally, adjust values in:
- [`./meta/Project.json`](./meta/Project.json)
- [`./meta/Packaging.json`](./meta/Packaging.json)

Then proceed to the [Build](#build) section.


# Build

## Build Tools
- CMake 3.28 or later
- C++ 17 (or later) compiler (GCC, MinGW, MSVC)
- Python 3.10 or later
- Graphviz (optional, for target graph)
- Qt Installer Framework 4.10 or later (optional, for packaging)

### Notes:
- If CMake target dependency graph is desired, Graphviz must be installed.
Output is located at `./build/{toolset}/[{build_type}]/graphviz/`.
If Graphviz is installed, but no image is generated, define the `GRAPHVIZ_DIR` environment variable.
Example: `GRAPHVIZ_DIR=C:\Program Files\Graphviz`.

- Add the Qt Installer Framework’s bin directory to your system `PATH`.
Example: `C:\Qt\Tools\QtInstallerFramework\4.10\bin`.

## Dependencies
- Qt 6
- Boost
- GoogleTest (downloaded automatically by CMake during project generation)

## One-Command Build Script
Use [`./build.py`](./build.py) to generate build system files (e.g. MakeFiles or MSVS solution), compile, test, install the CMake project and generate installation packages.<br>
To see available options, run:
```bash
python ./build.py --help
```
The [`./build.py`](./build.py) supports multiple toolsets (pairs of a build system and a compiler). The toolsets were tested on the following platforms:
- [Ubuntu 24](#ubuntu-24) (Make and GCC);
- [Windows 11](#windows-11-with-ucrt) (Make and MinGW UCRT);
- [Windows 11](#windows-11-with-msvs-2022-and-msvc) (MSVS2022 and MSVC).

## Ubuntu 24
Use the `UnixMakefiles_GCC` toolset.<br>

### Installation Of Dependecies
To install the required dependencies, run:
```bash
sudo apt update && sudo apt-get install -y \
  dpkg-dev \
  qt6-base-dev \
  libboost-all-dev
```
### VS Code:
Use the `Linux` configuration in the `C/C++ Configuration` settings.<br>
**Caveat:** [`./.vscode/launch.json`](./.vscode/launch.json) contains a hardcoded path to an entrypoint-executable. If you edit files in [`./meta/`](./meta/), the path may break.

## Windows 11 With UCRT
Use the `MinGWMakefiles_MinGW` toolset.<br>

### Installation Of Dependecies
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6 mingw-w64-ucrt-x86_64-boost-libs
```
### VS Code:
Define the environment variable `MSYS2_HOME=C:\msys64`.<br>
Use the `Windows_MinGW_UCRT` configuration in the `C/C++ Configuration` settings.<br>
**Caveat:** [`./.vscode/launch.json`](./.vscode/launch.json) contains a hardcoded path to an entrypoint-executable. If you edit files in [`./meta/`](./meta/), the path may break.

## Windows 11 With MSVS 2022 and MSVC
Use the `VS2022_MSVC` toolset.<br>

### Installation Of Dependecies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.

Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.

### VS Code:
Define the environment variable `VC2022ToolsInstallDir`. <br>
E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.<br>
Use the `Windows_MSVC2022` configuration in the `C/C++ Configuration` settings.<br>
**Caveat:** [`./.vscode/launch.json`](./.vscode/launch.json) contains a hardcoded path to an entrypoint-executable. If you edit files in [`./meta/`](./meta/), the path may break.


# Run
For builds made with:
- [Ubuntu 24](#ubuntu-24) (Make and GCC);
- [Windows 11](#windows-11-with-ucrt) (Make and MinGW UCRT);

compiled (in `./build/`) and installed (in `./install/`) executables can be run directly, if dependencies are installed via the recommended package managers.<br>
For other configurations (e.g., Windows MSVC 2022), it may be required to set paths to shared libraries of the dependecies before running.<br>
<br>
CMake module [`CMagneto`](./cmake/modules/CMagneto.cmake) creates helper scripts inside `bin` subdirectories of `./build/` and `./install/`:
- `set_env` script sets environment variables for runtime.
- `run` script executes the entrypoint-executable.

Look for `set_up__set_env__script()` and `set_up__run__script()` functions of the [`CMagneto`](./cmake/modules/CMagneto.cmake) CMake module.


# CI
Adjust values in [`./meta/CI.json`](./meta/CI.json) before any actions with Docker images and CI pipelines.

## Docker
Use [`./CI/Docker/build_docker_image.py`](./CI/Docker/build_docker_image.py) to build Docker images:
```bash
python ./CI/Docker/build_docker_image.py --help
```

## GitLab
- [`./CI/Docker/`](./CI/Docker/) contains Dockerfiles. These must be passed to [`./CI/Docker/build_docker_image.py`](./CI/Docker/build_docker_image.py) before triggering CI.
- Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to \"[`CI/GitLab/pipeline.yml`](./CI/GitLab/pipeline.yml)\".

### CI Triggers
The [`./CI/GitLab/pipeline.yml`](./CI/GitLab/pipeline.yml) instructs GitLab to create a CI pipeline, if the `main` branch is involved or a tag is pushed.<br>
To create the pipeline for an untagged commit to another branch, push the commit to the branch with a message, ending with `RUN_CI_PIPELINE`.

### CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/packages/generic/{DockerRegistrySuffix}/{BranchName_or_Tag}/{Platform}/{toolset}/{PackageNameBase}-{ProjectVersion}.{PackageExtension}`,

where:
- `CI_PROJECT_ID` is a GitLab CI variable, which resolves to a number, e.g. 67161006;
- `DockerRegistrySuffix` is defined in [`./meta/CI.json`](./meta/CI.json);
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](./CI/Docker/Dockerfile.Ubuntu24AMD__build) yields Platform==`Ubuntu24AMD`;
- `toolset` is the argument, passed to [`./build.py --toolset`](./build.py).
- `PackageNameBase` and `ProjectVersion` are defined in [`./meta/Packaging.json`](./meta/Packaging.json) and [`./meta/Project.json`](./meta/Project.json).
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in [`./packaging/CPackConfig.cmake`](./packaging/CPackConfig.cmake) and depends on platform and toolset.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/67161006/packages/generic/enowsw/contacts/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/EnowContacts-1.0.0.deb](https://gitlab.com/api/v4/projects/67161006/packages/generic/enowsw/contacts/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/EnowContacts-1.0.0.deb) .