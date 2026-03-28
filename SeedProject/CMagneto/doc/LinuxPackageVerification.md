<!--
Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This file is part of the CMagneto framework.
It is licensed under the MIT license found in the LICENSE file
located at the root directory of the CMagneto framework.

By default, the CMagneto framework root resides at the root of the project where it is used,
but consumers may relocate it as needed.
-->

# Linux Package Verification
## 1. Purpose
This document describes how verification of generated Linux installation packages is implemented in the CMagneto framework and the SeedProject.

The goal is to verify that every 3rd-party shared-library dependency is deployed according to the active build-variant policy:

- some imported shared libraries are expected to be present on the target machine;
- some imported shared libraries must be bundled into the generated package.

Verification is performed after packages are generated. The generated package contents are checked, and actual runtime resolution of packaged ELF binaries is checked as well.


## 2. Terms
### 2.1. ELF
`ELF` stands for `Executable and Linkable Format`.

It is the standard Linux binary format used for:

- executables;
- shared libraries;
- object files.

When a Linux executable or shared library is inspected in this document, an ELF file is being discussed.

### 2.2. Shared library
A shared library is a binary loaded at runtime by another binary.

Typical Linux shared-library names look like:

- `libz.so`
- `libz.so.1`
- `libz.so.1.3.1`

### 2.3. SONAME
`SONAME` is the runtime name embedded into an ELF shared library.

An actual file may have one filename on disk, while the dynamic loader is instructed to look for another runtime identity. For example:

- actual file on disk: `libz.so.1.3.1`
- SONAME embedded into the ELF metadata: `libz.so.1`

At runtime, resolution is usually performed by SONAME rather than by the original full filename from the build machine.

Because of that, package verification must consider SONAME, not only raw file paths gathered during configuration.

### 2.4. `readelf`
`readelf` is a Linux tool used to inspect ELF metadata.

In this implementation, it is used to read SONAME from shared libraries.

### 2.5. `ldd`
`ldd` is a Linux tool used to show which shared libraries an ELF binary resolves at runtime, and from which filesystem paths.

In this implementation, it is used to verify whether packaged binaries resolve bundled dependencies from inside the package and externally provided dependencies from outside the package.

### 2.6. Imported shared library target
An imported shared library target is a CMake target provided by `find_package(...)` or another external package description.

Examples:

- `Qt6::Core`
- `Qt6::Widgets`
- `ZLIB::ZLIB`

These targets are not built by the project itself. They represent binaries provided from outside the project.

It should be noted that such a target is not always reported by CMake with target type `SHARED_LIBRARY`.
Some packages expose runtime shared libraries as imported targets of type `UNKNOWN_LIBRARY`.
Because of that, target type alone is insufficient when bundled and externally provided runtime dependencies are collected.


## 3. Deployment policy
The deployment policy is configured by the active build variant.

Two modes are used:

- `EXPECT_ON_TARGET_MACHINE`
- `BUNDLE_WITH_PACKAGE`

The policy is configured in Python build-variant files by helpers such as:

- `expectExternalSharedLibrariesOnTargetMachine(...)`
- `bundleExternalSharedLibraries(...)`

The policy is then passed to CMake and used during target setup.


## 4. Why a bundled dependency was added to the SeedProject
Originally, the SeedProject did not contain a real bundled 3rd-party shared-library dependency.

Because of that, only the `EXPECT_ON_TARGET_MACHINE` case could be exercised in practice. The `BUNDLE_WITH_PACKAGE` path could not be verified by a real package test.

To make the verification meaningful, `ZLIB::ZLIB` was added as a bundled imported shared-library dependency in the Linux build variant, and zlib usage was added to the GUI executable.

As a result:

- Qt remained an example of externally provided runtime dependencies;
- zlib became an example of a bundled runtime dependency.

This allowed both deployment modes to be checked by package verification.


## 5. Where the implementation lives
### 5.1. CMake side
The CMake-side logic is implemented mainly in:

- `SeedProject/CMagneto/cmake/ThirdPartySharedLibsTools_Internals.cmake`
- `SeedProject/CMagneto/cmake/SetUpProject.cmake`

The CMake side is responsible for:

- collecting imported shared-library targets linked by project targets;
- registering runtime artifact paths once per imported target, including build-type-specific variants;
- applying the deployment policy configured by the build variant;
- determining which library files are to be bundled;
- generating `runtime_dependency_manifest.json` as canonical runtime-dependency metadata;
- exposing that manifest to later runtime-related stages.

### 5.2. Python side
The Python-side verification is implemented mainly in:

- `SeedProject/CMagneto/py/cmake/build_runner.py`

The Python side is responsible for:

- reading deployment metadata generated by CMake;
- extracting generated Linux packages;
- locating packaged ELF runtime files;
- running `ldd` on packaged binaries;
- checking whether dependencies are resolved from the expected locations.

The canonical input is `runtime_dependency_manifest.json`.


## 6. Metadata generated by CMake
During project setup, a JSON file named `runtime_dependency_manifest.json` is generated into the build tree.

This file is the canonical build-tree description of runtime-dependency state.

For each imported shared-library target, the following is recorded:

- imported target name;
- install mode or `UNCLASSIFIED`;
- one or more library paths associated with that target;
- project targets that link to that imported target.

For each project target, the following is also recorded:

- resolved runtime paths for the active build type;
- linked imported shared-library targets;
- imported targets that are still unclassified.

Low-level bundling overrides are recorded as well.

This file is intended to be the shared handoff artifact between CMake configuration and later runtime-related stages.
It is consumed directly by the Python build runner after package generation.

It should be noted that recorded library paths are concrete paths discovered on the build machine.
Because of that, file names in this metadata may contain build-machine-specific minor or patch versions, for example `libQt6Core.so.6.4.2`.

This must not be interpreted as an exact target-machine version requirement.
During Linux package verification, possible runtime names are derived from these paths, including ELF `SONAME` values such as `libQt6Core.so.6`.
As a result, the verification logic is based mainly on runtime names and resolution behavior rather than on an exact build-machine patch version embedded in the JSON file.

Only imported targets that are recognized as runtime shared-library dependencies are written into this file.
Recognition is performed not only by CMake target type, but also by inspecting the resolved runtime artifact paths.

No additional JSON metadata is generated.
Linux package verification relies only on `runtime_dependency_manifest.json`.


## 7. Why SONAME-aware handling was added
If raw build-machine library paths were copied into package metadata without adjustment, incorrect files could be bundled or checked.

On Linux, a library file discovered during configuration may be:

- a linker-facing name such as `libz.so`;
- a versioned runtime file such as `libz.so.1.3.1`;
- a symlink chain ending in the file actually used for runtime loading.

At runtime, the loader typically uses SONAME, such as `libz.so.1`.

Because of that, the following behavior was added on the CMake side:

- SONAME is read from ELF shared libraries with `readelf`;
- when a bundled library has a SONAME file in the same directory, that SONAME file is preferred as the installable path.
- when that SONAME path is a symlink, the real library file behind it is packaged as well.

This was done so that:

- packaged files better match Linux runtime expectations;
- verification can match packaged runtime libraries by the names actually used by the loader.
- packaged SONAME links are not left dangling inside the generated package.


## 7.1. Why install-tree runtime search order matters
On Linux, bundling a shared library into a package is not sufficient by itself.

If the installed executable keeps an `RPATH` or `RUNPATH` that prefers externally provided library directories over the packaged `lib/` directory, the bundled library may still be ignored at runtime.

In that case:

- the package physically contains the bundled library;
- the executable still resolves the dependency from the system instead of from the package.

Because of that, Linux install-tree runtime search paths must be ordered so that the packaged runtime directory is searched before directories of dependencies expected to exist on the target machine.

For packaged executables, the bundled runtime directory is typically:

- `$ORIGIN/../lib`

For packaged shared libraries, the bundled runtime directory is typically:

- `$ORIGIN`

Only after those packaged locations should directories of externally provided dependencies be appended.


## 8. Step-by-step verification flow
### 8.1. Build-variant policy is declared
The active Linux build variant declares which imported shared libraries are:

- expected to be installed on the target machine;
- bundled with the package.

In the SeedProject:

- Qt runtime libraries are expected on the target machine;
- zlib is bundled with the package.

### 8.2. Imported shared-library targets are collected during CMake setup
When project targets are set up, imported shared-library targets linked to them are detected.

For each such imported target:

- runtime artifact paths are gathered and registered once per imported target;
- configured deployment mode is registered;
- the target is associated with the project targets that link to it.

For build configurations, build-type-specific runtime paths are also registered.

This detection is not based only on the CMake target type.
If an imported target is reported as `UNKNOWN_LIBRARY`, its resolved artifact paths are still inspected.
If the artifact is recognized as a runtime shared library, the target is treated as an imported shared-library dependency.

### 8.3. Runtime dependency manifest is generated
After targets are set up, `runtime_dependency_manifest.json` is generated.

Its purpose is to transfer deployment expectations and resolved runtime-dependency data from CMake configuration into later runtime-related logic.

No additional JSON views are generated.

### 8.4. Bundled imported shared libraries are installed together with their transitive runtime dependencies
At install and package time, imported shared libraries configured as `BUNDLE_WITH_PACKAGE` are installed first as direct bundled artifacts.

After that, runtime dependencies of those bundled imported shared libraries are discovered recursively during installation.
This step is performed from the already installed bundled library files, not only from the original direct imported target list.

Dependencies explicitly configured as `EXPECT_ON_TARGET_MACHINE` are excluded from this recursive bundling step.
Platform system runtime libraries are excluded as well.

As a result, if bundled imported shared library A depends on another shared library B and B is not represented as a separately tracked imported target, B may still be discovered and copied into the install tree as a transitive bundled runtime dependency.

### 8.5. Package generation is performed
At package stage, `cpack` generates Linux installation packages in the build tree.

Supported package formats currently checked by the verification code are:

- `.deb`
- `.tgz`
- `.tar.gz`

Artifacts created by CPack for its own internal work, such as files under `_CPack_Packages/`, are not treated as generated packages for verification purposes.

### 8.6. Generated packages are extracted
Each supported package is extracted into a temporary verification directory.

Extraction is performed as follows:

- `.deb` packages are extracted with `dpkg-deb -x`;
- tar-based packages are extracted with Python `tarfile`.

Packages that do not contain the expected runtime payload root are skipped.

### 8.7. The installed runtime root inside the package is located
The expected payload root is derived from project metadata and is expected to have the form:

`opt/<CompanyName_SHORT>/<ProjectNameBase>`

This root is treated as the runtime installation tree inside the extracted package.

### 8.8. Packaged ELF runtime files are discovered
The packaged `bin/` and `lib/` directories are scanned recursively.

Files are treated as ELF files if their leading bytes match the ELF magic number.

These ELF files are the binaries whose runtime dependencies are verified.

### 8.9. Actual runtime dependency resolution is collected
`ldd` is run for each packaged ELF file.

Its output is parsed to determine:

- the name of each resolved shared library;
- the actual filesystem path from which it was resolved.

If `ldd` reports `not found` for a required library, verification fails.

### 8.10. Candidate runtime names are derived for each declared dependency
For each imported shared-library entry from the runtime dependency manifest, a set of possible runtime names is computed.

This set may include:

- the basename of the recorded file path;
- the basename of the resolved real path if the file exists;
- SONAME read with `readelf`, if available.

This is done because runtime resolution may use a name different from the original path recorded during configuration.

### 8.11. Bundled dependencies are verified
For each imported shared library configured as `BUNDLE_WITH_PACKAGE`, two checks are performed.

First, package contents are checked:

- at least one packaged file with an expected runtime name must exist inside the extracted package.

Second, runtime resolution is checked:

- at least one resolved path reported by `ldd` for that dependency must point inside the extracted package root.

This verifies both:

- the library was physically packaged;
- the packaged binaries actually resolve that library from the packaged copy.

On Linux, a bundled dependency may appear in the package both as:

- a SONAME symlink, such as `libz.so.1`;
- the real file behind it, such as `libz.so.1.3`.

That is expected and required for correct runtime resolution.

If the bundled library is present in the package but still resolves from the system, verification must fail.
Such a result usually indicates that install-tree runtime search order is wrong.

### 8.12. Externally provided dependencies are verified
For each imported shared library configured as `EXPECT_ON_TARGET_MACHINE`, two checks are performed as well.

First, package contents are checked:

- the package must not contain files corresponding to that dependency.

Second, runtime resolution is checked:

- at least one resolved path reported by `ldd` for that dependency must point outside the extracted package root.

This verifies both:

- the dependency was not accidentally bundled;
- packaged binaries are still resolving it as an external dependency.


## 9. What exactly is proven by the verification
The verification does not merely check whether a file was copied somewhere.

The following is verified:

- whether a dependency expected to be bundled is actually present in the package;
- whether a bundled dependency is actually used from inside the package by packaged ELF binaries;
- whether a dependency expected to be external is absent from the package;
- whether an external dependency is resolved from outside the package by packaged ELF binaries;
- whether any required shared library is missing at runtime.

This makes the verification stronger than a simple directory-content check.


## 10. Why both package-content checks and `ldd` checks are needed
Only checking package contents would be insufficient.

A library file could be physically present in the package, but packaged binaries could still resolve another copy from the system.

Only checking `ldd` would also be insufficient.

A dependency could accidentally resolve from the system during verification even though the package layout is wrong or incomplete.

Therefore, both kinds of checks are performed:

- package-content checks;
- runtime-resolution checks.


## 11. Current practical example in the SeedProject
The SeedProject currently provides both policy cases:

- Qt shared libraries are treated as externally provided;
- zlib is treated as bundled.

This means that generated Linux packages are expected to show the following behavior:

- Qt runtime libraries are not copied into the package and are resolved from outside the extracted package root;
- zlib runtime libraries are copied into the package and are resolved from inside the extracted package root.


## 12. Limitations and scope
The current verification is Linux-specific in implementation.

That limitation comes from the tools and binary format being used:

- ELF inspection is performed with `readelf`;
- runtime resolution is inspected with `ldd`;
- package extraction currently supports Linux package formats only.

The deployment policy itself is not Linux-specific. The policy remains build-variant-driven and platform-independent in meaning. Only the current realization and verification described in this document are Linux-specific.


## 13. Summary
The implemented package verification pipeline can be summarized as follows:

1. A build variant declares deployment policy for imported shared libraries.
2. CMake collects imported shared-library targets linked by project targets.
3. CMake registers runtime artifact paths by imported target and generates `runtime_dependency_manifest.json`.
4. Linux packages are generated by `cpack`.
5. Supported packages are extracted.
6. Packaged ELF binaries are discovered.
7. `ldd` is used to collect actual runtime library resolution.
8. Bundled dependencies are checked for presence inside the package and for runtime resolution from inside the package.
9. Externally provided dependencies are checked for absence from the package and for runtime resolution from outside the package.

As a result, generated Linux packages are verified not only structurally, but also behaviorally with respect to shared-library deployment.
