# Build tools
- CMake
- C++ 17 compiler (GCC, or MinGW, or MSVC)
- Python 3.10
- Graphviz (optional)

# Dependecies
- Qt6
- Boost

## Ubuntu 24.04 GCC
`sudo apt-get install qt6-base-dev`
`sudo apt-get install libboost-all-dev`

The repo contains VS Code files, which configure intelliSense, debugging and basic tasks.
Just select "Linux" configuration among other options in "C/C++ Configuration" settings.

## Windows MinGW UCRT
MSYS2 is expected to be installed in C:/msys64.
`pacman -S mingw-w64-ucrt-x86_64-qt6`
`pacman -S mingw-w64-ucrt-x86_64-boost-libs`

The repo contains VS Code files, which configure intelliSense, debugging and basic tasks.
Select "Windows_MinGW_UCRT" configuration among other options in "C/C++ Configuration" settings.
These IDE files refer to `MSYS2_HOME` environment variable. E.g. `MSYS2_HOME=C:\msys64`.

## Windows MSVC 2022
Tested with
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (aka Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.

Define environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible binaries. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
Define environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible binaries. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.

The repo contains VS Code files, which configure intelliSense.
Select "Windows_MSVC2022" configuration among other options in "C/C++ Configuration" settings.
These IDE files refer to `VC2022ToolsInstallDir` environment variable. E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.

# How to build
`python ./build.py --help`

If target dependency graph picture is desired, Graphviz must be installed.
Output picture is generated at `./build/{platform_name}/[{build_type}]/graphviz`.
If Graphviz is installed, but there is no picture, define environment variable `GRAPHVIZ_DIR`. E.g. `GRAPHVIZ_DIR=C:\Program Files\Graphviz`.

# How to run
If the project is built using "Ubuntu 24.04 GCC" or "Windows MinGW UCRT", and all dependecies are installed using corresponding package managers,
output executables can be run without any additional steps.
Otherwise it may be required to set paths to shared libraries of the dependecies before execution.
`./cmake_modules/SetUpTargets.cmake` creates "set_env" and "run" scripts in "bin" subdirectories of ./build and ./install.
Look for `set_up__set_env__script()` and `set_up__run__script()` functions.