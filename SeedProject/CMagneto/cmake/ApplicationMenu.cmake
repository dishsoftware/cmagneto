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

#[[
    CMagnetoInternal__application_menu__normalize_installed_file_path

    Validates that an installed file path is non-empty and relative to the install
    prefix, then normalizes it to a forward-slash-separated canonical form.

    This helper is used before application-menu metadata is stored so downstream
    packagers can rely on install-prefix-relative paths such as `bin/MyApp` rather
    than having to handle absolute paths or mixed separators.
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

#[[
    CMagnetoInternal__application_menu__make_entry_id

    Derives a stable, filesystem-friendly identifier from a user-visible menu
    entry name.

    The identifier is lowercased, reduced to `[a-z0-9_]`, stripped of leading
    and trailing underscores, and uniquified against previously registered
    application-menu entries in the current configure run.

    The resulting id is used for generated asset names such as launcher icons and
    `.desktop` files.
]]
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

#[[
    CMagnetoInternal__application_menu__register_entry

    Registers one application-menu entry backed by an install-prefix-relative
    target file or helper file.

    Icon inputs may be provided either as source-root-relative paths
    (`WINDOWS_ICON`, `LINUX_ICON`) or as already-resolved absolute paths
    (`WINDOWS_ICON_ABS_PATH`, `LINUX_ICON_ABS_PATH`).

    Stored metadata:
    - generated entry id
    - user-visible entry name
    - normalized installed file path
    - installed Windows icon path, if provided
    - installed Linux icon path, if provided

    Side effects:
    - installs the optional Windows and Linux icon assets into
      `${CMagneto__SUBDIR_APPLICATION_MENU_ASSETS}icons/`
    - appends one logical record to the global
      `CMagnetoInternal__ApplicationMenuEntries` registry

    That registry is later consumed by packager-specific backends, currently:
    - IFW on Windows for Start Menu shortcuts
    - DEB on Linux for `.desktop` launchers
]]
function(CMagnetoInternal__application_menu__register_entry iEntryName iInstalledFilePath)
    cmake_parse_arguments(ARG "" "WINDOWS_ICON;LINUX_ICON;WINDOWS_ICON_ABS_PATH;LINUX_ICON_ABS_PATH" "" ${ARGN})

    if(iEntryName STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration for installed file \"${iInstalledFilePath}\": NAME must be specified.")
    endif()

    CMagnetoInternal__application_menu__normalize_installed_file_path("${iInstalledFilePath}" _normalizedInstalledFilePath)
    CMagnetoInternal__application_menu__make_entry_id("${iEntryName}" _entryId)

    if(NOT ARG_WINDOWS_ICON STREQUAL "" AND NOT ARG_WINDOWS_ICON_ABS_PATH STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration for installed file \"${iInstalledFilePath}\": WINDOWS_ICON and WINDOWS_ICON_ABS_PATH are mutually exclusive.")
    endif()

    if(NOT ARG_LINUX_ICON STREQUAL "" AND NOT ARG_LINUX_ICON_ABS_PATH STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto application-menu registration for installed file \"${iInstalledFilePath}\": LINUX_ICON and LINUX_ICON_ABS_PATH are mutually exclusive.")
    endif()

    set(_windowsIconInstallRelPath "")
    if(NOT ARG_WINDOWS_ICON STREQUAL "" OR NOT ARG_WINDOWS_ICON_ABS_PATH STREQUAL "")
        if(NOT ARG_WINDOWS_ICON_ABS_PATH STREQUAL "")
            set(_windowsIconAbsPath "${ARG_WINDOWS_ICON_ABS_PATH}")
            cmake_path(GET _windowsIconAbsPath EXTENSION _windowsIconExtension)
        else()
            set(_baseDirDescription "application-menu entry \"${iEntryName}\"")
            CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription} Windows icon" "${ARG_WINDOWS_ICON}"
                OUTPUT_ABS_PATHS _windowsIconAbsPaths
                OUTPUT_REL_PATHS _windowsIconRelPaths
                IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
                ALLOW_PATHS_UNDER_BUILD_BASE_DIR
            )
            list(GET _windowsIconAbsPaths 0 _windowsIconAbsPath)
            list(GET _windowsIconRelPaths 0 _windowsIconRelPath)
            cmake_path(GET _windowsIconRelPath EXTENSION _windowsIconExtension)
        endif()
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
    if(NOT ARG_LINUX_ICON STREQUAL "" OR NOT ARG_LINUX_ICON_ABS_PATH STREQUAL "")
        if(NOT ARG_LINUX_ICON_ABS_PATH STREQUAL "")
            set(_linuxIconAbsPath "${ARG_LINUX_ICON_ABS_PATH}")
            cmake_path(GET _linuxIconAbsPath EXTENSION _linuxIconExtension)
        else()
            set(_baseDirDescription "application-menu entry \"${iEntryName}\"")
            CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription} Linux icon" "${ARG_LINUX_ICON}"
                OUTPUT_ABS_PATHS _linuxIconAbsPaths
                OUTPUT_REL_PATHS _linuxIconRelPaths
                IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
                ALLOW_PATHS_UNDER_BUILD_BASE_DIR
            )
            list(GET _linuxIconAbsPaths 0 _linuxIconAbsPath)
            list(GET _linuxIconRelPaths 0 _linuxIconRelPath)
            cmake_path(GET _linuxIconRelPath EXTENSION _linuxIconExtension)
        endif()
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
    NAME - Display name of the menu entry.

    Notes:
    - The executable target itself must already exist.
    - The registered target path is derived from the target's installed executable
      output name under `${CMagneto__SUBDIR_EXECUTABLE}`.
    - The function reuses executable icon metadata previously declared through
      `CMagneto__bind_icon_to_executable(...)`.
    - This function only registers menu integration metadata and related icon
      assets; it does not itself create shortcuts or `.desktop` files.
]]
function(CMagneto__add_executable_to_application_menu iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__add_executable_to_application_menu")

    cmake_parse_arguments(ARG "" "NAME" "" ${ARGN})
    if(ARG_NAME STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__add_executable_to_application_menu(\"${iExeTargetName}\"): NAME must be specified.")
    endif()

    CMagneto__compose_binary_OUTPUT_NAME("${iExeTargetName}" _binaryOutputNameWE)
    CMagneto__platform__add_executable_extension("${_binaryOutputNameWE}" _binaryOutputName)
    set(_installedFilePath "${CMagneto__SUBDIR_EXECUTABLE}${_binaryOutputName}")

    CMagnetoInternal__get_executable_icon_metadata("${iExeTargetName}" _windowsIconAbsPath _linuxIconAbsPath _macIconAbsPath)

    CMagnetoInternal__application_menu__register_entry("${ARG_NAME}" "${_installedFilePath}"
        WINDOWS_ICON_ABS_PATH "${_windowsIconAbsPath}"
        LINUX_ICON_ABS_PATH "${_linuxIconAbsPath}"
    )
endfunction()

#[[
    CMagneto__add_installed_file_to_application_menu

    Registers an installed file, specified relative to the installation prefix, as an application-menu entry.

    Named arguments:
    NAME         - Display name of the menu entry.
    WINDOWS_ICON - Optional `.ico` file to use for Windows launcher shortcuts.
    LINUX_ICON   - Optional Linux icon asset used by Linux launcher backends such
                   as the DEB `.desktop` integration.

    Notes:
    - `iInstalledFilePath` must be relative to the final installation prefix.
    - Use this overload when the launcher target is not a CMake executable target
      owned by the current configure scope.
    - As with the executable-target overload, this function only registers menu
      integration metadata and related icon assets.
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
