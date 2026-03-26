# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
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
    CMagneto__set_up__project

    Sets up:
    - CMake package configuration files, auxilliary targets, reports, helper scripts, etc.;
    - Unit and integration test compilation and `run_tests` scripts;
    - Packaging.

    It must be called:
    - After all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
    - From a CMakeLists.txt, where the `project(...) command is called.
]]
function(CMagneto__set_up__project)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    CMagneto__print_platform_and_compiler()

    # Add source directory.
    cmake_path(SET _PROJECT_SOURCE_DIR NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}/${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}/")
    add_subdirectory("${_PROJECT_SOURCE_DIR}")
    CMagnetoInternal__set_up_targets_runtime_resolution()

    # Generate build stage reports, helper scripts, etc.
    CMagnetoInternal__set_up__CMake_package_export()
    CMagnetoInternal__set_up__build_summary__file() # Required by `build.py` in the project root.
    CMagnetoInternal__set_up__3rd_party_shared_libs__list() # Optional.
    CMagnetoInternal__set_up__external_shared_library_deployment__list() # Optional build-machine-specific metadata for package verification.
    CMagnetoInternal__set_up__set_env__script() # Legacy dev helper for cases where runtime dependencies are not resolved by target properties.
    CMagnetoInternal__set_up__env_vscode__file() # Legacy VS Code helper for debugger setups that do not honor target runtime resolution.
    CMagnetoInternal__set_up__run__script() # Optional legacy dev helper.
    ####################################################

    # Configure tests.
    cmake_path(SET _PROJECT_TESTS_DIR NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_TESTS}/")
    add_subdirectory("${_PROJECT_TESTS_DIR}" EXCLUDE_FROM_ALL) # Exclude tests from the default build target, so they are not built unless explicitly requested.
    CMagnetoInternal__add__build_tests__target() # Required by `build.py` in the project root.
    CMagnetoInternal__set_up__run_tests__script() # Required by `build.py` in the project root.

    # Configure packaging.
    ## The project only sets up packaging, if it is the top level project.
    if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
        CMagnetoInternal__install_bundled_external_shared_libraries()

        cmake_path(SET _CPACKCONFIG_PATH NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_CPACKCONFIG}/CPackConfig.cmake")
        include("${_CPACKCONFIG_PATH}")
    endif()
endfunction()
