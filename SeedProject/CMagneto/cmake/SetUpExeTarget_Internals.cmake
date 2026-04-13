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
    This submodule of the CMagneto module defines internal functions and variables for setting up executable targets.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Define functions and variables for setting up targets (common for static/shared libs and exes).
include("${CMAKE_CURRENT_LIST_DIR}/SetUpTarget.cmake")


function(CMagnetoInternal__check_executable_target_type iExeTargetName iCallerName)
    if(NOT TARGET ${iExeTargetName})
        CMagnetoInternal__message(FATAL_ERROR "${iCallerName}: target \"${iExeTargetName}\" does not exist.")
    endif()

    get_target_property(_targetType ${iExeTargetName} TYPE)
    if(NOT (_targetType STREQUAL "EXECUTABLE"))
        CMagnetoInternal__message(FATAL_ERROR "${iCallerName}: target \"${iExeTargetName}\" type must be EXECUTABLE, got \"${_targetType}\".")
    endif()
endfunction()


function(CMagnetoInternal__set_up_windows_executable_icon iExeTargetName iIconAbsPath)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_TMP}")

    cmake_path(NATIVE_PATH iIconAbsPath NORMALIZE _iconNativePath)
    string(REPLACE "\\" "\\\\" _iconNativePathEscaped "${_iconNativePath}")

    set(_rcPath "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_TMP}/${iExeTargetName}__AppIcon.rc")
    set(_rcText [=[
IDI_APP_ICON ICON "]=])
    string(APPEND _rcText "${_iconNativePathEscaped}")
    string(APPEND _rcText [=["
]=])
    file(WRITE "${_rcPath}" "${_rcText}")

    target_sources(${iExeTargetName} PRIVATE "${_rcPath}")
endfunction()
