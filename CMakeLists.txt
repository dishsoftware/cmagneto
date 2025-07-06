# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

cmake_minimum_required(VERSION 3.28) # The oldest version of CMake (on Ubuntu 24 LTS) among the platforms supported by the project.


# Configure project attributes.
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
include("${CMAKE_SOURCE_DIR}/cmake/modules/CMagneto/ParseMeta.cmake")


project("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}"
    DESCRIPTION "${CMagneto__PROJECT_JSON__PROJECT_DESCRIPTION}"
    HOMEPAGE_URL "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}"
    VERSION "${CMagneto__PROJECT_JSON__PROJECT_VERSION}"
    LANGUAGES CXX
)


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON) # GoogleTest requires at least C++17.


# Include custom CMake modules.
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules") # Search of modules in directories from CMAKE_MODULE_PATH is not recursive.
include(CMagneto)

CMagneto__print_platform_and_compiler()


# Add source directories.
add_subdirectory("src/${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")


# Generate build stage reports, helper scripts, etc.
CMagneto__set_up_project()
CMagneto__set_up__3rd_party_shared_libs__list()
CMagneto__set_up__set_env__script()
CMagneto__set_up__env_vscode__file()
CMagneto__set_up__run__script()
CMagneto__set_up__run_tests__script()
CMagneto__set_up__build_summary__file()


# Configure tests.
add_subdirectory(tests EXCLUDE_FROM_ALL) # Exclude tests from the default build target, so they are not built unless explicitly requested.
CMagneto__add__build_tests__target()


# Configure packaging.
## The project only tries to set up packaging, if it is the top level project.
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
    include(${CMAKE_CURRENT_SOURCE_DIR}/packaging/CPackConfig.cmake)
endif()