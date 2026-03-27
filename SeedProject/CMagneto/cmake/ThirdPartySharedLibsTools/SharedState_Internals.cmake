# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)

# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/../Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/../Constants.cmake")

# Define constants and functions for handling scripts.
include("${CMAKE_CURRENT_LIST_DIR}/../Platform.cmake")

# Define general-purpose functions generation and installation of arbitrary files.
include("${CMAKE_CURRENT_LIST_DIR}/../SetUpFile.cmake")

# Define functions and variables for setting up targets (common for static/shared libs and exes).
include("${CMAKE_CURRENT_LIST_DIR}/../SetUpTarget.cmake")

# Define functions and variables for setting up static/shared library targets.
include("${CMAKE_CURRENT_LIST_DIR}/../SetUpLibTarget.cmake")

# Define functions and variables for setting up executable targets.
include("${CMAKE_CURRENT_LIST_DIR}/../SetUpExeTarget.cmake")


set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE "EXPECT_ON_TARGET_MACHINE")
set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE "BUNDLE_WITH_PACKAGE")

set(CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE ""
    CACHE STRING
    "Semicolon-separated imported shared-library targets expected to be installed on the target machine at the same absolute locations as on the build machine."
)
set(CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE ""
    CACHE STRING
    "Semicolon-separated imported shared-library targets that must be bundled into the installation package."
)
set(CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILES ""
    CACHE STRING
    "Semicolon-separated runtime dependency files that must be bundled into the installation package as low-level overrides."
)
set(CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS ""
    CACHE STRING
    "Semicolon-separated file masks that must be searched and bundled into the installation package as low-level overrides."
)
set(CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILES ""
    CACHE STRING
    "Semicolon-separated runtime dependency files that must not be bundled into the installation package."
)
set(CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS ""
    CACHE STRING
    "Semicolon-separated file masks that must not be bundled into the installation package."
)


#[[
    CMagnetoInternal__add_path_to_shared_libs

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    iPath - path to a binary of a shared lib, which iTargetName is linked to.
]]
function(CMagnetoInternal__add_path_to_shared_libs iTargetName iBuildType iPath)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "CMagnetoInternal__PathsToSharedLibs__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PathsTo_${_buildType}_SharedLibs__${iTargetName}")
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    if(NOT DEFINED _paths)
        set(_paths "")
    endif()

    list(APPEND _paths ${iPath})
    list(REMOVE_DUPLICATES _paths)

    set_property(GLOBAL PROPERTY "${_propName}" "${_paths}")
endfunction()


#[[
    CMagnetoInternal__get_paths_to_shared_libs

    Returns paths to binaries of shared libraries, which iTargetName is linked to.

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    Paths to shared libs for iTargetName are filled when CMagneto__set_up__library(iTargetName) or CMagneto__set_up__executable(iTargetName) are called.
]]
function(CMagnetoInternal__get_paths_to_shared_libs iTargetName iBuildType oPaths)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "CMagnetoInternal__PathsToSharedLibs__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PathsTo_${_buildType}_SharedLibs__${iTargetName}")
    endif()

    get_property(_isSet GLOBAL PROPERTY "${_propName}" SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()
