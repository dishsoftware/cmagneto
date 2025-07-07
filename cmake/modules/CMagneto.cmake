# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    See `./CMagneto.md`.
    The file loads submodules of CMagneto CMake module (except Packager).
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load CMagneto submodules.
## Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/Logger.cmake")

## Define functions to load project metadata.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/MetaLoader.cmake")

## CMakePackageConfigHelpers contains functions to create config files (*Config.cmake, *ConfigVersion.cmake, etc.),
## which are read by find_package() in consumer projects.
include(CMakePackageConfigHelpers)

## Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/Constants.cmake")

## Defines general-purpose functions to simplify integration with CMake generators of build system files.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/GeneratorTools.cmake")

## Define general-purpose functions for path handling.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/PathTools.cmake")

## Define constants and functions for handling scripts.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/Platform.cmake")

## Define general-purpose functions generation and installation of arbitrary files.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/SetUpFile.cmake")

## Define functions for handling 3rd-party shared libraries.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/ThirdPartySharedLibsTools.cmake")

## Define general-purpose functions and variables to simplify Qt integration.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/Qt.cmake")

## Load the QtWrappers CMake module to use a workaround for a bug in MOC preprocessor of Qt 5.6.0 and newer.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/../QtWrappers.cmake")

## Load functions to set up static/shared lib targets, exe targets and project.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/SetUpTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/SetUpLibTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/SetUpExeTarget.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/SetUpProject.cmake")

## Define functions for GoogleTest integration.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/TestTools.cmake")


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