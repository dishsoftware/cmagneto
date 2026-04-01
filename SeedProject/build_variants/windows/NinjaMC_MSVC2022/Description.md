Tested on Windows 11 with MSVS2022.


## Installation of Additional Build Tools
- Install `Ninja`. E.g. `winget install Ninja-build.Ninja`.


## Installation of Dependencies
Tested with:
- Qt 6.8.2. The easiest way to get it - run QtOnlineInstaller (or Qt Maintenance Tool) from https://www.qt.io/download-open-source and install "Qt/Qt 6.8.2/MSVC 2022 64-bit" component.
- Boost 1.87.0. The easiest way to get it - install from [Prebuilt windows binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) at https://www.boost.org/users/download/.
- zlib 1.3.2. The easiest way to get it - install a CMake package export that provides `ZLIBConfig.cmake`.
- GoogleTest 1.17.0 or compatible may be installed optionally for test builds. If it is not installed, `FetchContent` is used.

1. Define the environment variable `QT6_MSVC2022_DIR`, which refers to a directory with compatible Qt files. E.g. `QT6_MSVC2022_DIR=C:\Qt\6.8.2\msvc2022_64`.
2. Define the environment variable `BOOST_MSVC2022_DIR`, which refers to a directory with compatible Boost files. E.g. `BOOST_MSVC2022_DIR=C:\boost_1_87_0\lib64-msvc-14.3`.
3. Define the environment variable `ZLIB_MSVC2022_DIR`, which refers to a directory with compatible zlib files. E.g. `ZLIB_MSVC2022_DIR=C:\Data\Installs\zlib\zlib-1.3.2-install`.<br>


## MSVC environment

Using the MSVC compiler requires its environment to be set up before invoking `build.py`, `cmake`, `ctest`, or `cpack`.

### 1. Use one of MSVC-specific shells
- `x64 Native Tools Command Prompt for VS 2022`
- `Developer Command Prompt for Visual Studio 2022`
- `Developer PowerShell for Visual Studio 2022`

### 2. Load the MSVC environment into Command Prompt
```bat
vcvars64.bat
```

### 3. Load the MSVC environment into PowerShell
```powershell
.\scripts\windows\load_vcvars.ps1 "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```


## VS Code
Define the environment variable `VC2022ToolsInstallDir`.<br>
E.g. `VC2022ToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207`.<br>
It enables IntelliSense.

Launch VS Code from a shell where the MSVC environment has already been loaded so that tasks work.<br>
```powershell
code .
```

Use the `Windows_NinjaMC_MSVC` configuration in the `C/C++ Configuration` settings.<br>
