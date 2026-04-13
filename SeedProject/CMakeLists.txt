# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

cmake_minimum_required(VERSION 3.31) # Keep in sync with ./CMakePresets.json: preset schema version 10 makes CMake 3.31 the supported project minimum.
# set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

# Newer CMake versions warn unless the intended modern behavior of these
# policies is selected explicitly.
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()
if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
endif()


# Configure project attributes.
## Define functions to load project data.
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
include("${CMAKE_SOURCE_DIR}/CMagneto/cmake/MetaLoader.cmake")
CMagneto__parse__project_json()


project("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}"
    DESCRIPTION "${CMagneto__PROJECT_JSON__PROJECT_DESCRIPTION}"
    HOMEPAGE_URL "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}"
    VERSION "${CMagneto__PROJECT_JSON__PROJECT_VERSION}"
    LANGUAGES CXX
)


# Set project-global options.
## Minimum language standard is bound by the project source code and GoogleTest CMake module.
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Include the rest of CMagneto cmake modules (except Packager).
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
include("${CMAKE_SOURCE_DIR}/CMagneto/cmake/Main.cmake")

# Optional, if some C++ code of CMagneto is useful in this project.
add_subdirectory(
    "${CMAKE_SOURCE_DIR}/CMagneto/cpp/sources"
    "${CMAKE_BINARY_DIR}/CMagneto/sources"
)

# Defines exact `find_dependency(...)` lines to be written into the generated `*Config.cmake` of the project.
# Useful to ease life of consumer projects after call of `find_package(<THIS_PROJECT>)`.
CMagneto__set_CMake_package_find_dependencies(
    "find_dependency(Qt6 REQUIRED COMPONENTS Core Gui Widgets)"
    "find_dependency(Boost CONFIG REQUIRED)"
)

CMagneto__set_up__project()
