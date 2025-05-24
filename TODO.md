* ? Add to CMake
    install(
      ...
      COMPONENT Development
    )
* ? Remove set_env and .env.vscode scripts and copy 3rd-party libraries to build/bin and install/bin instead.
* ? Make some variables from cmake_modules/SetUpTargets.cmake accessible only within the file.

* Generate LibName.h with exports from a CMake or Python script.
* Add a script, which copies 3rd-party shared libraries to install/bin. The script must also copy .pdb or analogues, if they exist.
* Tweak generation with MSVS to build, debug, test and install using the IDE's GUI only.
* Add install path from CMake if generator is multi-config.
* Slap quotes in CMake. Add checks if lists are empty.
* Check if Linux scripts can be run corectly from any workdir.
