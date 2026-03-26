* Tweak generation with MSVS to be able to run the whole build pipeline using the IDE's GUI only. ? Define `CMAKE_INSTALL_PREFIX_$<CONFIG>=CMAKE_INSTALL_PREFIX/$<CONFIG>` if generator is multi-config.
* Check if there are always quotes around path variables in CMake. Add checks if lists are empty.
* Write a check if there are 3rd-party shared libs with the same name, but in different directories.
* Use InstallRequiredSystemLibraries CMake module.
* Transitive shared-library bundling is still not solved fully. Direct imported shared libraries configured as `BUNDLE_WITH_PACKAGE` are now discovered, bundled and verified, but if bundled external shared library A depends on another shared library B in a different directory and B is not represented as a tracked imported target, CMagneto still does not discover and bundle B recursively. Current Linux package verification may detect some such problems after packaging, but recursive dependency discovery itself is still missing. To gather shared libraries recursively, consider usage of `ldd` or `lddtree` on binaries in the installed tree, or consider CMake `BundleUtilities` and `GetPrerequisites` modules.
* Add function set_up_interface_library.
* CMakePresets.json.
* Test coverage for code of CMagneto framework itself. Test coverage of SeedProject is already added.
* Qt IFW tweaks.
* Add system tests and an approppriate job in CI pipeline.
* Add ignition switch to branding assets.
* Adopt the Open Container Initiative (OCI) label schema for labeling Docker images.
* Add option to run verbose build: `cmake --build . --config Release --verbose`.
* Target name validity check must be done by the same piece of code both in the one-command-build-script and in CMagneto CMake modules.
* Packaging of Debug fails, if generator is multi-config.
* Add instructions on when to use interface and object libraries.
* Add integration and system tests for CMagneto framework.
* Support newer C++ standards' features, including C++ modules.
* Add copying (installing) of runtime-loaded resources into build and install dirs.
* Add a script, which generates `*.ts` files, using Qt lupdate.
* Add resource manager C++ code.
* In the `_DEFS.hpp` files add relative paths to resources.
* Add `Project_DEFS.hpp` file, common for all targets in the project, witgh project version and compatibility definitions.
* Don't look for lrelerase every time a ts file occurs.
* Do the same for each used build tool. Log versions and paths to these tools.
* Rewrite `QtWrappers.cmake`. Check if `automoc` is enabled.
* Make setting resource paths relative to:
  - `@resources/QtRC`
  - `@resources/QtTS`
  - `@resources/other`
  - etc.
  Add files in these dirs automatically?

* Automatically merge ts files of a target into a monolitic ts file?
* Does Google Test degrade performance of Release binaries?
* When to throw (raise) and when to exit in the one-command-build-scripts?
* Add possibility to add files to a target from a CMakeLists.txt in any subdir of the target using a path, relative to the lists file.
* Use `os.PathLike` instead of `Path` or `str` in python code as widely as possible.
* Run system tests only after merge into the main branch.
* Add a description how to work with and `TODO.md` and sync it with task managers.
* Sync test projects, while preserving CMagneto repo graph topology.
* Add memory leaks checks.
* ? In CI: change artifacts ouput path from `*/Branch_or_Tag/*` to `*/CommitSHA_or_TAG/*`.
* Why in `GUI` target is missing in the test coverage report?
* Make options to compile as shared, measure code coverage and check memory leaks per target, e.g. `--coverage TargetA TargetB`, `--coverage ALL` or `--coverage ALL_EXCEPT TargetA`...
* Change `str += ...` to `"".join(strs)` in python code.
* Add support of Android and WebAssembly.
* Add build stage with all the stages, but in Docker containers locally.
