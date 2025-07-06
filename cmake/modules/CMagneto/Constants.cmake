# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines constants, which may be used by scripts and other modules.
]]


# Build/install subdirectory names.
set(CMagneto__SUBDIR_SOURCE "src/")
set(CMagneto__SUBDIR_STATIC "lib/")
set(CMagneto__SUBDIR_SHARED "lib/") # On Windows, .dll files are the shared libraries, but CMake treats them as runtime artifacts, not library artifacts.
set(CMagneto__SUBDIR_EXECUTABLE "bin/")
set(CMagneto__SUBDIR_INCLUDE "include/")
set(CMagneto__SUBDIR_CMAKE "lib/cmake/")
set(CMagneto__SUBDIR_RESOURCES "@resources/")
set(CMagneto__SUBDIR_QTRC "QtRC/")
set(CMagneto__SUBDIR_QTTS "QtTS/")
set(CMagneto__SUBDIR_TMP "TMP/")
set(CMagneto__SUBDIR_SUMMARY "summary/")
set(CMagneto__SUBDIR_CTESTTESTFILE "tests/")
set(CMagneto__SUBDIR_PACKAGES "packages/")

cmake_path(SET CMAKE_ARCHIVE_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_STATIC}/")
cmake_path(SET CMAKE_LIBRARY_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SHARED}/")
cmake_path(SET CMAKE_RUNTIME_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/")

# These postfixes do not affect executable target output names (names of compiled executables).
set(CMAKE_DEBUG_POSTFIX "_D")
set(CMAKE_RELWITHDEBINFO_POSTFIX "_RDI")
set(CMAKE_MINSIZEREL_POSTFIX "_MSR")

set(CMagneto__COMPONENT__RUNTIME "Runtime")
set(CMagneto__COMPONENT__DEVELOPMENT "Development")
set(CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC "BuildMachineSpecific")

set(CMagneto__BUILD_SUMMARY__FILE_NAME "build_summary.txt")
set(CMagneto__TEST_BUILD_SUMMARY__FILE_NAME "test_build_summary.txt")
set(CMagneto__RUN_TESTS__SCRIPT_NAME_WE "run_tests")
set(CMagneto__TEST_REPORT__FILE_NAME "test_report.xml")