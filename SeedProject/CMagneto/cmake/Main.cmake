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
    See `./README.md`.
    The file loads submodules of the CMagneto CMake module (except Packager).
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load CMagneto submodules.
## Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

## Set up instrumentation to generate metadata files for code coverage tools.
include("${CMAKE_CURRENT_LIST_DIR}/MetaLoader.cmake")

## CMakePackageConfigHelpers contains functions to create config files (*Config.cmake, *ConfigVersion.cmake, etc.),
## which are read by find_package() in consumer projects.
include(CMakePackageConfigHelpers)

## Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

## Defines general-purpose functions to simplify integration with CMake generators of build system files.
include("${CMAKE_CURRENT_LIST_DIR}/GeneratorTools.cmake")

## Define general-purpose functions for path handling.
include("${CMAKE_CURRENT_LIST_DIR}/PathTools.cmake")

## Define constants and functions for handling scripts.
include("${CMAKE_CURRENT_LIST_DIR}/Platform.cmake")

## Define functions to load project metadata.
include("${CMAKE_CURRENT_LIST_DIR}/CodeCoverage.cmake")

## Define general-purpose functions generation and installation of arbitrary files.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpFile.cmake")

## Define functions for handling 3rd-party shared libraries.
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools.cmake")

## Define general-purpose functions and variables to simplify Qt integration.
include("${CMAKE_CURRENT_LIST_DIR}/Qt.cmake")

## Load the QtWrappers CMake module to use a workaround for a bug in MOC preprocessor of Qt 5.6.0 and newer.
include("${CMAKE_CURRENT_LIST_DIR}/QtWrappers.cmake")

## Load functions to set up static/shared lib targets, exe targets and project.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SetUpLibTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SetUpExeTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SetUpProject.cmake")

## Define functions for GoogleTest integration.
include("${CMAKE_CURRENT_LIST_DIR}/TestTools.cmake")


function(CMagneto__print_platform_and_compiler)
    CMagnetoInternal__message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
    CMagnetoInternal__message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    CMagnetoInternal__message(STATUS "Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
    CMagnetoInternal__message(STATUS "Compiler Path: ${CMAKE_CXX_COMPILER}")

    CMagneto__is_multiconfig(_isGeneratorMulticonfig)
    if(_isGeneratorMulticonfig)
        CMagnetoInternal__message(STATUS "Multi-configuration generator of build system files")
    else()
        CMagnetoInternal__message(STATUS "Single-configuration generator of build system files")
    endif()
endfunction()