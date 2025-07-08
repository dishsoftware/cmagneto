* ? Remove "set_env" and ".env.vscode" scripts and copy 3rd-party libraries to "build/.../bin" and "install/.../bin" instead.
    It can be achieved using
    ```cmake
    set_target_properties(iTarget PROPERTIES
        BUILD_RPATH "$ORIGIN/../lib;$ORIGIN/../other_lib"
        INSTALL_RPATH ""
        # On Linux dynamic libs are placed to "lib" and executables into "bin":
        # Also add "../lib" to both BUILD_RPATH and INSTALL_RPATH of executables.
    )
    ```
* ? Make some variables from submodules of "./cmake/modules/CMagneto/" accessible only within the file.

* Generate "LibTargetName.h" with exports from a CMake or Python script.
* Add a script, which copies 3rd-party shared libraries to "install/.../3rd_party" directory. The script must also copy ".pdb" or analogues, if they exist.
* Gather paths to include directories of 3rd-party shared libraries and generate "./vscode/c_cpp_properties.json" using a template file by substituting "includePath" properties with the gathered paths.
* Tweak generation with MSVS to be able to run the whole build pipeline using the IDE's GUI only. ? Define `CMAKE_INSTALL_PREFIX_$<CONFIG>=CMAKE_INSTALL_PREFIX/$<CONFIG>` if generator is multi-config.
* Check if there are always quotes around path variables in CMake. Add checks if lists are empty.
* Endorse specifying ProjectName as a namespace while linking targets of the project to other targets of the project. Support it in "./cmake/modules/CMagneto/" and "./build.py".
* Write a check if there are 3rd-party shared libs with the same name, but in different directories.
* Use InstallRequiredSystemLibraries CMake module.
* What if an external shared lib A depends on another shared lib B, A and B are in different dirs? CMagneto does not discover library B. It means, not all dependecies will end up ion distributed package. To gather all shared libs recursively, consider usage of "ldd or "lddtree" on binaries in "installed" dir. Or consider BundleUtilities and GetPrerequisites CMake modules.
* Add function set_up_interface_library.
* CMakePresets.json.
* Add option "--file ALL" to ./CI/Docker/build_image.py.
* Test coverage.
* Qt IFW tweaks.
* Add system tests and an approppriate job in CI pipeline.
* Add ignition switch to branding assets.
* Adopt the Open Container Initiative (OCI) label schema for labeling Docker images.
* CMagneto__get_library_type must receive and define `--LIB_{CompanyName_SHORT}_{ProjectNameBase}_{LibTargetName}_SHARED` instead of `--LIB_{LibTargetName}_SHARED`.
* Add option to run verbose build: `cmake --build . --config Release --verbose`.
* Packaging of Debug fails, if generator is multi-config.