Tested on Windows 11 with MSVS2022.


## Installation Of Dependecies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.
- zlib 1.3.2.
- GoogleTest 1.17.0 or compatible may be installed optionally for test builds. If it is not installed, `FetchContent` is used.

1. Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
2. Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.
3. Define the environment variable `ZLIB_MSVC2022_DIR`, which refers to a directory with compatible zlib files. E.g. `ZLIB_MSVC2022_DIR=C:\Data\Installs\zlib\zlib-1.3.2-install`.<br>


## VS Code
Use the `Windows_VS2022_MSVC` configuration in the `C/C++ Configuration` settings.<br>

## Shell setup
No CMagneto-specific MSVC environment variable is required for this build variant.
If you invoke `cmake` or `build.py` from a plain terminal, a Visual Studio developer shell is still the safest CLI entry point.
