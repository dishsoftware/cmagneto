# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

cmake_minimum_required(VERSION 3.28) # The oldest version of CMake (on Ubuntu 24 LTS) among the platforms supported by the project.
# set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)


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
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Include the rest of CMagneto cmake modules (except Packager).
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
include("${CMAKE_SOURCE_DIR}/CMagneto/cmake/Main.cmake")
CMagneto__set_up__project()