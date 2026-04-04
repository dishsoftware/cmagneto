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
    Escapes a value for use in a `.desktop` file field.

    The function keeps the output suitable for plain key/value desktop-entry lines
    by normalizing embedded newlines to the escaped `\n` form and preserving literal
    backslashes.
]]
function(CMagnetoInternal__deb__escape_desktop_entry_value iInputText oEscapedText)
    set(_text "${iInputText}")
    string(REPLACE "\\" "\\\\" _text "${_text}")
    string(REPLACE "\r" "" _text "${_text}")
    string(REPLACE "\n" "\\n" _text "${_text}")
    set(${oEscapedText} "${_text}" PARENT_SCOPE)
endfunction()

#[[
    Escapes an executable path for the `Exec=` field of a `.desktop` file.

    The generated value is always wrapped in double quotes so install prefixes or
    executable names containing spaces remain launchable from desktop environments.
]]
function(CMagnetoInternal__deb__escape_desktop_exec_argument iInputText oEscapedText)
    set(_text "${iInputText}")
    string(REPLACE "\\" "\\\\" _text "${_text}")
    string(REPLACE "\"" "\\\"" _text "${_text}")
    string(REPLACE "$" "\\$" _text "${_text}")
    string(REPLACE "`" "\\`" _text "${_text}")
    set(${oEscapedText} "\"${_text}\"" PARENT_SCOPE)
endfunction()

#[[
    CMagnetoInternal__deb__write_linux_desktop_entry_assets

    Generates Linux desktop-entry assets for application-menu registrations when the
    DEB packager is active.

    The function consumes the global `CMagnetoInternal__ApplicationMenuEntries`
    registry populated by `ApplicationMenu.cmake`, writes one generated `.desktop`
    file per registered entry, and installs those generated files into the package's
    own install tree under:

        ${CMagneto__SUBDIR_APPLICATION_MENU_ASSETS}desktop-entries/

    For DEB packaging, the function also stages each generated launcher into
    `/usr/share/applications/` while the package is being assembled.

    As a result, the finished `.deb` contains those launcher files as normal
    package-owned assets, and installing the package installs them into
    `/usr/share/applications/` on the target machine.

    Linux icon handling:
    - `Icon=` is written as an absolute path inside the installed package tree.
    - This is intentionally simpler than icon-theme registration and avoids requiring
      extra `/usr/share/icons/...` integration for the current DEB workflow.
    - The referenced icon file is still package-owned because the icon itself is
      installed through the regular CMake install rules created by
      `ApplicationMenu.cmake`.

    Safety notes:
    - Plain `cmake --install --prefix ...` must remain local and must not try to
      write into `/usr/share/...`.
    - To enforce that, the `/usr/share/applications/...` copy step is guarded by the
      `CMagnetoInternal__IS_CPACK_INSTALL` variable, which is injected only for CPack
      package staging through `CPACK_CUSTOM_INSTALL_VARIABLES`.
]]
function(CMagnetoInternal__deb__write_linux_desktop_entry_assets)
    get_property(_applicationMenuEntries GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntries)
    list(LENGTH _applicationMenuEntries _entriesCount)
    if(_entriesCount EQUAL 0)
        return()
    endif()

    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_TMP}")
    set(_generatedFilesDir "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_TMP}/CMagnetoGeneratedDebDesktopEntries")
    file(MAKE_DIRECTORY "${_generatedFilesDir}")

    set(_desktopAssetInstallDir "${CMagneto__SUBDIR_APPLICATION_MENU_ASSETS}desktop-entries")

    math(EXPR _lastEntryIndex "${_entriesCount} - 5")
    foreach(_entryIndex RANGE 0 ${_lastEntryIndex} 5)
        math(EXPR _nameIndex "${_entryIndex} + 1")
        math(EXPR _targetPathIndex "${_entryIndex} + 2")
        math(EXPR _linuxIconInstallPathIndex "${_entryIndex} + 4")

        list(GET _applicationMenuEntries ${_entryIndex} _entryId)
        list(GET _applicationMenuEntries ${_nameIndex} _entryName)
        list(GET _applicationMenuEntries ${_targetPathIndex} _installedFileRelPath)
        list(GET _applicationMenuEntries ${_linuxIconInstallPathIndex} _linuxIconInstallPath)

        set(_desktopFileName "${CMagneto__PACKAGING_JSON__PACKAGE_ID}.${_entryId}.desktop")
        set(_desktopAssetInstallRelPath "${_desktopAssetInstallDir}/${_desktopFileName}")
        set(_desktopAssetSourcePath "${_generatedFilesDir}/${_desktopFileName}")

        cmake_path(SET _launcherTargetAbsPath NORMALIZE "${CPACK_PACKAGING_INSTALL_PREFIX}/${_installedFileRelPath}")
        cmake_path(GET _installedFileRelPath PARENT_PATH _launcherWorkingDirRelPath)
        if(_launcherWorkingDirRelPath STREQUAL "")
            set(_launcherWorkingDirAbsPath "${CPACK_PACKAGING_INSTALL_PREFIX}")
        else()
            cmake_path(SET _launcherWorkingDirAbsPath NORMALIZE "${CPACK_PACKAGING_INSTALL_PREFIX}/${_launcherWorkingDirRelPath}")
        endif()

        CMagnetoInternal__deb__escape_desktop_entry_value("${_entryName}" _entryNameEscaped)
        CMagnetoInternal__deb__escape_desktop_entry_value("${CMagneto__PROJECT_JSON__PROJECT_DESCRIPTION}" _entryCommentEscaped)
        CMagnetoInternal__deb__escape_desktop_entry_value("${_launcherWorkingDirAbsPath}" _launcherWorkingDirEscaped)
        CMagnetoInternal__deb__escape_desktop_entry_value("${_launcherTargetAbsPath}" _launcherTryExecEscaped)
        CMagnetoInternal__deb__escape_desktop_exec_argument("${_launcherTargetAbsPath}" _launcherExecEscaped)

        set(_desktopEntryLines
            "[Desktop Entry]"
            "Version=1.0"
            "Type=Application"
            "Name=${_entryNameEscaped}"
            "Comment=${_entryCommentEscaped}"
            "Exec=${_launcherExecEscaped}"
            "TryExec=${_launcherTryExecEscaped}"
            "Path=${_launcherWorkingDirEscaped}"
            "Terminal=false"
            "Categories=Utility\\;"
            "StartupNotify=true"
        )

        if(NOT _linuxIconInstallPath STREQUAL "")
            cmake_path(SET _launcherIconAbsPath NORMALIZE "${CPACK_PACKAGING_INSTALL_PREFIX}/${_linuxIconInstallPath}")
            CMagnetoInternal__deb__escape_desktop_entry_value("${_launcherIconAbsPath}" _launcherIconEscaped)
            list(APPEND _desktopEntryLines "Icon=${_launcherIconEscaped}")
        endif()

        list(JOIN _desktopEntryLines "\n" _desktopEntryText)
        string(APPEND _desktopEntryText "\n")
        file(WRITE "${_desktopAssetSourcePath}" "${_desktopEntryText}")

        install(FILES "${_desktopAssetSourcePath}"
            DESTINATION "${_desktopAssetInstallDir}"
            COMPONENT "${CMagneto__COMPONENT__RUNTIME}"
        )

        cmake_path(SET _desktopMenuInstallPath NORMALIZE "/usr/share/applications/${_desktopFileName}")
        string(CONFIGURE [=[
if(CMagnetoInternal__IS_CPACK_INSTALL)
    file(MAKE_DIRECTORY "$ENV{DESTDIR}/usr/share/applications")
    file(COPY_FILE
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/@_desktopAssetInstallRelPath@"
        "$ENV{DESTDIR}@_desktopMenuInstallPath@"
        ONLY_IF_DIFFERENT
    )
endif()
]=] _installDesktopEntryCode @ONLY)
        install(CODE "${_installDesktopEntryCode}" COMPONENT "${CMagneto__COMPONENT__RUNTIME}")
    endforeach()
endfunction()
