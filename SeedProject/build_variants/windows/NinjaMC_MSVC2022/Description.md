Tested on Windows 11 with MSVS2022.


## Installation of additional Build Tools
- Install `Ninja`. E.g. `winget install Ninja-build.Ninja`.


## Installation Of Dependecies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.
- zlib 1.3.2. The easiest way to get it - install a CMake package export that provides `ZLIBConfig.cmake`.
- GoogleTest 1.17.0 or compatible may be installed optionally for test builds. If it is not installed, `FetchContent` is used.

1. Define the environment variable `VC2022ToolsInstallDir`, which refers to e.g. `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207`.<br>
2. Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
3. Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.
4. Define the environment variable `ZLIB_MSVC2022_DIR`, which refers to a directory with compatible zlib files. E.g. `ZLIB_MSVC2022_DIR=C:\Data\Installs\zlib\zlib-1.3.2-install`.<br>


## VS Code
Use the `Windows_NinjaMC_MSVC` configuration in the `C/C++ Configuration` settings.<br>
