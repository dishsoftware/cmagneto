Tested on Windows 11 with MinGW UCRT.


## Installation Of Dependecies
MSYS2 is expected to be installed in `C:/msys64`.<br>
To install the required dependencies, run:
```bash
pacman -S mingw-w64-ucrt-x86_64-qt6 mingw-w64-ucrt-x86_64-boost-libs
```


## VS Code
Use the `Windows_MinGW` configuration in the `C/C++ Configuration` settings.<br>

### Optional
The following actions are only required to set up fallback IDE IntelliSence options.
* Define the environment variable `MSYS2_HOME`. E.g. `MSYS2_HOME=C:\msys64`.<br>