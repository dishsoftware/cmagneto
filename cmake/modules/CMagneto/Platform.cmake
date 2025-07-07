# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines general-purpose functions and constants for platform handling.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/Platform_Internals.cmake")


#[[
    CMagneto__platform__add_executable_extension

    Returns the input path to a shell script, defined without a platform-dependent extension,
    appended with the appropriate extension.
]]
function(CMagneto__platform__add_executable_extension iExePathWE oExePath)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_exePath "${iExePathWE}.exe")
    else()
        set(_exePath "${iExePathWE}")
    endif()
    set(${oExePath} "${_exePath}" PARENT_SCOPE)
endfunction()


#[[
    CMagneto__platform__add_script_extension

    Returns the input path to a shell script, defined without a platform-dependent extension,
    appended with the appropriate extension.
]]
function(CMagneto__platform__add_script_extension iShellScriptPathWE oShellScriptPath)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_shellScriptPath "${iShellScriptPathWE}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_shellScriptPath "${iShellScriptPathWE}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()
    set(${oShellScriptPath} "${_shellScriptPath}" PARENT_SCOPE)
endfunction()


#[[
    CMagneto__platform__add_script_suffix_and_extension

    Returns the input path to a shell script, defined without platfrom-dependent suffix and extension,
    appended with the appropriate suffix and extension.
]]
function(CMagneto__platform__add_script_suffix_and_extension iShellScriptPathWSuffixAndE oShellScriptPath)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_shellScriptPath "${iShellScriptPathWSuffixAndE}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_shellScriptPath "${iShellScriptPathWSuffixAndE}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()
    set(${oShellScriptPath} "${_shellScriptPath}" PARENT_SCOPE)
endfunction()