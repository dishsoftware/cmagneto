Tested on Ubuntu 24.


## Installation Of Dependecies
To install most of build tools and dependencies (all, but Qt Installer Framework), run:
```bash
sudo apt update && sudo apt install -y \
  dpkg-dev \
  qt6-base-dev \
  qt6-tools-dev \
  libboost-all-dev \
  zlib1g-dev \
  libgtest-dev \
  lcov
```

`libgtest-dev` is optional. If installed, the test build uses the package directly. If not installed, CMake falls back to downloading GoogleTest during configure.<br>


## VS Code
Use the `Linux_GCC` configuration in the `C/C++ Configuration` settings.<br>
