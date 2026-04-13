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
    This submodule of the CMagneto module defines general-purpose functions and variables to simplify Qt integration.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/Qt_Internals.cmake")


function(CMagneto__find__Qt_lrelease_executable oQT_LRELEASE_EXECUTABLE)
    CMagnetoInternal__find_registered_tool("Qt_lrelease" _registeredLreleaseExecutable)
    set(_resolvedLreleaseExecutable "")

    if(DEFINED QT_LRELEASE_EXECUTABLE AND NOT QT_LRELEASE_EXECUTABLE STREQUAL "")
        set(_resolvedLreleaseExecutable "${QT_LRELEASE_EXECUTABLE}")
    elseif(DEFINED QT6_LRELEASE_EXECUTABLE AND NOT QT6_LRELEASE_EXECUTABLE STREQUAL "")
        set(_resolvedLreleaseExecutable "${QT6_LRELEASE_EXECUTABLE}")
    elseif(DEFINED Qt6_LRELEASE_EXECUTABLE AND NOT Qt6_LRELEASE_EXECUTABLE STREQUAL "")
        set(_resolvedLreleaseExecutable "${Qt6_LRELEASE_EXECUTABLE}")
    endif()

    if(NOT "${_resolvedLreleaseExecutable}" STREQUAL "")
        if(NOT "${_registeredLreleaseExecutable}" STREQUAL "${_resolvedLreleaseExecutable}")
            CMagnetoInternal__register_tool("Qt_lrelease" "${_resolvedLreleaseExecutable}")
            CMagnetoInternal__message(STATUS "Qt lrelease found at \"${_resolvedLreleaseExecutable}\".")
        endif()
        set(${oQT_LRELEASE_EXECUTABLE} "${_resolvedLreleaseExecutable}" PARENT_SCOPE)
        return()
    endif()

    if(NOT "${_registeredLreleaseExecutable}" STREQUAL "")
        set(${oQT_LRELEASE_EXECUTABLE} "${_registeredLreleaseExecutable}" PARENT_SCOPE)
        return()
    endif()

    find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
    get_target_property(_lreleaseLocation Qt6::lrelease LOCATION)
    if(NOT "${_lreleaseLocation}" STREQUAL "")
        CMagnetoInternal__register_tool("Qt_lrelease" "${_lreleaseLocation}")
        set(${oQT_LRELEASE_EXECUTABLE} "${_lreleaseLocation}" PARENT_SCOPE)
        CMagnetoInternal__message(STATUS "Qt lrelease found at \"${_lreleaseLocation}\".")
        return()
    endif()

    CMagnetoInternal__message(FATAL_ERROR "Qt lrelease not found.")
endfunction()
