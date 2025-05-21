* ? Add to CMake scripts:
    install(
      ...
      COMPONENT Development
    )

* Generate LibName.h with exports from a CMake or Python script.
* Add s script, which copies 3rd-party shared libraries to install/bin. The script must also copy .pdb or analogues, if they exist.
* GTest.
* Tweak generation with MSVS to build, debug, test and install using the IDE's GUI only.
* Make some variables from cmake_modules/SetUpTargets.cmake accessible only within the file.
* ? Remove set_env and .env.vscode scripts and copy 3rd-party libraries to build/bin and install/bin instead.