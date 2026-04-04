# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

#[[
    Internal process-wide tool registry for one CMake configure run.

    Tools are stored in a GLOBAL property so repeated lookups can be avoided while
    remaining independent from cache variables and install-tree artifacts.

    The registry lives inside the current CMake process, so it works both for
    normal standalone projects and for superbuild-style configure runs in which
    CMagneto is used from a larger top-level project.
]]

set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTools "")


#[[
    CMagnetoInternal__register_tool

    Registers or updates a resolved tool path under a stable tool id.

    Parameters:
        iToolId      - Stable ASCII identifier, for example `Qt_lrelease`.
        iToolAbsPath - Resolved absolute path to the tool executable.
]]
function(CMagnetoInternal__register_tool iToolId iToolAbsPath)
    if("${iToolId}" STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__register_tool: tool id must not be empty.")
    endif()

    get_property(_registeredTools GLOBAL PROPERTY CMagnetoInternal__RegisteredTools)
    if(NOT DEFINED _registeredTools OR "${_registeredTools}" STREQUAL "")
        set(_registeredTools "")
    endif()

    list(FIND _registeredTools "${iToolId}" _toolIdIndex)
    if(_toolIdIndex EQUAL -1)
        list(APPEND _registeredTools "${iToolId}" "${iToolAbsPath}")
    else()
        math(EXPR _toolPathIndex "${_toolIdIndex} + 1")
        list(REMOVE_AT _registeredTools ${_toolPathIndex})
        list(INSERT _registeredTools ${_toolPathIndex} "${iToolAbsPath}")
    endif()

    set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTools "${_registeredTools}")
endfunction()


#[[
    CMagnetoInternal__find_registered_tool

    Looks up a previously registered tool path.

    Returns:
        oToolAbsPath - Registered tool path, or an empty string if the tool is not
                       registered yet in the current configure run.
]]
function(CMagnetoInternal__find_registered_tool iToolId oToolAbsPath)
    if("${iToolId}" STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__find_registered_tool: tool id must not be empty.")
    endif()

    get_property(_registeredTools GLOBAL PROPERTY CMagnetoInternal__RegisteredTools)
    if(NOT DEFINED _registeredTools OR "${_registeredTools}" STREQUAL "")
        set(${oToolAbsPath} "" PARENT_SCOPE)
        return()
    endif()

    list(FIND _registeredTools "${iToolId}" _toolIdIndex)
    if(_toolIdIndex EQUAL -1)
        set(${oToolAbsPath} "" PARENT_SCOPE)
        return()
    endif()

    math(EXPR _toolPathIndex "${_toolIdIndex} + 1")
    list(GET _registeredTools ${_toolPathIndex} _toolAbsPath)
    set(${oToolAbsPath} "${_toolAbsPath}" PARENT_SCOPE)
endfunction()
