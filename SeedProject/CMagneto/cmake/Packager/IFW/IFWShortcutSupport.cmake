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

include("${CMAKE_CURRENT_LIST_DIR}/IFWScriptSupport.cmake")

function(CMagnetoInternal__ifw__generate_windows_shortcut_component_script_text oScriptText)
    if(NOT WIN32)
        set(${oScriptText} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_applicationMenuEntries GLOBAL PROPERTY CMagnetoInternal__ApplicationMenuEntries)
    list(LENGTH _applicationMenuEntries _entriesCount)
    if(_entriesCount EQUAL 0)
        set(${oScriptText} "" PARENT_SCOPE)
        return()
    endif()

    set(_scriptText [=[
Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType !== "windows")
        return;
]=])

    math(EXPR _lastEntryIndex "${_entriesCount} - 5")
    foreach(_entryIndex RANGE 0 ${_lastEntryIndex} 5)
        math(EXPR _nameIndex "${_entryIndex} + 1")
        math(EXPR _targetPathIndex "${_entryIndex} + 2")
        math(EXPR _windowsIconInstallPathIndex "${_entryIndex} + 3")

        list(GET _applicationMenuEntries ${_nameIndex} _entryName)
        list(GET _applicationMenuEntries ${_targetPathIndex} _installedFileRelPath)
        list(GET _applicationMenuEntries ${_windowsIconInstallPathIndex} _windowsIconInstallPath)

        cmake_path(GET _installedFileRelPath PARENT_PATH _shortcutWorkingDirRelPath)
        if(_shortcutWorkingDirRelPath STREQUAL "")
            set(_shortcutWorkingDirectory "@TargetDir@")
        else()
            set(_shortcutWorkingDirectory "@TargetDir@/${_shortcutWorkingDirRelPath}")
        endif()

        set(_shortcutTargetPath "@TargetDir@/${_installedFileRelPath}")
        set(_shortcutLinkPath "@StartMenuDir@/${_entryName}.lnk")
        set(_shortcutDescription "Open ${_entryName}")

        CMagnetoInternal__ifw__escape_js_string("${_shortcutTargetPath}" _shortcutTargetPathEscaped)
        CMagnetoInternal__ifw__escape_js_string("${_shortcutWorkingDirectory}" _shortcutWorkingDirectoryEscaped)
        CMagnetoInternal__ifw__escape_js_string("${_shortcutLinkPath}" _shortcutLinkPathEscaped)
        CMagnetoInternal__ifw__escape_js_string("${_shortcutDescription}" _shortcutDescriptionEscaped)

        string(APPEND _scriptText
            "\n"
            "    component.addOperation(\"CreateShortcut\", \"${_shortcutTargetPathEscaped}\", \"${_shortcutLinkPathEscaped}\",\n"
            "        \"workingDirectory=${_shortcutWorkingDirectoryEscaped}\""
        )

        if(NOT _windowsIconInstallPath STREQUAL "")
            set(_shortcutIconPath "@TargetDir@/${_windowsIconInstallPath}")
            CMagnetoInternal__ifw__escape_js_string("${_shortcutIconPath}" _shortcutIconPathEscaped)
            string(APPEND _scriptText ", \"iconPath=${_shortcutIconPathEscaped}\"")
        endif()

        string(APPEND _scriptText ", \"description=${_shortcutDescriptionEscaped}\");\n")
    endforeach()

    string(APPEND _scriptText [=[
}
]=])

    set(${oScriptText} "${_scriptText}" PARENT_SCOPE)
endfunction()
