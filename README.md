<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

![Framework Banner](./SeedProject/CMagneto/doc/assets/header/Header.jpg)
# CMagneto Project

[![CMagneto pipeline](https://gitlab.com/dishsoftware/cmagneto/badges/main/pipeline.svg)](https://gitlab.com/dishsoftware/cmagneto/-/pipelines)
[![Seed project coverage (downstream)](https://gitlab.com/dishsoftware/contactholder/badges/main/coverage.svg)](https://gitlab.com/dishsoftware/contactholder)

<!--
Note For Developers

Keep paragraphs of this file in sync with the same paragraphs in
- CMagneto Project root README.md;
- CMagneto Framework root README.md;
- project description on GitLab, GitHub, BitBucket etc.
-->

**CMagneto Project** is a **CMagneto Framework** and a **seed (template) project** <br>
for bootstrapping **CMake**-backed **C++** projects.<br>
It eliminates most of the repetitive setup required to start a production-ready C++ project.

**CMagneto Framework** covers the full lifecycle: <br>
project structure, tooling and build setup, <br>
third-party library deployment, legal file management, testing, packaging, and CI <br>
— all pre-configured and ready to use.<br>

🔗 GitLab repository: [gitlab.com/dishsoftware/cmagneto](https://gitlab.com/dishsoftware/cmagneto)<br>
🔗 GitHub mirror: [github.com/dishsoftware/cmagneto](https://github.com/dishsoftware/cmagneto)


## Platform Support

**CMagneto Framework** is agnostic to compilers, generators of build-system files, IDEs, and CI systems, <br>
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


## How To Use It

The **CMagneto Framework** is embedded inside the **seed (template) project**:
- [`SeedProject/`](./SeedProject/) → your starting point;
- [`SeedProject/CMagneto/`](./SeedProject/CMagneto/) → reusable framework (keep unchanged).

1. Copy content of [`./SeedProject/`](./SeedProject/) into the root of your new project.
2. Do NOT modify content of [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/) (code of **CMagneto Framework**).
3. Modify the rest of seed project's code. Start with [`./SeedProject/meta/`](./SeedProject/meta/).

👉 See detailed explanation in [**CMagneto Framework** README.md](./SeedProject/CMagneto/README.md#1-how-to-use-the-cmagneto-framework).


## Showcase

### From zero to working project (`Ubuntu 24` / `Debian 12`).

This is a minimal end-to-end example of creating and building a project using CMagneto.

```bash
# Install build tools and dependencies.
sudo apt update && sudo apt install -y \
  git \
  python3 \
  python-is-python3 \
  build-essential \
  qt6-base-dev \
  qt6-tools-dev \
  libboost-all-dev \
  zlib1g-dev \
  libgtest-dev \
  dpkg-dev \
  graphviz \
  lcov \
  wget

# Clone CMagneto Project.
git clone https://gitlab.com/dishsoftware/cmagneto.git CMagneto

# Install a newer CMake without replacing the system one,
# then activate it only in this shell.
./CMagneto/SeedProject/scripts/Linux/install_cmake_into_opt.sh 4.3.1
source ./CMagneto/SeedProject/scripts/Linux/switch_cmake_in_this_shell_instance.sh
use_cmake 4.3.1

# Copy seed project into your new project.
cp -r ./CMagneto/SeedProject ./MyApp

cd MyApp

# Build, test, package.
python ./build.py --build_variant Makefiles_GCC --build_type Release
```

### Result

- Build artifacts are generated;
- Tests are executed;
- A distributable `.deb` package is created and ready to install.

### 📁 Resulting project structure

```
MyApp/
├── CMagneto/              # Framework.
├── meta/                  # New project metadata
├── src/                   # New project code
├── tests/                 # New project native (unit and integration) and system tests
├── packaging/             # New project resources for distribution packages.
├── build/
│   └── Makefiles_GCC/
│       └── Release/       # Build output.
│           └── packages/  # Distribution package `*.deb`.
│                          # ^ Can be installed: creates an icon in Start Menu, installed application is ready to run.
├── install/
│   └── Makefiles_GCC/
│       └── Release/       # Install output.
└── build.py               # Build entry point.
```


## Structure Of The Repository

```text
<CMagneto Project root>/
├── README.md          # This document.
├── SeedProject/       # Seed (template) project root.
│   ├── CMagneto/      # CMagneto Framework root.
│   │   │              # ^ Its content is meant to be invariant and reused in all bootstrapped projects.
│   │   │
│   │   ├── README.md  # CMagneto Framework documentation entry point.
│   │   └── ...        # Other files of the CMagneto Framework.
│   │
│   └── ...            # Files of the seed (template) project itself. Meant to be modified.
│
└── ...                # Files, required only for development of the CMagneto Project.
```


## License

Look into [`License` section of **CMagneto Framework** `README.md`](./SeedProject/CMagneto/README.md#license) <br>
and into [`License` section of the **seed project** `README.md`](./SeedProject/README.md#license).<br>
[`./LICENSE`](./LICENSE) and [`./SeedProject/CMagneto/LICENSE`](./SeedProject/CMagneto/LICENSE) are identical.


## CI Validation

**CMagneto** is continuously validated against a downstream consumer project:
[**ContactHolder**](https://gitlab.com/dishsoftware/contactholder).

On each commit to **CMagneto**, CI synchronizes the content of [`./SeedProject/`](./SeedProject/) into the root of **ContactHolder** on a branch with the same name, then runs the downstream pipeline.


## Glossary

- `CMagneto Project root (dir)` - [this (`./`)](.) dir.
- `Seed project root (dir)` - [`./SeedProject/`](./SeedProject/) dir.
- In all files under the [`seed project root`](./SeedProject/), that directory itself is referred to as `project root (dir)`.
- `CMagneto Framework root (dir)` - [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/) dir.
- `Test project root (dir)` - [dir with a test project under `./tests/testProjects/`](./tests/testProjects/).
- `CMagneto Framework root (dir) of the project` in context of a test project is `./CMagneto/` subdir inside the `test project root`.
