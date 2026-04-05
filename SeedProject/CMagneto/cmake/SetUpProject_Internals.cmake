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
    This submodule of the CMagneto module defines internal functions and variables for setting up project.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Load submodules to handle related binaries and files.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpFile.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SetUpLibTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SetUpExeTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools.cmake")

# Define functions for GoogleTest integration.
include("${CMAKE_CURRENT_LIST_DIR}/TestTools.cmake")


#[[
    CMagnetoInternal__set_up__CMake_package_export

    Sets up CMake package configuration files:
    1) Defines an export set for install targets;
    2) Generates and installs:
        2.1) *Targets.cmake
        2.2) *Config.cmake
        2.3) *ConfigVersion.cmake

    It must be called:
    - After all library and executable targets has been set up.
]]
function(CMagnetoInternal__set_up__CMake_package_export)
    # Export all targets to a single export set.
    # The exported target names are fully qualified already via each target's EXPORT_NAME.
    install(EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${CMagneto__SUBDIR_CMAKE}/${PROJECT_NAME}
        COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
    )

    # Create a template "${PROJECT_NAME}Config.cmake.in" file.
    set(_cmake_in__content [[
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@Targets.cmake")
    ]])
    set(_cmake_in__path "${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE "${_cmake_in__path}" "${_cmake_in__content}")

    # Generate the ${PROJECT_NAME}Config.cmake using the template file.
    configure_package_config_file(
        "${_cmake_in__path}"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION ${CMagneto__SUBDIR_CMAKE}/${PROJECT_NAME}
    )

    # Create the ${PROJECT_NAME}ConfigVersion.cmake file.
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # Install the package configuration files.
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION ${CMagneto__SUBDIR_CMAKE}/${PROJECT_NAME}
        COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
    )
endfunction()


set(CMagnetoInternal__GENERATE_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/generate_build_summary.cmake")


#[[
    CMagnetoInternal__set_up__build_summary__file

    After all registered targets are built, the function composes, places to build directory and installs "build_summary.txt".

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
    If the function is not called, "build.py" will not work correctly:
    "build.py" checks for the presence of "build_summary.txt" to determine whether the project is compiled.
]]
function(CMagnetoInternal__set_up__build_summary__file)
    set(_summaryOutputDir "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SUMMARY}")
    CMagnetoInternal__get_git_commit_sha(_gitCommitSha)

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_summaryOutputPath "${_summaryOutputDir}/$<CONFIG>/${CMagneto__BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_summaryOutputPath "${_summaryOutputDir}/${CMagneto__BUILD_SUMMARY__FILE_NAME}")
        set(_buildType "${CMAKE_BUILD_TYPE}")
    endif()

    add_custom_target(build_summary ALL)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    if(_registeredTargets)
        add_dependencies(build_summary ${_registeredTargets})
    endif()

    # The file is used by "build.py" to determine whether the project is compiled.
    add_custom_command(
        TARGET build_summary POST_BUILD
        COMMENT "Composing ${CMagneto__BUILD_SUMMARY__FILE_NAME}"
        COMMAND ${CMAKE_COMMAND}
            -DOUT="${_summaryOutputPath}"
            -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
            -DCMAKE_SYSTEM_VERSION="${CMAKE_SYSTEM_VERSION}"
            -DCMAKE_GENERATOR="${CMAKE_GENERATOR}"
            -DCMAKE_CXX_COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
            -DCMAKE_CXX_COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
            -DCMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER}"
            -DCMAKE_BUILD_TYPE="${_buildType}"
            -DGIT_COMMIT_SHA="${_gitCommitSha}"
            -P "${CMagnetoInternal__GENERATE_BUILD_SUMMARY__SCRIPT_PATH}"
    )

    # Install the file.
    install(FILES "${_summaryOutputPath}"
        DESTINATION "${CMagneto__SUBDIR_SUMMARY}"
        COMPONENT ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC}
    )
endfunction()
