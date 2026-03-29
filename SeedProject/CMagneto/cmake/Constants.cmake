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
    This submodule of the CMagneto module defines constants, which may be used by scripts and other modules.
]]


# Build/install subdirectory names.
## Under project root: project source dir.
set(CMagneto__SUBDIR_SOURCE "src/")

## Under project build and install dirs: parent for compiled static libs.
set(CMagneto__SUBDIR_STATIC "lib/")

## Under project build and install dirs: parent for compiled shared libs.
## Note: On Windows, CMake treats shared libraries as runtime artifacts, not library artifacts;
## thus, `*.dll` files are placed under `{CMagneto__SUBDIR_EXECUTABLE}`.
set(CMagneto__SUBDIR_SHARED "lib/")

## Under project build and install dirs: parent for compiled executables.
## Note: see a note above.
set(CMagneto__SUBDIR_EXECUTABLE "bin/")

## Under project install dir: parent for all non-private headers of all library targets.
set(CMagneto__SUBDIR_INCLUDE "include/")

## Under project install dir: parent for CMake package configuration files of the project and all its library targets.
set(CMagneto__SUBDIR_CMAKE "lib/cmake/")

## Under target source dir: parent for all resources of a target.
## Under project install dir: parent for all resources of all targets.
set(CMagneto__SUBDIR_TARGET_RESOURCES "@resources/")

## Under target source dir: parent for target's resources, which must be embedded into the target's binary using Qt RCC.
set(CMagneto__SUBDIR_QTRC "QtRC/")

## Under target source dir: parent for target's Qt translation files (`*.ts`).
## Under project install dir: parent for `*.qm` (compiled `*.ts`) resources of all targets.
set(CMagneto__SUBDIR_QTTS "QtTS/")

## Under project build dir: temporary files, created during `Generation` and `Build` stages.
set(CMagneto__SUBDIR_TMP "TMP/")

## Under project build and install dirs: parent for build and test reports.
set(CMagneto__SUBDIR_SUMMARY "summary/")

## Under project root: parent for unit and integration tests' code and resources.
## Under project build dir: parent for `CTestTestfile.cmake` and built test files.
set(CMagneto__SUBDIR_TESTS "tests/")

## Under project root: parent for `CPackConfig.cmake` and `{CMagneto__SUBDIR_PACKAGE_RESOURCES}`.
set(CMagneto__SUBDIR_CPACKCONFIG "packaging/")

## Under `{CMagneto__SUBDIR_CPACKCONFIG}`: parent for package resources (e.g. license, user agreement, etc).
set(CMagneto__SUBDIR_PACKAGE_RESOURCES "@resources/")

## Under project build dir: parent for generated packages.
set(CMagneto__SUBDIR_PACKAGES "packages/")
########################################################################################################################

cmake_path(SET CMAKE_ARCHIVE_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_STATIC}/")
cmake_path(SET CMAKE_LIBRARY_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SHARED}/")
cmake_path(SET CMAKE_RUNTIME_OUTPUT_DIRECTORY NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/")

# These postfixes do not affect executable target output names (names of compiled executables).
set(CMAKE_DEBUG_POSTFIX "_D")
set(CMAKE_RELWITHDEBINFO_POSTFIX "_RDI")
set(CMAKE_MINSIZEREL_POSTFIX "_MSR")

# Names of installation components.
set(CMagneto__COMPONENT__RUNTIME "Runtime")
set(CMagneto__COMPONENT__DEVELOPMENT "Development")
set(CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC "BuildMachineSpecific")

# Names of report files.
set(CMagneto__BUILD_SUMMARY__FILE_NAME "build_summary.txt")
set(CMagneto__TEST_BUILD_SUMMARY__FILE_NAME "test_build_summary.txt")
set(CMagneto__RUN_TESTS__SCRIPT_NAME_WE "run_tests")
set(CMagneto__TEST_REPORT__FILE_NAME "test_report.xml")