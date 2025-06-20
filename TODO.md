* ? Remove "set_env" and ".env.vscode" scripts and copy 3rd-party libraries to "build/.../bin" and "install/.../bin" instead.
    It can be achieved using
    ```
    set_target_properties(iTarget PROPERTIES
        BUILD_RPATH "$ORIGIN/../lib;$ORIGIN/../other_lib"
        INSTALL_RPATH ""
        # On Linux dynamic libs are placed to "lib" and executables into "bin":
        # Also add "../lib" to both BUILD_RPATH and INSTALL_RPATH of executables.
    )
    ```
* ? Make some variables from "./cmake/modules/CMagneto.cmake" accessible only within the file.
* ? Add project name as prefix to all variables in CMagneto to support superbuild.

* Generate "LibName.h" with exports from a CMake or Python script.
* Add a script, which copies 3rd-party shared libraries to "install/.../3rd_party" directory. The script must also copy ".pdb" or analogues, if they exist.
* Gather paths to include directories of 3rd-party shared libraries and generate "./vscode/c_cpp_properties.json" using a template file by substituting "includePath" properties with the gathered paths.
* Generate ".vscode/launch.json" using a template by substituting "program" properties with a name of the entrypoint executable binary.
* Tweak generation with MSVS to be able to run the whole build pipeline using the IDE's GUI only. ? Define `CMAKE_INSTALL_PREFIX_$<CONFIG>=CMAKE_INSTALL_PREFIX/$<CONFIG>` if generator is multi-config.
* Check if there are always quotes around path variables in CMake. Add checks if lists are empty.
* Make inclusions of the project headers look like `#include <ProjectName/LibName/.../Subdir/.../Header.hpp>`.
* Endorse specifying ProjectName as a namespace while linking targets of the project to other targets of the project. Support it in "./cmake/modules/CMagneto.cmake" and "./build.py".
* Write a check if there are 3rd-party shared libs with the same name, but in different directories.
* Use InstallRequiredSystemLibraries CMake module.
* What if an external shared lib A depends on another shared lib B, A and B are in different dirs? CMagneto does not discover library B. It means, not all dependecies will end up ion distributed package. To gather all shared libs recursively, consider usage of "ldd or "lddtree" on binaries in "installed" dir. Or consider BundleUtilities and GetPrerequisites CMake modules.
* Add function set_up_interface_library.
* CMakePresets.json.
* Fix content of packaging\License.txt, packaging\Readme.txt, etc.
* Add option "--file ALL" to ./CI/Docker/build_docker_image.py.