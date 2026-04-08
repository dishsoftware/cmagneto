# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions and variables for setting up project.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpProject_Internals.cmake")


#[[
    CMagneto__set_CMake_package_find_dependencies

    Defines exact `find_dependency(...)` lines to be written into the generated `*Config.cmake`
    of the project.

    Parameters:
    iDependencyCalls - Each argument must be a complete CMake line, typically a `find_dependency(...)` call.

    Example:
    ```cmake
    CMagneto__set_CMake_package_find_dependencies(
        "find_dependency(Qt6 REQUIRED COMPONENTS Core Gui Widgets)"
        "find_dependency(Boost CONFIG REQUIRED)"
    )
    ```
]]
function(CMagneto__set_CMake_package_find_dependencies)
    set_property(GLOBAL PROPERTY CMagnetoInternal__CMakePackageFindDependencies "${ARGN}")
endfunction()


#[[
    CMagneto__set_up__project

    Sets up:
    - CMake package configuration files, auxilliary targets, reports, helper scripts, etc.;
    - Unit and integration test compilation and `run_tests` scripts;
    - Packaging.

    It must be called:
    - After all CMagneto__set_up__library(iLibTargetName), CMagneto__set_up__interface_library(iLibTargetName)
      and CMagneto__set_up__executable(iExeTargetName) are called.
    - From a CMakeLists.txt, where the `project(...) command is called.
]]
function(CMagneto__set_up__project)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    CMagneto__print_platform_and_compiler()

    # Add source directory.
    cmake_path(SET _PROJECT_SOURCES_SRC_DIR NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_SRC}/${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}/")
    add_subdirectory("${_PROJECT_SOURCES_SRC_DIR}")
    # Strategies based on embedded runtime paths may be applied later from the
    # central project setup directory.
    CMagnetoInternal__get_runtime_resolution_strategy(_runtimeResolutionStrategy)
    if(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__EMBEDDED_RUNTIME_PATHS}")
        CMagnetoInternal__set_up_targets_runtime_resolution()
    endif()

    CMagnetoInternal__install_project_defs_header()

    # Generate build stage reports, helper scripts, etc.
    CMagnetoInternal__set_up__CMake_package_export()
    CMagnetoInternal__set_up__build_summary__file() # Required by `build.py` in the project root.
    CMagnetoInternal__set_up__runtime_dependency_manifest() # Canonical runtime-dependency metadata consumed by diagnostics and verification.
    CMagnetoInternal__set_up__set_env__script() # Build-tree helper for cases where runtime dependencies are not resolved by target properties.
    CMagnetoInternal__set_up__env_vscode__file() # Build-tree VS Code helper for debugger setups that do not honor target runtime resolution.
    CMagnetoInternal__set_up__run__script() # Optional build-tree helper.
    ####################################################

    # Configure tests.
    cmake_path(SET _PROJECT_NATIVE_TESTS_DIR NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_TESTS_NATIVE}/")
    add_subdirectory("${_PROJECT_NATIVE_TESTS_DIR}" EXCLUDE_FROM_ALL) # Exclude tests from the default build target, so they are not built unless explicitly requested.
    CMagnetoInternal__add__build_tests__target() # Required by `build.py` in the project root.
    CMagnetoInternal__set_up__run_tests__script() # Required by `build.py` in the project root.

    # Configure packaging.
    ## The project only sets up packaging, if it is the top level project.
    if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
        CMagneto__set_up__license_bundle_installation()
        CMagnetoInternal__install_bundled_external_shared_libraries()

        cmake_path(SET _CPACKCONFIG_PATH NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_CPACKCONFIG}/CPackConfig.cmake")
        include("${_CPACKCONFIG_PATH}")
    endif()
endfunction()
