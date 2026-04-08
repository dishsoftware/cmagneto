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
    This submodule of the CMagneto module defines general-purpose functions for path handling.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/PathTools_Internals.cmake")


#[[
    CMagneto__are_paths_equal

    Resolves variables and "..", and then compares paths.
]]
function(CMagneto__are_paths_equal iPathA iPathB oAreEqual)
    cmake_path(SET _normalizedPathA NORMALIZE "${iPathA}")
    cmake_path(SET _normalizedPathB NORMALIZE "${iPathB}")
    if("${_normalizedPathA}" STREQUAL "${_normalizedPathB}")
        set(${oAreEqual} TRUE PARENT_SCOPE)
    else()
        set(${oAreEqual} FALSE PARENT_SCOPE)
    endif()
endfunction()


function(CMagneto__does_path_contain_backslash iPath oPathContainsBackslash)
    string(FIND "${iPath}" "\\" _backslashPos)
    if(_backslashPos EQUAL -1)
        set(${oPathContainsBackslash} FALSE PARENT_SCOPE)
    else()
        set(${oPathContainsBackslash} TRUE PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagneto__is_path_under_dir

    Checks, if iAbsolutePath is under iAbsoluteDirPath (in the dir or its subdirectory recursively).
    iAbsolutePath == iAbsoluteDirPath yields TRUE.
]]
function(CMagneto__is_path_under_dir iAbsolutePath iAbsoluteDirPath oPathIsUnderDir)
    if(NOT IS_ABSOLUTE "${iAbsolutePath}")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__is_path_under_dir: iAbsolutePath is not absolute: \"${iAbsolutePath}\".")
    endif()
    if(NOT IS_ABSOLUTE "${iAbsoluteDirPath}")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__is_path_under_dir: iAbsoluteDirPath is not absolute: \"${iAbsoluteDirPath}\".")
    endif()

    cmake_path(SET _normalizedPath NORMALIZE "${iAbsolutePath}")
    cmake_path(SET _normalizedDirPath NORMALIZE "${iAbsoluteDirPath}")

    if("${_normalizedPath}" STREQUAL "${_normalizedDirPath}")
        set(${oPathIsUnderDir} TRUE PARENT_SCOPE)
    else()
        cmake_path(APPEND _normalizedDirPath "")
        string(FIND "${_normalizedPath}" "${_normalizedDirPath}" _pos)

        # Check if the path starts with the dir.
        if(_pos EQUAL 0)
            set(${oPathIsUnderDir} TRUE PARENT_SCOPE)
        else()
            set(${oPathIsUnderDir} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()


function(CMagneto__get_dir_relative_to_project_source_root iAbsoluteDir oDirRelativeToProjectSourceRoot)
    cmake_path(RELATIVE_PATH iAbsoluteDir BASE_DIRECTORY "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}/" OUTPUT_VARIABLE _dirRelativeToProjectSourceRoot)
    cmake_path(SET _dirRelativeToProjectSourceRoot NORMALIZE "${_dirRelativeToProjectSourceRoot}")
    # Avoid "." paths, bacause some CMake generators do not handle them correctly.
    if (_dirRelativeToProjectSourceRoot STREQUAL ".")
        set(_dirRelativeToProjectSourceRoot "")
    endif()
    set(${oDirRelativeToProjectSourceRoot} "${_dirRelativeToProjectSourceRoot}" PARENT_SCOPE)
endfunction()


function(CMagneto__get_dir_relative_to_sources_root iAbsoluteDir oDirRelativeToSourcesRoot)
    cmake_path(RELATIVE_PATH iAbsoluteDir BASE_DIRECTORY "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_ROOT}/" OUTPUT_VARIABLE _dirRelativeToSourcesRoot)
    cmake_path(SET _dirRelativeToSourcesRoot NORMALIZE "${_dirRelativeToSourcesRoot}")
    if(_dirRelativeToSourcesRoot STREQUAL ".")
        set(_dirRelativeToSourcesRoot "")
    endif()
    set(${oDirRelativeToSourcesRoot} "${_dirRelativeToSourcesRoot}" PARENT_SCOPE)
endfunction()
