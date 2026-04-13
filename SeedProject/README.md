<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

*This is a seed CMake C++ project, which is distributed as a part of the CMagneto Framework repository.*<br>
*The seed project features:*
- *Cross-platform development support;*
- *Modular source layout;*
- *Integrated unit testing;*
- *Integrated packaging (CPack);*
- *Docker support for reproducible environments;*
- *GitLab CI integration;*
- *Preconfigured Visual Studio Code settings.*

*Consider everything in the directory, except [`./CMagneto/`](./CMagneto/) and its contents,*<br>
*as a **ready-to-use CMake C++ project template**.*

*Look into [`How To Use The CMagneto Framework`](./CMagneto/README.md#1-how-to-use-the-cmagneto-framework) section of CMagneto doc.*

---
---
---

![Project Banner](./doc/assets/header/Header.jpg)
# Contact Holder
Open-source contact manager, that gives you full control over how, when, and where your contacts are stored and synchronized.


## License
This project is licensed under the [MIT License](./LICENSE).

### Third-party Components
- [**CMagneto**](./CMagneto/README.md) framewok is used under the terms of the [MIT License](./CMagneto/README.md#license).<br>
    The framework contains [`QtWrappers CMake Module`](./CMagneto/cmake/QtWrappers.cmake), which is based on [`Salome`](https://www.salome-platform.org/) code and licensed under the GNU LGPL 2.1 or later.<br>
    See [the file](./CMagneto/cmake/QtWrappers.cmake) header and [`GNU Lesser General Public License, version 2.1`](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).
- [**CLI11**](https://github.com/CLIUtils/CLI11) sources are included in this repository under [`./3rdParty/sources/CLI11/`](./3rdParty/sources/CLI11/). See [its license](./3rdParty/sources/CLI11/LICENSE).
- **Qt** is used under the terms of the GNU LGPL 3.0. See [`Qt Licensing`](https://doc.qt.io/qt-6/licensing.html) for details.
- **Boost** is used under the Boost Software License 1.0. See [`The Boost Software License`](https://www.boost.org/users/license.html).
- **zlib** is used under the terms of the zlib License. See [zlib License](https://zlib.net/zlib_license.html).


## Git History Policy
The same as [CMagneto Framework Git history policy](./CMagneto/README.md#git-history-policy)


## Documentation Conventions
The same as [CMagneto Framework documentation conventions](./CMagneto/README.md#documentation-conventions)


## Code Conventions
Look into [`./doc/CodeConventions.md`](./doc/CodeConventions.md) .

---


## 1. Build
### 1.1. Build Tools
The same as in [`Project Build Tools` section the CMagneto Framework doc](./CMagneto/README.md#project-build-tools).


### 1.2. Dependencies
- Boost
- CLI11
- Qt 6
- zlib


### 1.3. Build
The [`./CMakePresets.json`](./CMakePresets.json) is the source of truth for build configuration. <br>
It is endorsed to use the one-command [`./build.py`](./build.py) script to run all build stages: from configuration of build system files to packaging and system tests. <br>
To see available options, run:
```bash
python ./build.py --help
```
For details look into [`1.3. Build Project` section the CMagneto Framework doc](./CMagneto/README.md#13-build-project).


## 2. Run
Runtime dependency policy is encoded in the active configure preset and related CMake cache variables:
- some used 3rd-party shared libraries can be marked as expected on the target machine at the same absolute locations as on the build machine;
- others can be marked as bundled into the installation package.

Thus, built/installed binaries run on the build machine, <br>
and binaries from distribution packages run on target machines without any issues.

For a details look into [`1.4. Run Project` section the CMagneto Framework doc](./CMagneto/README.md#14-run-project).

The following legacy helper scripts are also created inside `bin/` subdirectories of `./build/`:
- `set_env` prepends build-machine-specific dependency directories to the runtime environment;
- `run` executes `set_env` and then runs the project entrypoint executable.

These files are only meant to be used for experiments and tests with binaries during development.


## 3. Continuous Integration (CI)
Look into [`./CI/Docker/README.md`](./CI/Docker/README.md) and [`./CI/GitLab/README.md`](./CI/GitLab/README.md).
