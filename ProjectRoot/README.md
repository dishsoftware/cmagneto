*This is a seed CMake C++ project, which is distributed as a part of the CMagneto framework repository.*<br>
*The seed project features:*
- *Cross-platform development support;*
- *Modular source layout;*
- *Integrated unit testing;*
- *Integrated packaging (CPack);*
- *Docker support for reproducible environments;*
- *GitLab CI integration;*
- *Preconfigured Visual Studio Code settings.*

*Consider everything in the directory, except [`./CMagneto/`](./CMagneto/) and its contents,*<br>
*as a **ready-to-use CMake C++ project template**.*

*Look into [`How To Use The CMagneto Framework`](./CMagneto/README.md#1-how-to-use-the-cmagneto-framework) section of CMagneto doc.*

---
---
---

![Project Banner](./doc/assets/header/Header.jpg)
# Contact Holder
Open-source contact manager, that gives you full control over how, when, and where your contacts are stored and synchronized.

## License
This project is licensed under the [MIT License](./LICENSE).

### Third-party Components
- [**CMagneto**](./CMagneto/README.md) framewok is used under the terms of the [MIT License](./CMagneto/README.md#license).<br>
    The framework contains [`QtWrappers CMake Module`](./CMagneto/cmake/QtWrappers.cmake), which is based on [`Salome`](https://www.salome-platform.org/) code and licensed under the GNU LGPL 2.1 or later.<br>
    See [the file](./CMagneto/cmake/QtWrappers.cmake) header and [`GNU Lesser General Public License, version 2.1`](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).
- **Qt** is used under the terms of the GNU LGPL 3.0. See [`Qt Licensing`](https://doc.qt.io/qt-6/licensing.html) for details.
- **Boost** is used under the Boost Software License 1.0. See [`The Boost Software License`](https://www.boost.org/users/license.html).


## Documentation Conventions
The same as [CMagneto framework documentation conventions](./CMagneto/README.md#documentation-conventions)


## Code Conventions
Look into [`./doc/CodeConventions.md`](./doc/CodeConventions.md) .

---


## 1. Build
### 1.1. Build Tools
The same as in [`Project Build Tools` section the CMagneto framework doc](./CMagneto/README.md#project-build-tools).


### 1.2. Dependencies
- Qt 6
- Boost
- GoogleTest (downloaded automatically by CMake during project generation)


### 1.3. One-Command Build Script
Use [`./build.py`](./build.py) to generate build system files (e.g. MakeFiles or MSVS solution), compile, test, install the CMake project and generate installation packages.<br>
To see available options, run:
```bash
python ./build.py --help
```
The [`./build.py`](./build.py) supports multiple toolsets (pairs of a build system and a compiler). The toolsets were tested on the following platforms:
- [Ubuntu 24 with Make and GCC](#131-ubuntu-24-with-make-and-gcc) (Make and GCC);
- [Windows 11 with Make and MinGW UCRT](#132-windows-11-with-make-and-mingw-ucrt) (Make and MinGW UCRT);
- [Windows 11 with MSVS2022 and MSVC](#133-windows-11-with-msvs2022-and-msvc) (MSVS2022 and MSVC).


#### 1.3.1. Ubuntu 24 With Make And GCC
Use the `UnixMakefiles_GCC` toolset.
##### 1.3.1.1. Installation Of Dependecies
To install most of build tools and dependencies (all, but Qt Installer Framework), run:
```bash
sudo apt update && sudo apt-get install -y \
  dpkg-dev \
  qt6-base-dev \
  qt6-tools-dev \
  libboost-all-dev
```
##### 1.3.1.2. VS Code
Use the `Linux` configuration in the `C/C++ Configuration` settings.


#### 1.3.2. Windows 11 With Make And MinGW UCRT
Use the `MinGW` toolset.
##### 1.3.2.1. Installation Of Dependecies
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6 mingw-w64-ucrt-x86_64-boost-libs
```
##### 1.3.2.2. VS Code
Define the environment variable `MSYS2_HOME=C:\msys64`.<br>
Use the `Windows_MinGW_UCRT` configuration in the `C/C++ Configuration` settings.


#### 1.3.3. Windows 11 With MSVS2022 And MSVC
Use the `VS2022_MSVC` toolset.
##### 1.3.3.1. Installation Of Dependecies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.

Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.
##### 1.3.3.2. VS Code
Define the environment variable `VC2022ToolsInstallDir`.<br>
E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.<br>
Use the `Windows_MSVC2022` configuration in the `C/C++ Configuration` settings.


## 2. Run
The following helper scripts are created inside `bin/` subdirectories of `./build/` and `./install/`:
- `set_env` script sets environment variables for runtime, including paths to directories with 3rd-party shared libs;
- `run` script executes a `set_env` script and the runs the project entrypoint-executable.


## 3. Continuous Integration (CI)
### 3.1. Docker
Use [`./CI/Docker/build_image.py`](./CI/Docker/build_image.py) to build Docker images:
```bash
python ./CI/Docker/build_image.py --help
```
[`./CI/Docker/`](./CI/Docker/) contains Dockerfiles. They must be fed to [`./CI/Docker/build_image.py`](./CI/Docker/build_image.py) every time they are changed before triggering CI.

### 3.2. GitLab
#### 3.2.1. CI Triggers
The [`./CI/GitLab/pipeline.yml`](./CI/GitLab/pipeline.yml) instructs GitLab to create a CI pipeline, if the `main` branch is involved or a tag is pushed.<br>
To create the pipeline for an untagged commit to another branch, push the commit to the branch with a message, ending with `RUN_CI_PIPELINE`.

#### 3.2.2. CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/{BranchName_or_Tag}/{Platform}/{toolset}/Dish_ContactHolder-{ProjectVersion}.{PackageExtension}`,

where:
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](./CI/Docker/Dockerfile.Ubuntu24AMD__build) yields Platform=`Ubuntu24AMD`;
- `toolset` is the argument, passed to [`./build.py --toolset`](./build.py);
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in [`./packaging/CPackConfig.cmake`](./packaging/CPackConfig.cmake) and depends on platform and toolset.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-1.0.0.deb](https://gitlab.com/api/v4/projects/67161006/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-1.0.0.deb) .