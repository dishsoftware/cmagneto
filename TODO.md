* ? Add to CMake
    install(
      ...
      COMPONENT Development
    )
* ? Remove "set_env" and ".env.vscode" scripts and copy 3rd-party libraries to "build/.../bin" and "install/.../bin" instead.
* ? Make some variables from "./cmake_modules/SetUpTargets.cmake" accessible only within the file.
* ? Rename "./cmake_modules" to "./cmake/modules" and "./cmake_aux" to "./cmake/scripts".

* Generate "LibName.h" with exports from a CMake or Python script.
* Add a script, which copies 3rd-party shared libraries to "install/.../3rd_party" directory. The script must also copy ".pdb" or analogues, if they exist.
* Gather paths to include directories of 3rd-party shared libraries and generate "./vscode/c_cpp_properties.json" using a template file by substituting "includePath" properties with the gathered paths.
* Generate ".vscode/launch.json" using a template by substituting "program" properties with a name of the entrypoint executable binary.
* Tweak generation with MSVS to be able to run the whole build pipeline using the IDE's GUI only. ? Define `CMAKE_INSTALL_PREFIX_$<CONFIG>=CMAKE_INSTALL_PREFIX/$<CONFIG>` if generator is multi-config.
* Check if there are always quotes around path variables in CMake. Add checks if lists are empty.
* Make inclusions of the project headers look like `#include <ProjectName/LibName/.../Subdir/.../Header.hpp>`.
* Endorse specifying ProjectName as a namespace while linking targets of the project to other targets of the project. Support it in "./cmake_modules/SetUpTargets.cmake" and "./build.py".
* Write a check if there are 3rd-party shared libs with the same name, but in different directories.
* Add packaging.
* Add CI/CD.
