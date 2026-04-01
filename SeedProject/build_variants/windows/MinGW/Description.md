Tested on Windows 11 with MinGW UCRT.


## Installation Of Dependecies
MSYS2 must be installed.<br>
To install the required dependencies, run:
```bash
pacman -S \
  mingw-w64-ucrt-x86_64-qt6 \
  mingw-w64-ucrt-x86_64-boost-libs \
  mingw-w64-ucrt-x86_64-zlib \
  mingw-w64-ucrt-x86_64-gtest
```

`mingw-w64-ucrt-x86_64-zlib` is optional. If installed, the test build uses the package directly. If not installed, CMake falls back to downloading GoogleTest during configure.<br>


## Environment
Define the environment variable `MSYS2_HOME`. E.g. `MSYS2_HOME=C:\msys64`.<br>
The MinGW preset uses this path to add `{MSYS2_HOME}\ucrt64` to `CMAKE_PREFIX_PATH`, which allows CMake to locate MSYS2 packages.<br>

## VS Code
Use the matching `Windows_MinGW_{BuildType}` configuration in the `C/C++ Configuration` settings.<br>
