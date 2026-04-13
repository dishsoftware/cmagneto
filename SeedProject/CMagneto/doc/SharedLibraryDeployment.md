<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This file is part of the CMagneto Framework.
It is licensed under the MIT license found in the LICENSE file
located at the root directory of the CMagneto Framework.

By default, the CMagneto Framework root resides at the root of the project where it is used,
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

The policy is now declared directly in build-variant presets through CMake cache variables such as:

- `CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE`;
- `CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE`.

Low-level bundling overrides can also be declared in presets with:

- `CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILES`;
- `CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS`;
- `CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILES`;
- `CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS`.

See:

- [`./../../build_variants/`](./../../build_variants/)
- [`./../README.md`](./../README.md)

After all project targets are set up, a canonical build-tree artifact named
`runtime_dependency_manifest.json` is generated.

That manifest records:

- imported shared-library targets;
- their install-mode decisions;
- resolved runtime artifact paths;
- project targets that link them;
- low-level bundling overrides.

Runtime setup, helper scripts, and package verification are then
driven from that manifest-oriented query layer.

### 2.1. Runtime-resolution strategy
Runtime dependency policy and runtime-resolution strategy are separate concerns.

The deployment policy answers:

- which imported shared libraries are expected on the target machine;
- which imported shared libraries must be bundled.

The runtime-resolution strategy answers:

- how build-tree runtime lookup is expressed on the current platform;
- whether runtime behavior is configured through target properties or through target-local build steps;
- whether the configuration may be applied later from a central directory scope or must be attached in the target's own directory.

The current internal strategy mapping is:

- `EMBEDDED_RUNTIME_PATHS` on Linux;
- `TARGET_LOCAL_RUNTIME_FILES` on Windows;
- `NONE` on platforms for which no dedicated runtime-resolution implementation exists yet.

This distinction is important because a platform may expose some analogue of runtime search metadata, but the framework still needs a concrete strategy that matches both:

- the platform loader model;
- the way CMake allows that model to be configured.

In other words, a capability such as "the platform has something RPATH-like" is not sufficient by itself. A chosen strategy is still required.


## 3. How imported shared libraries are deduced
During target setup, linked libraries are inspected and only imported runtime shared libraries are kept.

The core implementation lives in:

- [`./../cmake/ThirdPartySharedLibsTools.cmake`](./../cmake/ThirdPartySharedLibsTools.cmake)
- [`./../cmake/ThirdPartySharedLibsTools_Internals.cmake`](./../cmake/ThirdPartySharedLibsTools_Internals.cmake)

The key functions are:

- `CMagnetoInternal__register_linked_imported_shared_library_targets`
- `CMagnetoInternal__is_imported_shared_library_target`
- `CMagnetoInternal__get_imported_shared_library_paths`
- `CMagnetoInternal__get_imported_shared_library_paths_for_build_type`
- `CMagnetoInternal__is_path_to_shared_library`

Important details:

- project-owned targets are skipped;
- imported runtime libraries are kept;
- imported targets of type `UNKNOWN_LIBRARY` are still accepted if their resolved runtime artifact is recognized as a real shared library;
- runtime paths are collected from `IMPORTED_LOCATION` and `IMPORTED_LOCATION_<CONFIG>` properties;
- runtime paths are registered once per imported target, including build-type-specific variants;
- only the relationship `project target -> linked imported targets` is stored per project target.

A per-project-target cache of shared-library paths is not used.
Target-level path lists are reconstructed from linked imported targets and their centrally
registered runtime artifact paths.

Platform-specific recognition is done in `CMagnetoInternal__is_path_to_shared_library`:

- Linux: `readelf` is used to recognize ELF shared objects;
- Windows: `.dll` extension is used for direct runtime artifacts, and GNU import libraries such as `*.dll.a` may also be translated to their sibling runtime DLLs;
- Darwin: `.dylib` extension is used.


## 4. Why explicit `EXPECT_ON_TARGET_MACHINE` exists
At first glance it may seem sufficient to list only bundled imported shared libraries and treat every other discovered shared library as external automatically.

CMagneto intentionally does not do that.

It distinguishes between:

- external by explicit design;
- external only because no deployment decision was declared.

That distinction matters because `EXPECT_ON_TARGET_MACHINE` is not just descriptive metadata. It activates concrete behavior.

If an imported shared library is explicitly classified as `EXPECT_ON_TARGET_MACHINE`, CMagneto treats it as an intentional external dependency and:

- records that decision in `runtime_dependency_manifest.json`;
- on Linux, appends its directory to `INSTALL_RPATH`;
- includes its directory in helper scripts such as `set_env` and `.env.vscode`;
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

This is why CMagneto warns about linked imported shared libraries that have no install-mode decision.
That warning is emitted through the runtime dependency manifest query layer by `CMagnetoInternal__runtime_dependency_manifest__warn_about_target_unclassified_imported_targets`.


## 5. Linux
Linux is the most complete implementation in the framework.

### 5.0. Low-level bundling overrides
The target-based policy remains the primary mechanism.

CMagneto also supports a companion low-level override layer for cases where runtime artifacts are not represented cleanly by imported shared-library targets.

The public entry points are:

- `CMagneto__bundle_runtime_dependency_files`
- `CMagneto__bundle_runtime_dependency_file_patterns`
- `CMagneto__exclude_bundled_runtime_dependency_files`
- `CMagneto__exclude_bundled_runtime_dependency_file_patterns`

The corresponding preset cache variables are:

- `CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILES`
- `CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS`
- `CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILES`
- `CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS`

These overrides are intended for:

- plugin files;
- helper shared libraries not exposed as imported targets;
- package-manager quirks;
- explicit exclusion of wrongly discovered runtime dependencies.

### 5.0.1. Precedence rules
When low-level bundling overrides are used together with the normal target-based policy, CMagneto applies them in the following practical order:

1. target-based bundled imported shared libraries are collected;
2. explicit include files are added;
3. explicit include file patterns are expanded and added;
4. explicit exclude files and explicit exclude file patterns are applied to the resulting bundled file set;
5. recursive transitive runtime dependency discovery is performed for the installed bundled files;
6. dependencies expected on the target machine remain excluded from recursive bundling;
7. built-in platform safety exclusions remain applied, such as Linux system-runtime exclusions or Windows system-DLL exclusions, unless an explicit user include override says otherwise;
8. explicit exclude files and explicit exclude file patterns are applied again to the transitive dependency results before they are copied.

As a result:

- explicit exclude rules win over explicit include rules;
- low-level include rules can add extra runtime artifacts that target-based deduction did not discover directly;
- low-level include rules can also override framework-default Linux system-runtime exclusions during transitive runtime dependency bundling;
- low-level exclude rules can suppress both directly bundled files and transitively discovered runtime dependencies.

### 5.1. Runtime shared-library recognition
Linux shared libraries are recognized in `CMagnetoInternal__is_path_to_shared_library` by calling `readelf -h` and checking that the ELF file type is dynamic.

SONAME-aware packaging is implemented by:

- `CMagnetoInternal__get_elf_soname`
- `CMagnetoInternal__get_installable_shared_library_path`

The reason is that the runtime loader often resolves a library by SONAME rather than by the exact path discovered during configuration.

### 5.2. Build-tree and install-tree runtime lookup
On Linux, the selected runtime-resolution strategy is `EMBEDDED_RUNTIME_PATHS`.

Linux runtime lookup is configured in `CMagnetoInternal__set_up_target_runtime_resolution`.
The required imported-library directories are queried through the runtime dependency manifest layer.

For executables:

- build tree uses collected imported-library directories and `$ORIGIN/../lib`;
- install tree uses `$ORIGIN/../lib` first, then directories of dependencies classified as `EXPECT_ON_TARGET_MACHINE`.

For shared libraries:

- build tree uses collected imported-library directories and `$ORIGIN`;
- install tree uses `$ORIGIN` first, then directories of dependencies classified as `EXPECT_ON_TARGET_MACHINE`.

This search order matters.

Bundled runtime directories must be searched before external directories. Otherwise a library that was copied into the package may still be resolved from the system instead of from the packaged copy.

This strategy is expressed through target properties such as `BUILD_RPATH` and `INSTALL_RPATH`.
Because those properties may be adjusted after targets have already been created, the Linux runtime-resolution pass may be applied later from the higher-level project setup.

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

Low-level overrides are applied in the same install step:

- explicit include files are added to the bundled source set;
- include file patterns are expanded against known imported-library directories and added to the bundled source set;
- explicit exclude files and exclude file masks are applied to the final bundled file set before installation.

If a discovered path refers to a versioned file but a SONAME link exists, CMagneto prefers the SONAME path for packaging and also installs the real file behind the symlink chain so the package does not contain a dangling SONAME link.

### 5.5. Recursive transitive bundling
After direct bundled imported shared libraries are installed, CMagneto runs an install-time script generated by `CMagnetoInternal__install_bundled_external_shared_libraries`.

That script uses `file(GET_RUNTIME_DEPENDENCIES)` to discover runtime dependencies of already installed bundled shared libraries and copy additional needed files into the package.

This step excludes:

- imported shared libraries explicitly marked `EXPECT_ON_TARGET_MACHINE`;
- Linux system runtime libraries such as `libc.so`, `libstdc++.so`, `libpthread.so`, and similar.

After transitive dependency discovery, user-provided exclude-file and exclude-pattern overrides are also applied before additional runtime files are copied into the package.

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
CMagneto generates one build-tree JSON file:

- `runtime_dependency_manifest.json`

`runtime_dependency_manifest.json` is the canonical runtime-dependency artifact.

It records:

- imported shared libraries and their install modes;
- project targets and the imported targets linked by them;
- resolved runtime paths for the active build type;
- low-level bundling overrides.

The file is used directly or indirectly by:

- Linux runtime setup;
- helper-script generation such as `set_env` and `.env.vscode`;
- Linux package verification.

Only `runtime_dependency_manifest.json` is intended to be treated as the source of truth.

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

- `CMagnetoInternal__get_runtime_resolution_strategy`, which currently returns `NONE` outside Linux and Windows;
- `CMagnetoInternal__set_up_target_runtime_resolution`, which only has concrete behavior for the Linux and Windows strategies;
- `CMagnetoInternal__install_bundled_external_shared_libraries`, which returns immediately for platforms other than Linux and Windows.

The helper files still use `LD_LIBRARY_PATH` on non-Windows platforms, so they are generic Unix-style helpers, not a real macOS deployment implementation.

So the short version is:

- Linux: fully implemented;
- macOS and other Unix-like systems: partially recognized, not fully deployed.


## 7. Windows
Windows uses the same policy categories, but different runtime mechanics.

### 7.1. Runtime shared-library recognition
Windows runtime shared libraries are recognized in `CMagnetoInternal__is_path_to_shared_library` by `.dll` extension.

In addition, `CMagnetoInternal__get_runtime_shared_library_path_for_imported_artifact` resolves GNU import libraries such as `libz.dll.a` to their actual runtime DLLs. This is needed because some Windows package-manager integrations expose imported targets through import libraries rather than directly through DLL paths.

### 7.2. Build-tree runtime resolution
On Windows, the selected runtime-resolution strategy is `TARGET_LOCAL_RUNTIME_FILES`.

For local development, `CMagnetoInternal__set_up_target_runtime_resolution` adds a `POST_BUILD` step using `$<TARGET_RUNTIME_DLLS:...>`.

This copies runtime DLLs next to the built executable or DLL and is the main build-tree convenience mechanism on Windows.

When imported shared-library runtime paths are already known through the manifest-oriented query layer, those resolved runtime DLL paths are copied as an additional build-tree convenience step as well. This covers imported targets whose runtime DLLs are not surfaced through `$<TARGET_RUNTIME_DLLS:...>` alone.

This strategy is not expressed through `RPATH`-style target properties. It is expressed by attaching a target-local build rule.

That distinction matters in CMake:

- target properties such as `BUILD_RPATH` and `INSTALL_RPATH` may be adjusted later from a central directory scope;
- `add_custom_command(TARGET ... POST_BUILD ...)` must be called from the same directory in which the target was created.

Because of that, Windows runtime-resolution setup is attached during target setup in the target's own `CMakeLists.txt` directory, while Linux runtime-resolution setup may be applied later from `CMagneto__set_up__project()`.

### 7.3. Install-tree and packaged runtime layout
Bundled imported shared libraries are installed into `bin/`, not `lib/`.

Then the same install-time `file(GET_RUNTIME_DEPENDENCIES)` process is used to discover additional transitive DLL dependencies and copy them into `bin/` as well.

On Windows, unresolved transitive DLL names reported by `file(GET_RUNTIME_DEPENDENCIES)` are currently downgraded to warnings during this install-time transitive step. This is done because optional or OS-provided dependency names may be reported as unresolved even when the directly bundled runtime DLL itself has already been identified correctly.

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

That is why the helper scripts `set_env.bat` and `.env.vscode` configure `Path` only for dependencies intentionally expected to be installed on the target machine.

More generally, this is why Windows is mapped to `TARGET_LOCAL_RUNTIME_FILES` rather than to an embedded-runtime-path strategy. The main build-tree convenience mechanism is app-local DLL placement, not binary-embedded runtime search metadata.

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
- `CMagnetoInternal__get_runtime_resolution_strategy`
- `CMagnetoInternal__register_linked_imported_shared_library_targets`
- `CMagnetoInternal__is_imported_shared_library_target`
- `CMagnetoInternal__get_imported_shared_library_paths`
- `CMagnetoInternal__get_imported_shared_library_paths_for_build_type`
- `CMagnetoInternal__generate__runtime_dependency_manifest__content`
- `CMagnetoInternal__set_up_target_runtime_resolution`
- `CMagnetoInternal__install_bundled_external_shared_libraries`
- `CMagnetoInternal__runtime_dependency_manifest__warn_about_target_unclassified_imported_targets`

The main files to read are:

- [`./../cmake/ThirdPartySharedLibsTools.cmake`](./../cmake/ThirdPartySharedLibsTools.cmake)
- [`./../cmake/ThirdPartySharedLibsTools_Internals.cmake`](./../cmake/ThirdPartySharedLibsTools_Internals.cmake)
- [`./../cmake/ThirdPartySharedLibsTools/SharedState_Internals.cmake`](./../cmake/ThirdPartySharedLibsTools/SharedState_Internals.cmake)
- [`./LinuxPackageVerification.md`](./LinuxPackageVerification.md)
- [`./../README.md`](./../README.md)
