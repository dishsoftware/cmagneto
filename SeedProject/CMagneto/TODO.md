* Tweak generation with MSVS to be able to run the whole build pipeline using the IDE's GUI only. ? Define `CMAKE_INSTALL_PREFIX_$<CONFIG>=CMAKE_INSTALL_PREFIX/$<CONFIG>` if generator is multi-config.
* Check if there are always quotes around path variables in CMake. Add checks if lists are empty.
* Write a check if there are 3rd-party shared libs with the same name, but in different directories.
* ? Use `InstallRequiredSystemLibraries`, `BundleUtilities`, `qt_generate_deploy_app_script()`, `qt_deploy_runtime_dependencies()`, `windeployqt`, `macdeployqt`.
* Add system tests for transitive runtime-dependency bundling of external shared libraries. Recursive install-time dependency discovery is now used for bundled imported shared libraries, but the exclusion rules for system runtimes and libraries expected on the target machine should be validated on Linux and Windows with realistic dependency graphs.
* Add instructions on when to use interface and object libraries.
* Test coverage for code of CMagneto framework itself. Test coverage of SeedProject is already added.
* Add ignition switch to branding assets.
* Adopt the Open Container Initiative (OCI) label schema for labeling Docker images.
* Add option to run verbose build: `cmake --build . --config Release --verbose`.
* Packaging of Debug fails, if generator is multi-config.
* Support newer C++ standards' features, including C++ modules.
* Add a script, which generates `*.ts` files, using Qt lupdate.
* Add resource manager C++ code.
* In the `_DEFS.hpp` files add relative paths to resources ?
* Add `Project_DEFS.hpp` file, common for all targets in the project, witgh project version and compatibility definitions.
* Do the same for each used build tool. Log versions and paths to these tools.
* Rewrite `QtWrappers.cmake`. Check if `automoc` is enabled.
* Automatically merge ts files of a target into a monolitic ts file?
* When to throw (raise) and when to exit in the one-command-build-scripts?
* Add possibility to add files to a target from a CMakeLists.txt in any subdir of the target using a path, relative to the lists file.
* Use `os.PathLike` instead of `Path` or `str` in python code as widely as possible.
* Add a description how to work with and `TODO.md` and sync it with task managers.
* Sync test projects, while preserving CMagneto repo graph topology.
* Add memory leaks checks.
* ? In CI: change artifacts ouput path from `*/Branch_or_Tag/*` to `*/CommitSHA_or_TAG/*`.
* Why in `GUI` target is missing in the test coverage report?
* Make options to measure code coverage and check memory leaks per target, e.g. `--coverage TargetA TargetB`, `--coverage ALL` or `--coverage ALL_EXCEPT TargetA`...
* Change `str += ...` to `"".join(strs)` in python code.
* Add support of Android and WebAssembly.
* Add build stage with all the stages, but in Docker containers locally.
* Assume a target A of the project does not use dependency D, and a target B of the project does use the D. If a consumer project links against A, will current setup of the project require the consumer project to `find_dependency(D)` ?
* CMagneto must work without Qt at all.
* ? Use `obj->setProperty()` to store nesting IDs of widgets instead of mixins.
* Make `zip` and `tar` packagers add `portable.flag`.