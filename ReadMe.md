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
If compiled application does not run, add dll of dependencies to the same folder, as contacts_gui.exe, or add paths to dependecies to PATH variable.

The repo contains VS Code files, which configure intelliSense.
Select "Windows_MSVC2022" configuration among other options in "C/C++ Configuration" settings.
These IDE files refer to `VC2022ToolsInstallDir` environment variable. E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433`.

# How to build
`python ./build.py --help`