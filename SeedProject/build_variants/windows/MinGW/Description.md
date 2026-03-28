Tested on Windows 11 with MinGW UCRT.


## Installation Of Dependecies
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6 mingw-w64-ucrt-x86_64-boost-libs mingw-w64-ucrt-x86_64-zlib
```

Optional:
```bash
pacman -S mingw-w64-ucrt-x86_64-gtest
```
If installed, the test build uses the MSYS2 GTest package directly. If not installed, CMake falls back to downloading GoogleTest during configure.<br>


## VS Code
Use the `Windows_MinGW` configuration in the `C/C++ Configuration` settings.<br>

## Environment
Define the environment variable `MSYS2_HOME`. E.g. `MSYS2_HOME=C:\msys64`.<br>
The MinGW build variant uses this path to add `C:\msys64\ucrt64` to `CMAKE_PREFIX_PATH`, which allows CMake to locate MSYS2 packages such as Qt6, Boost, and zlib.<br>
