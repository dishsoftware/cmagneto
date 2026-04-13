<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This file is part of the CMagneto Framework.
It is licensed under the MIT license found in the LICENSE file
located at the root directory of the CMagneto Framework.

By default, the CMagneto Framework root resides at the root of the project where it is used,
but consumers may relocate it as needed.
-->

# License Management

> **Note:** Paths in this document are shown relative to the project root.

This document describes the `SeedProject` license management system driven by
[`./CMagneto/cmake/LicenseManager.cmake`](./../cmake/LicenseManager.cmake).

The system has one purpose:
- define which legal files belong to a distributable artifact;
- install those files into the final install tree;
- package the same files through CPack using the same `install()` rules.

The canonical installed layout is always the `licenses/` tree inside the target
installation directory.


## 1. Concepts

The system uses three layers:

1. Source files
    Real `LICENSE`, `NOTICE`, `copyright`, or similar files.

2. License components
    Reusable JSON manifests under [`./licenses/components/`](./../../licenses/components/)
    that describe one logical dependency or legal unit.

3. License bundles
    JSON manifests under [`./licenses/bundles/`](./../../licenses/bundles/)
    that select the components to install/package for a concrete build variant or
    distribution profile.


## 2. Directory Layout

```text
SeedProject/
├── LICENSE
├── licenses/
│   ├── 3rd-party/
│   │   └── ...
│   ├── bundles/
│   │   ├── default.json
│   │   ├── mingw-msys2-ucrt64.json
│   │   ├── msvc2022.json
│   │   └── linux-gcc.json
│   └── components/
│       ├── seedproject.json
│       ├── cmagneto.json
│       └── ...
└── build_variants/
    └── ...
```

Recommended meaning of the directories:
- [`./licenses/components/`](./../../licenses/components/) contains reusable component manifests.
- [`./licenses/bundles/`](./../../licenses/bundles/) contains bundle manifests selected by build variants.
- [`./licenses/3rd-party/`](./../../licenses/3rd-party/) can store checked-in legal files that belong to redistributed third-party dependencies.

The project's own canonical license source may still live at the repo root as
[`./LICENSE`](./../../LICENSE). It does not need to be duplicated under `./licenses/`.


## 3. Component Manifest Format

Each component manifest is a JSON file under [`./licenses/components/`](./../../licenses/components/).

Example:

```json
{
    "id": "seedproject",
    "name": "SeedProject",
    "notes": "Primary project license shipped with every distributable package.",
    "files": [
        {
            "kind": "license",
            "source": "LICENSE",
            "install": "licenses/ProjectLicense.txt"
        }
    ]
}
```

Supported top-level fields currently used by the system:
- `id`: stable identifier of the component.
- `name`: human-readable name.
- `notes`: optional maintainer note.
- `files`: array of files to install/package.

Each file entry supports:
- `kind`: informational label such as `license` or `notice`.
- `source`: source path of the file.
- `install`: destination path relative to the install root.

### 3.1. `source`

`source` may be:
- a path relative to the project root, for example:
  - `LICENSE`
  - `CMagneto/LICENSE`
  - `licenses/3rd-party/somelib/LICENSE.txt`
- an absolute path;
- a path containing `$env{...}` tokens, for example:
  - `$env{MSYS2_HOME}/ucrt64/share/licenses/qt6-base/LGPL-3.0-only.txt`

If a referenced environment variable is missing, configuration fails.

### 3.2. `install`

`install` must be a relative path inside the final install tree.

Typical values:
- `licenses/ProjectLicense.txt`
- `licenses/3rd-party/CMagneto/LICENSE.txt`
- `licenses/3rd-party/Qt6-base/LGPL-3.0-only.txt`

The path is normalized and must stay inside the install tree.


## 4. Bundle Manifest Format

Each bundle manifest is a JSON file under [`./licenses/bundles/`](./../../licenses/bundles/).

Example:

```json
{
    "id": "mingw-msys2-ucrt64",
    "name": "Distribution bundle for the MinGW build variant with MSYS2 UCRT64",
    "components": [
        "seedproject",
        "cmagneto",
        "qt6-base-msys2-ucrt64",
        "zlib-msys2-ucrt64"
    ]
}
```

Supported fields:
- `id`: stable identifier of the bundle.
- `name`: human-readable name.
- `components`: array of component manifest references.

Each component reference is resolved relative to
[`./licenses/components/`](./../../licenses/components/).
The `.json` suffix may be omitted.


## 5. Selecting a Bundle

The active bundle is controlled by the CMake cache variable:

`CMagneto__LICENSE_BUNDLE`

It is resolved relative to [`./licenses/bundles/`](./../../licenses/bundles/).

Default value:

```cmake
set(CMagneto__LICENSE_BUNDLE "default" CACHE STRING ...)
```

The intended workflow is to set the value in a build variant preset.

Example from a build variant:

```json
{
  "cacheVariables": {
    "CMagneto__LICENSE_BUNDLE": "mingw-msys2-ucrt64"
  }
}
```

Current examples:
- `MinGW` -> `mingw-msys2-ucrt64`
- `Ninja_MSVC2022` -> `msvc2022`
- `VS2022_MSVC` -> `msvc2022`
- `Makefiles_GCC` -> `linux-gcc`


## 6. What CMake Does With the Bundle

[`CMagneto__set_up__license_bundle_installation()`](./../cmake/LicenseManager.cmake)
is called from project setup when the project is the top-level one.

The function:
1. resolves the selected bundle manifest;
2. resolves each referenced component manifest;
3. validates every `source` path;
4. registers `install(FILES ...)` rules for each file entry;
5. exports resolved bundle file metadata for packager-specific consumers.

Because the system uses `install(FILES ...)`, the same bundle drives both:
- plain `cmake --install`;
- CPack package generation.

This means the install tree and the packaged tree stay aligned.


## 7. Installed Layout

Assume the selected bundle contains:
- `seedproject`
- `cmagneto`
- `qt6-base-msys2-ucrt64`
- `zlib-msys2-ucrt64`

Then the installed product may contain:

```text
licenses/
├── ProjectLicense.txt
└── 3rd-party/
    ├── CMagneto/
    │   └── LICENSE.txt
    ├── Qt6-base/
    │   ├── LGPL-3.0-only.txt
    │   └── Qt-GPL-exception-1.0.txt
    └── ZLib/
        └── LICENSE.txt
```

This tree is the canonical runtime-facing output of the system.
If application code needs to read legal files, it should refer to this installed tree.


## 8. Adding a New Dependency

To add legal files for a newly redistributed dependency:

1. Decide where the source legal files come from.
   Options:
   - checked into the repository;
   - vendored inside the repository;
   - external path provided by an environment variable.

2. Create a component manifest in [`./licenses/components/`](./../../licenses/components/).

3. Add one or more file entries with the desired final `install` paths under `licenses/`.

4. Add the component id to one or more bundle manifests in [`./licenses/bundles/`](./../../licenses/bundles/).

5. Select that bundle from the appropriate build variant preset if needed.

6. Reconfigure the project and verify the generated install tree or package contents.

Example component:

```json
{
    "id": "somelib",
    "name": "Some Library",
    "notes": "Bundled with proprietary Windows packages.",
    "files": [
        {
            "kind": "license",
            "source": "vendor/somelib/LICENSE.txt",
            "install": "licenses/3rd-party/somelib/LICENSE.txt"
        },
        {
            "kind": "notice",
            "source": "vendor/somelib/NOTICE.txt",
            "install": "licenses/3rd-party/somelib/NOTICE.txt"
        }
    ]
}
```


## 9. Recommended Conventions

- Keep the repo root [`./LICENSE`](./../../LICENSE) as the canonical source of the project's own license text.
- Preserve a stable installed layout under `licenses/` even if source legal files come from different places.
- Prefer one component per redistributed dependency or logical legal unit.
- Put only redistributed or embedded legal materials into bundles for a shipped artifact.
- Do not treat the license system as a legal decision engine; it is a structured way to declare and ship legal files.


## 10. Notes About IFW

The license bundle is packager-agnostic.

Packager-specific adaptations, such as Qt IFW display logic, belong in the
corresponding packager submodules under
[`./CMagneto/cmake/Packager/`](./../cmake/Packager/).

The canonical source of truth remains the installed `licenses/` tree produced by
the bundle.
