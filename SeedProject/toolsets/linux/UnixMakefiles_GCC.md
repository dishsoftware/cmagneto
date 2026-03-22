Tested on Ubuntu 24.


## Installation Of Dependecies
To install most of build tools and dependencies (all, but Qt Installer Framework), run:
```bash
sudo apt update && sudo apt install -y \
  dpkg-dev \
  qt6-base-dev \
  qt6-tools-dev \
  libboost-all-dev \
  lcov
```


## VS Code
Use the `Linux` configuration in the `C/C++ Configuration` settings.<br>
[`./.vscode/launch.json`](./../../.vscode/launch.json) contains a hardcoded path to a project entrypoint-executable. Adjust it.