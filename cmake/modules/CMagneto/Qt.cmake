# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines general-purpose functions and variables to simplify Qt integration.
]]


function(CMagneto__find__Qt_lrelease_executable oQT_LRELEASE_EXECUTABLE)
    #set(QT_LRELEASE_EXECUTABLE "${QT_LRELEASE_EXECUTABLE}" CACHE FILEPATH "Path to Qt lrelease executable" FORCE)

    if(DEFINED QT_LRELEASE_EXECUTABLE AND NOT QT_LRELEASE_EXECUTABLE STREQUAL "")
        set(${oQT_LRELEASE_EXECUTABLE} "${QT_LRELEASE_EXECUTABLE}" PARENT_SCOPE)
        CMagnetoInternal__message(STATUS "Qt lrelease found at \"${QT_LRELEASE_EXECUTABLE}\".")
        return()
    endif()

    if(DEFINED QT6_LRELEASE_EXECUTABLE AND NOT QT6_LRELEASE_EXECUTABLE STREQUAL "")
        set(${oQT_LRELEASE_EXECUTABLE} "${QT6_LRELEASE_EXECUTABLE}" PARENT_SCOPE)
        CMagnetoInternal__message(STATUS "Qt lrelease found at \"${QT6_LRELEASE_EXECUTABLE}\".")
        return()
    endif()

    if(DEFINED Qt6_LRELEASE_EXECUTABLE AND NOT Qt6_LRELEASE_EXECUTABLE STREQUAL "")
        set(${oQT_LRELEASE_EXECUTABLE} "${Qt6_LRELEASE_EXECUTABLE}" PARENT_SCOPE)
        CMagnetoInternal__message(STATUS "Qt lrelease found at \"${Qt6_LRELEASE_EXECUTABLE}\".")
        return()
    endif()

    find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
    get_target_property(_lreleaseLocation Qt6::lrelease LOCATION)
    if(NOT _lreleaseLocation STREQUAL "")
        set(${oQT_LRELEASE_EXECUTABLE} "${_lreleaseLocation}" PARENT_SCOPE)
        CMagnetoInternal__message(STATUS "Qt lrelease found at \"${_lreleaseLocation}\".")
        return()
    endif()

    CMagnetoInternal__message(FATAL_ERROR "Qt lrelease not found.")
endfunction()
