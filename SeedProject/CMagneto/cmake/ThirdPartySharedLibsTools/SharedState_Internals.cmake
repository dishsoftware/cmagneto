# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
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
set(CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__EMBEDDED_RUNTIME_PATHS "EMBEDDED_RUNTIME_PATHS")
set(CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__TARGET_LOCAL_RUNTIME_FILES "TARGET_LOCAL_RUNTIME_FILES")
set(CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__NONE "NONE")

#[[
    CMagnetoInternal__get_runtime_resolution_strategy

    Returns the runtime-resolution strategy selected for the current platform.

    The strategy describes how build-tree runtime lookup is expressed in CMake:
    - EMBEDDED_RUNTIME_PATHS:
      runtime lookup is configured through target properties such as BUILD_RPATH
      and INSTALL_RPATH and may be applied later from a central directory scope;
    - TARGET_LOCAL_RUNTIME_FILES:
      runtime lookup is configured by attaching target-local build steps such as
      POST_BUILD copying of runtime files and must therefore be applied from the
      same directory in which the target was created;
    - NONE:
      no platform-specific runtime-resolution configuration is implemented.
]]
function(CMagnetoInternal__get_runtime_resolution_strategy oStrategy)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(_strategy ${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__EMBEDDED_RUNTIME_PATHS})
    elseif(WIN32)
        set(_strategy ${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__TARGET_LOCAL_RUNTIME_FILES})
    else()
        set(_strategy ${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__NONE})
    endif()

    set(${oStrategy} "${_strategy}" PARENT_SCOPE)
endfunction()

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
