# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines internal functions and variables to load project metadata from `./meta/` project directory.
    Must be loaded before loading of the CMagneto module itself.
]]


## Under project root: parent for project metadata.
## The constant is defined here, not in the Constants submodule,
## because the constant must be available before `project(...)` command,
## but the Constants submodule must be loaded after the CMakePackageConfigHelpers is loaded (TODO verify).
set(CMagneto__SUBDIR_META "meta/")

## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
cmake_path(SET CMagnetoInternal__META_DIR NORMALIZE "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_META}/")
cmake_path(SET CMagnetoInternal__PROJECT_JSON__PATH   NORMALIZE "${CMagnetoInternal__META_DIR}/Project.json")
cmake_path(SET CMagnetoInternal__PACKAGING_JSON__PATH NORMALIZE "${CMagnetoInternal__META_DIR}/Packaging.json")
