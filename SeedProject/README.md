<!--
Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

*This is a seed CMake C++ project, which is distributed as a part of the CMagneto framework repository.*<br>
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
- **Qt** is used under the terms of the GNU LGPL 3.0. See [`Qt Licensing`](https://doc.qt.io/qt-6/licensing.html) for details.
- **Boost** is used under the Boost Software License 1.0. See [`The Boost Software License`](https://www.boost.org/users/license.html).


## Git History Policy
The same as [CMagneto framework Git history policy](./CMagneto/README.md#git-history-policy)


## Documentation Conventions
The same as [CMagneto framework documentation conventions](./CMagneto/README.md#documentation-conventions)


## Code Conventions
Look into [`./doc/CodeConventions.md`](./doc/CodeConventions.md) .

---


## 1. Build
### 1.1. Build Tools
The same as in [`Project Build Tools` section the CMagneto framework doc](./CMagneto/README.md#project-build-tools).


### 1.2. Dependencies
- Qt 6
- Boost


### 1.3. One-Command Build Script
Use [`./build.py`](./build.py) to generate build system files (e.g. MakeFiles or MSVS solution), compile, test, install the CMake project and generate installation packages.<br>
To see available options, run:
```bash
python ./build.py --help
```
For details look into [`1.3. Build Project` section the CMagneto framework doc](./CMagneto/README.md#13-build-project).


## 2. Run
The following helper scripts are created inside `bin/` subdirectories of `./build/` and `./install/`:
- `set_env` script sets environment variables for runtime, including paths to directories with 3rd-party shared libs;
- `run` script executes a `set_env` script and the runs the project entrypoint-executable.


## 3. Continuous Integration (CI)
### 3.1. Docker
Use [`./CI/Docker/build_image.py`](./CI/Docker/build_image.py) to build Docker images:
```bash
python ./CI/Docker/build_image.py --help
```
[`./CI/Docker/`](./CI/Docker/) contains Dockerfiles. They must be fed to [`./CI/Docker/build_image.py`](./CI/Docker/build_image.py) every time they are changed before triggering CI.

### 3.2. GitLab
#### 3.2.1. CI Triggers
The [`./CI/GitLab/workflow.yml`](./CI/GitLab/workflow.yml) instructs GitLab to trigger (create) a CI pipeline, if the `main` branch is involved or a tag is pushed.<br>
To trigger a pipeline for an untagged commit to another branch, push the commit to the branch with a message, ending with `RUN_CI_PIPELINE`.

#### 3.2.2. CI Artifact Output
Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/{BranchName_or_Tag}/{Platform}/{toolset}/Dish_ContactHolder-{ProjectVersion}.{PackageExtension}`,

where:
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](./CI/Docker/Dockerfile.Ubuntu24AMD__build) yields Platform=`Ubuntu24AMD`;
- `toolset` is the argument, passed to [`./build.py --toolset`](./build.py);
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in [`./packaging/CPackConfig.cmake`](./packaging/CPackConfig.cmake) and depends on platform and toolset.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-0.0.1.deb](https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/UnixMakefiles_GCC/Dish_ContactHolder-0.0.1.deb) .