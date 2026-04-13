<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

![Framework Banner](./SeedProject/CMagneto/doc/assets/header/Header.jpg)
# CMagneto Project

<!--
Note For Developers

Keep paragraphs of this file in sync with the same paragraphs in
- CMagneto project root README.md;
- CMagneto framework root README.md;
- project description on GitLab, GitHub, BitBucket etc.
-->

**CMagneto project** is a **CMagneto framework** and a **seed (template) project** <br>
for bootstrapping **CMake**-backed **C++** projects.<br>

**CMagneto framework** covers the full lifecycle: <br>
project structure, tooling and build setup, <br>
third-party library deployment, legal file management, testing, packaging, and CI <br>
— all pre-configured and ready to use.<br>

🔗 GitLab repository: [gitlab.com/dishsoftware/cmagneto](https://gitlab.com/dishsoftware/cmagneto)<br>
🔗 GitHub mirror: [github.com/dishsoftware/cmagneto](https://github.com/dishsoftware/cmagneto)


## Platform Support

**CMagneto framework** is agnostic to compilers, generators of build-system files, IDEs, and CI systems, <br>
while providing out-of-the-box support for some of them.<br>

Platform-specific code is still unavoidable, though:

| Platform | Status        |
|----------|---------------|
| Linux    | ✅ Supported |
| Windows  | ✅ Supported |
| macOS    | 🕰️ Planned   |
| WASM     | 🕰️ Planned   |
| Android  | 🕰️ Planned   |


## What You Get

**Project scaffold**<br>
A ready-to-build CMake C++ project. <br>
Copy [`./SeedProject/`](./SeedProject), fill in project metadata in [`./meta/`](./SeedProject/meta) JSON files, define your build variants (preset-driven build configurations), and start coding.

**CMake convenience functions for executable/library targets**<br>
Definition helpers; source-location validation to enforce project structure and reproducible builds; generation of build stage reports and boilerplate C++ code.

**Optional CMagneto C++ libraries**<br>
Reusable code for common concerns such as logging, loading distributed resources (e.g. images and sounds), managing user settings, and Qt helpers for translations and embedded resources.

**Third-party shared library deployment**<br>
Per-build-variant policy to either bundle `.dll` / `.so` files with the package or expect them on the target machine. <br>
Automatic `RPATH` configuration on Linux. Automatic DLL copying into the build tree on Windows. Explicit override patterns for edge cases.

**Legal file management**<br>
Structured license bundle manifests and reusable license component files. <br>
Each build variant selects the right set of legal files to include in the package. Covered in [`LicenseManagement.md`](./SeedProject/CMagneto/doc/LicenseManagement.md).

**Cross-platform packaging**<br>
Integration of CPack with pre-configured Qt Installer Framework (IFW), DEB, and ZIP generators. <br>
Creation of Start Menu shortcuts on Windows. `.desktop` launchers on Linux.

**Testing pre-wired**<br>
GoogleTest configured automatically during project generation. LCOV coverage support for GCC and Clang.

**GitLab CI pipeline**<br>
Pre-configured pipeline, Dockerfiles, and a one-command Docker image builder ([`./CI/Docker/build_image.py`](./SeedProject/CI/Docker/build_image.py)).

**VS Code integration**<br>
Pre-configured workspace, tasks, and settings in [`./.vscode/`](./SeedProject/.vscode).

**Optional Python build frontend**<br>
One-command [`./build.py`](./SeedProject/build.py) script to run all build stages: from generation of build system files to packaging and system tests.

**Excellent documentation**
Easy to figure out what is going on both for protein- and silicon-based intelligence.


## Structure of the repository
- The framework code is mixed with the code of a seed (template) project under [`./SeedProject/`](./SeedProject/).
- Core files of the CMagneto framework are in [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/).

This file is a proxy for the actual [CMagneto framework README.md](./SeedProject/CMagneto/README.md).


## License
Look into [`License` section of **CMagneto framework** `README.md`](./SeedProject/CMagneto/README.md#license) <br>
and into [`License` section of the **seed project** `README.md`](./SeedProject/README.md#license).<br>
The license file [`./LICENSE`](./LICENSE) and the license file [`./SeedProject/CMagneto/LICENSE`](./SeedProject/CMagneto/LICENSE) are identical.


## Glossary
- `CMagneto project root (dir)` - [this (`./`)](.) dir.
- `Seed project root (dir)` - [`./SeedProject/`](./SeedProject/) dir.
- In all files under the [`seed project root`](./SeedProject/), that directory itself is referred to as `project root (dir)`.
- `CMagneto framework root (dir)` - [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/) dir.
- `Test project root (dir)` - [dir with a test project under `./tests/testProjects/`](./tests/testProjects/).
- `CMagneto framework root (dir) of the project` in context of a test project is `./CMagneto/` subdir inside the `test project root`.
