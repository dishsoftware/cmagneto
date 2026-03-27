<!--
Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This file is part of the CMagneto framework.
It is licensed under the MIT license found in the LICENSE file
located at the root directory of the CMagneto framework.

By default, the CMagneto framework root resides at the root of the project where it is used,
but consumers may relocate it as needed.
-->

# Third-Party Shared Library Deployment
## 1. Purpose
This document explains how CMagneto deduces imported 3rd-party shared-library runtime dependencies and how their distribution is handled on Linux, Windows, and partially on macOS or Unix-like systems.

It also explains why CMagneto requires an explicit deployment policy for imported shared libraries instead of treating every non-bundled dependency as external automatically.


## 2. Overall flow
CMagneto splits this problem into two distinct steps:

1. deduce which imported linked targets are actual runtime shared-library dependencies;
2. classify each such dependency as either:
   - `EXPECT_ON_TARGET_MACHINE`;
   - `BUNDLE_WITH_PACKAGE`.

The policy is normally declared in Python build variants with:

- `expectExternalSharedLibrariesOnTargetMachine(...)`;
- `bundleExternalSharedLibraries(...)`.

The build runner converts that policy into `-D` CMake variables before project configuration. See:

- [`./../py/cmake/build_variant.py`](./../py/cmake/build_variant.py)
- [`./../py/cmake/build_runner.py`](./../py/cmake/build_runner.py)
- [`./../README.md`](./../README.md)


## 3. How imported shared libraries are deduced
During target setup, CMagneto inspects linked targets and keeps only imported runtime shared libraries.

The core implementation lives in:

- [`./../cmake/ThirdPartySharedLibsTools.cmake`](./../cmake/ThirdPartySharedLibsTools.cmake)
- [`./../cmake/ThirdPartySharedLibsTools_Internals.cmake`](./../cmake/ThirdPartySharedLibsTools_Internals.cmake)

The key functions are:

- `CMagnetoInternal__collect_paths_to_shared_libs`
- `CMagnetoInternal__is_imported_shared_library_target`
- `CMagnetoInternal__get_imported_shared_library_paths`
- `CMagnetoInternal__is_path_to_shared_library`

Important details:

- project-owned targets are skipped;
- imported runtime libraries are kept;
- imported targets of type `UNKNOWN_LIBRARY` are still accepted if their resolved runtime artifact is recognized as a real shared library;
- runtime paths are collected from `IMPORTED_LOCATION` and `IMPORTED_LOCATION_<CONFIG>` properties.

Platform-specific recognition is done in `CMagnetoInternal__is_path_to_shared_library`:

- Linux: `readelf` is used to recognize ELF shared objects;
- Windows: `.dll` extension is used;
- Darwin: `.dylib` extension is used.


## 4. Why explicit `EXPECT_ON_TARGET_MACHINE` exists
At first glance it may seem sufficient to list only bundled imported shared libraries and treat every other discovered shared library as external automatically.

CMagneto intentionally does not do that.

It distinguishes between:

- external by explicit design;
- external only because no deployment decision was declared.

That distinction matters because `EXPECT_ON_TARGET_MACHINE` is not just descriptive metadata. It activates concrete behavior.

If an imported shared library is explicitly classified as `EXPECT_ON_TARGET_MACHINE`, CMagneto treats it as an intentional external dependency and:

- includes it in `external_shared_library_deployment.json`;
- on Linux, appends its directory to `INSTALL_RPATH`;
- includes its directory in legacy development helpers such as `set_env` and `.env.vscode`;
- excludes it from recursive transitive bundling;
- on Linux, verifies that it remains outside the package and resolves from outside it.

If an imported shared library is not listed in either policy set, CMagneto still detects it, but does not treat it as a fully declared external dependency. It remains unclassified.

That means:

- it is not bundled directly;
- it is not exported as an intentional external dependency;
- on Linux, its directory is not appended to `INSTALL_RPATH`;
- it is omitted from policy-driven package verification.

In other words:

- `EXPECT_ON_TARGET_MACHINE` means "external by design";
- not listed means "external only by omission".

This is why CMagneto warns about linked imported shared libraries that have no install-mode decision. That warning is emitted by `CMagnetoInternal__warn_about_unclassified_external_shared_libraries`.


## 5. Linux
Linux is the most complete implementation in the framework.

### 5.1. Runtime shared-library recognition
Linux shared libraries are recognized in `CMagnetoInternal__is_path_to_shared_library` by calling `readelf -h` and checking that the ELF file type is dynamic.

SONAME-aware packaging is implemented by:

- `CMagnetoInternal__get_elf_soname`
- `CMagnetoInternal__get_installable_shared_library_path`

The reason is that the runtime loader often resolves a library by SONAME rather than by the exact path discovered during configuration.

### 5.2. Build-tree and install-tree runtime lookup
Linux runtime lookup is configured in `CMagnetoInternal__set_up_target_runtime_resolution`.

For executables:

- build tree uses collected imported-library directories and `$ORIGIN/../lib`;
- install tree uses `$ORIGIN/../lib` first, then directories of dependencies classified as `EXPECT_ON_TARGET_MACHINE`.

For shared libraries:

- build tree uses collected imported-library directories and `$ORIGIN`;
- install tree uses `$ORIGIN` first, then directories of dependencies classified as `EXPECT_ON_TARGET_MACHINE`.

This search order matters.

Bundled runtime directories must be searched before external directories. Otherwise a library that was copied into the package may still be resolved from the system instead of from the packaged copy.

### 5.3. Consequences of listing or not listing a dependency in `INSTALL_RPATH`
If a dependency is explicitly classified as `EXPECT_ON_TARGET_MACHINE`, its directory contributes to `INSTALL_RPATH`.

Consequences:

- installed binaries know where to look for that external dependency;
- runtime behavior becomes part of the binary's declared deployment design;
- the binary does not need `LD_LIBRARY_PATH` for that location.

If the dependency is not classified as `EXPECT_ON_TARGET_MACHINE`, its directory is not appended to `INSTALL_RPATH`.

Consequences:

- the installed binary may still work if the library is found in default loader locations;
- the installed binary may also fail on another machine;
- runtime behavior may depend on environment variables or distribution-specific defaults instead of explicit package design.

So on Linux, installed binaries can genuinely differ depending on whether a dependency is explicitly declared external or left unclassified.

### 5.4. Bundled shared libraries
Bundled imported shared libraries are handled by:

- `CMagneto__bundle_external_shared_libraries`
- `CMagnetoInternal__install_bundled_external_shared_libraries`

Direct bundled imported shared libraries are installed into `lib/`.

If a discovered path refers to a versioned file but a SONAME link exists, CMagneto prefers the SONAME path for packaging and also installs the real file behind the symlink chain so the package does not contain a dangling SONAME link.

### 5.5. Recursive transitive bundling
After direct bundled imported shared libraries are installed, CMagneto runs an install-time script generated by `CMagnetoInternal__install_bundled_external_shared_libraries`.

That script uses `file(GET_RUNTIME_DEPENDENCIES)` to discover runtime dependencies of already installed bundled shared libraries and copy additional needed files into the package.

This step excludes:

- imported shared libraries explicitly marked `EXPECT_ON_TARGET_MACHINE`;
- Linux system runtime libraries such as `libc.so`, `libstdc++.so`, `libpthread.so`, and similar.

### 5.6. Consequences of excluding `EXPECT_ON_TARGET_MACHINE` libraries from recursive bundling
This exclusion means that if bundled library `A` depends on library `B`, and `B` was explicitly declared `EXPECT_ON_TARGET_MACHINE`, then `B` will not be pulled into the package transitively.

Consequences:

- the package stays smaller;
- external dependencies remain external by policy;
- system- or platform-provided libraries are not accidentally vendored into the package;
- the target machine must truly provide those excluded libraries at runtime.

So `EXPECT_ON_TARGET_MACHINE` is effectively a promise:

"Do not bundle this dependency, even indirectly. The runtime environment must supply it."

### 5.7. Generated metadata
CMagneto generates two build-tree JSON files:

- `3rd_party_shared_libs.json`
- `external_shared_library_deployment.json`

The first file is diagnostic only.

The second file contains deployment-policy metadata and is consumed later by Linux package verification logic.

See also [`./LinuxPackageVerification.md`](./LinuxPackageVerification.md).

### 5.8. Debian packaging
Debian packaging additionally enables `CPACK_DEBIAN_PACKAGE_SHLIBDEPS`, which allows Debian package dependencies on system-installed shared libraries to be computed automatically.


## 6. macOS and Unix-like systems other than Linux
Support outside Linux is partial.

What exists:

- Darwin shared-library recognition in `CMagnetoInternal__is_path_to_shared_library` by `.dylib` suffix.

What does not exist yet as a CMagneto-specific deployment solution:

- `install_name` rewriting;
- `@rpath` or `@loader_path` handling;
- app-bundle fixup;
- `.dylib` bundling logic;
- macOS-specific package verification.

This limitation is visible in:

- `CMagnetoInternal__set_up_target_runtime_resolution`, which has Linux and Windows branches only;
- `CMagnetoInternal__install_bundled_external_shared_libraries`, which returns immediately for platforms other than Linux and Windows.

The legacy helper files still use `LD_LIBRARY_PATH` on non-Windows platforms, so they are generic Unix-style helpers, not a real macOS deployment implementation.

So the short version is:

- Linux: fully implemented;
- macOS and other Unix-like systems: partially recognized, not fully deployed.


## 7. Windows
Windows uses the same policy categories, but different runtime mechanics.

### 7.1. Runtime shared-library recognition
Windows runtime shared libraries are recognized in `CMagnetoInternal__is_path_to_shared_library` simply by `.dll` extension.

### 7.2. Build-tree runtime resolution
For local development, `CMagnetoInternal__set_up_target_runtime_resolution` adds a `POST_BUILD` step using `$<TARGET_RUNTIME_DLLS:...>`.

This copies runtime DLLs next to the built executable or DLL and is the main build-tree convenience mechanism on Windows.

### 7.3. Install-tree and packaged runtime layout
Bundled imported shared libraries are installed into `bin/`, not `lib/`.

Then the same install-time `file(GET_RUNTIME_DEPENDENCIES)` process is used to discover additional transitive DLL dependencies and copy them into `bin/` as well.

Windows-specific exclusions are applied for:

- `api-ms-win-*`
- `ext-ms-*`
- DLLs under `System32`
- DLLs under `SysWOW64`

This prevents Windows system DLLs from being bundled accidentally.

### 7.4. No `RPATH`-style binary configuration
Unlike Linux, Windows does not use `RPATH`.

Runtime resolution depends mainly on:

- colocated DLLs next to the executable;
- process environment such as `PATH`;
- default Windows DLL search rules.

That is why the legacy helpers `set_env.bat` and `.env.vscode` configure `Path` only for dependencies intentionally expected to be installed on the target machine.

### 7.5. Practical nuance in the SeedProject
The current SeedProject Windows build variants classify Qt as `EXPECT_ON_TARGET_MACHINE`.

So the sample project does not currently exercise bundled imported shared libraries on Windows, even though the framework code does support that path.


## 8. Not listed vs `EXPECT_ON_TARGET_MACHINE`
This distinction is central.

### 8.1. Explicit `EXPECT_ON_TARGET_MACHINE`
This means:

- the dependency is external intentionally;
- CMagneto configures platform-specific behavior around that decision;
- package verification on Linux interprets that dependency as "must stay outside the package".

### 8.2. Not listed
This means:

- CMagneto detected the dependency;
- no deployment decision was declared for it;
- it is not a supported third policy, only an undeclared state.

### 8.3. Build and packaging consequences
Usually this does not immediately fail configuration, build, install, or packaging.

But it can still have important consequences:

- installed Linux binaries may miss a required external search path in `INSTALL_RPATH`;
- helper environment files may omit the dependency directory;
- package contents and runtime behavior may rely on default loader behavior instead of explicit deployment policy;
- Linux runtime verification may still fail later if the dependency is unresolved or resolves from an unexpected place.


## 9. Is the design more explicit than necessary?
Yes, somewhat.

A simpler framework could require users to list only bundled imported shared libraries and treat every other detected imported shared library as external automatically.

CMagneto chooses a stricter model instead.

That stricter model is more verbose, but it provides:

- explicit deployment intent;
- clearer separation between deliberate external dependencies and forgotten ones;
- safer packaging behavior;
- stronger Linux package verification.


## 10. Main implementation anchors
The most relevant implementation entry points are:

- `CMagneto__expect_external_shared_libraries_on_target_machine`
- `CMagneto__bundle_external_shared_libraries`
- `CMagnetoInternal__collect_paths_to_shared_libs`
- `CMagnetoInternal__is_imported_shared_library_target`
- `CMagnetoInternal__get_imported_shared_library_paths`
- `CMagnetoInternal__set_up_target_runtime_resolution`
- `CMagnetoInternal__install_bundled_external_shared_libraries`
- `CMagnetoInternal__warn_about_unclassified_external_shared_libraries`

The main files to read are:

- [`./../cmake/ThirdPartySharedLibsTools.cmake`](./../cmake/ThirdPartySharedLibsTools.cmake)
- [`./../cmake/ThirdPartySharedLibsTools_Internals.cmake`](./../cmake/ThirdPartySharedLibsTools_Internals.cmake)
- [`./LinuxPackageVerification.md`](./LinuxPackageVerification.md)
- [`./../README.md`](./../README.md)
