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

#[[
    This submodule defines functions to register installed files for application-menu integration.
]]

function(CMagnetoInternal__application_menu__normalize_installed_file_path iInstalledFilePath oNormalizedPath)
    set(_path "${iInstalledFilePath}")
    string(REPLACE "\\" "/" _path "${_path}")

    if(_path STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration: installed file path is empty.")
    endif()

    cmake_path(IS_ABSOLUTE _path _isAbsolute)
    if(_isAbsolute)
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration: installed file path \"${iInstalledFilePath}\" must be relative to the installation prefix.")
    endif()

    string(REGEX REPLACE "^/+" "" _path "${_path}")
    cmake_path(NORMAL_PATH _path OUTPUT_VARIABLE _normalizedPath)
    set(${oNormalizedPath} "${_normalizedPath}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__application_menu__make_entry_id iEntryName oEntryId)
    string(TOLOWER "${iEntryName}" _entryId)
    string(REGEX REPLACE "[^a-z0-9]+" "_" _entryId "${_entryId}")
    string(REGEX REPLACE "^_+" "" _entryId "${_entryId}")
    string(REGEX REPLACE "_+$" "" _entryId "${_entryId}")
    if(_entryId STREQUAL "")
        set(_entryId "application_menu_entry")
    endif()

    get_property(_entryIds GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntryIds)
    if(NOT _entryIds)
        set(_entryIds "")
    endif()

    set(_candidateEntryId "${_entryId}")
    set(_suffix 2)
    while(TRUE)
        list(FIND _entryIds "${_candidateEntryId}" _existingEntryIndex)
        if(_existingEntryIndex EQUAL -1)
            break()
        endif()

        set(_candidateEntryId "${_entryId}_${_suffix}")
        math(EXPR _suffix "${_suffix} + 1")
    endwhile()

    list(APPEND _entryIds "${_candidateEntryId}")
    set_property(GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntryIds "${_entryIds}")
    set(${oEntryId} "${_candidateEntryId}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__application_menu__register_entry iEntryName iInstalledFilePath)
    cmake_parse_arguments(ARG "" "WINDOWS_ICON;LINUX_ICON" "" ${ARGN})

    if(iEntryName STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration for installed file \"${iInstalledFilePath}\": NAME must be specified.")
    endif()

    CMagnetoInternal__application_menu__normalize_installed_file_path("${iInstalledFilePath}" _normalizedInstalledFilePath)
    CMagnetoInternal__application_menu__make_entry_id("${iEntryName}" _entryId)

    set(_baseDirDescription "application-menu entry \"${iEntryName}\"")
    set(_windowsIconInstallRelPath "")
    if(NOT ARG_WINDOWS_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription} Windows icon" "${ARG_WINDOWS_ICON}"
            OUTPUT_ABS_PATHS _windowsIconAbsPaths
            OUTPUT_REL_PATHS _windowsIconRelPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _windowsIconAbsPaths 0 _windowsIconAbsPath)
        list(GET _windowsIconRelPaths 0 _windowsIconRelPath)
        cmake_path(GET _windowsIconRelPath EXTENSION _windowsIconExtension)
        if(_windowsIconExtension STREQUAL "")
            set(_windowsIconExtension ".ico")
        endif()

        set(_windowsIconInstallDir "${CMagneto__SUBDIR_APPLICATION_MENU_ASSETS}icons")
        set(_windowsIconInstallName "${_entryId}${_windowsIconExtension}")
        set(_windowsIconInstallRelPath "${_windowsIconInstallDir}/${_windowsIconInstallName}")

        install(FILES "${_windowsIconAbsPath}"
            DESTINATION "${_windowsIconInstallDir}"
            RENAME "${_windowsIconInstallName}"
            COMPONENT "${CMagneto__COMPONENT__RUNTIME}"
        )
    endif()

    set(_linuxIconInstallRelPath "")
    if(NOT ARG_LINUX_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription} Linux icon" "${ARG_LINUX_ICON}"
            OUTPUT_ABS_PATHS _linuxIconAbsPaths
            OUTPUT_REL_PATHS _linuxIconRelPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _linuxIconAbsPaths 0 _linuxIconAbsPath)
        list(GET _linuxIconRelPaths 0 _linuxIconRelPath)
        cmake_path(GET _linuxIconRelPath EXTENSION _linuxIconExtension)
        if(_linuxIconExtension STREQUAL "")
            set(_linuxIconExtension ".png")
        endif()

        set(_linuxIconInstallDir "${CMagneto__SUBDIR_APPLICATION_MENU_ASSETS}icons")
        set(_linuxIconInstallName "${_entryId}${_linuxIconExtension}")
        set(_linuxIconInstallRelPath "${_linuxIconInstallDir}/${_linuxIconInstallName}")

        install(FILES "${_linuxIconAbsPath}"
            DESTINATION "${_linuxIconInstallDir}"
            RENAME "${_linuxIconInstallName}"
            COMPONENT "${CMagneto__COMPONENT__RUNTIME}"
        )
    endif()

    get_property(_applicationMenuEntries GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntries)
    list(APPEND _applicationMenuEntries
        "${_entryId}"
        "${iEntryName}"
        "${_normalizedInstalledFilePath}"
        "${_windowsIconInstallRelPath}"
        "${_linuxIconInstallRelPath}"
    )
    set_property(GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntries "${_applicationMenuEntries}")
endfunction()

#[[
    CMagneto__add_executable_to_application_menu

    Registers an executable target as an application-menu entry.

    Named arguments:
    NAME         - Display name of the menu entry.
    WINDOWS_ICON - Optional `.ico` file to use for Windows launcher shortcuts.
    LINUX_ICON   - Optional Linux icon asset reserved for Linux launcher backends.
]]
function(CMagneto__add_executable_to_application_menu iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__add_executable_to_application_menu")

    cmake_parse_arguments(ARG "" "NAME;WINDOWS_ICON;LINUX_ICON" "" ${ARGN})
    if(ARG_NAME STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__add_executable_to_application_menu(\"${iExeTargetName}\"): NAME must be specified.")
    endif()

    CMagneto__compose_binary_OUTPUT_NAME("${iExeTargetName}" _binaryOutputNameWE)
    CMagneto__platform__add_executable_extension("${_binaryOutputNameWE}" _binaryOutputName)
    set(_installedFilePath "${CMagneto__SUBDIR_EXECUTABLE}${_binaryOutputName}")

    CMagnetoInternal__application_menu__register_entry("${ARG_NAME}" "${_installedFilePath}"
        WINDOWS_ICON "${ARG_WINDOWS_ICON}"
        LINUX_ICON "${ARG_LINUX_ICON}"
    )
endfunction()

#[[
    CMagneto__add_installed_file_to_application_menu

    Registers an installed file, specified relative to the installation prefix, as an application-menu entry.

    Named arguments:
    NAME         - Display name of the menu entry.
    WINDOWS_ICON - Optional `.ico` file to use for Windows launcher shortcuts.
    LINUX_ICON   - Optional Linux icon asset reserved for Linux launcher backends.
]]
function(CMagneto__add_installed_file_to_application_menu iInstalledFilePath)
    cmake_parse_arguments(ARG "" "NAME;WINDOWS_ICON;LINUX_ICON" "" ${ARGN})
    if(ARG_NAME STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__add_installed_file_to_application_menu(\"${iInstalledFilePath}\"): NAME must be specified.")
    endif()

    CMagnetoInternal__application_menu__register_entry("${ARG_NAME}" "${iInstalledFilePath}"
        WINDOWS_ICON "${ARG_WINDOWS_ICON}"
        LINUX_ICON "${ARG_LINUX_ICON}"
    )
endfunction()
