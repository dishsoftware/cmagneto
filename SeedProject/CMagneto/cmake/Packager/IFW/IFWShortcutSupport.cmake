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

    if(NOT (CMagnetoInternal__IFW__CREATE_START_MENU_SHORTCUT OR CMagnetoInternal__IFW__CREATE_DESKTOP_SHORTCUT))
        set(${oScriptText} "" PARENT_SCOPE)
        return()
    endif()

    CMagneto__get_project_entrypoint(_entrypointExeTargetName)
    if(_entrypointExeTargetName STREQUAL "")
        CMagnetoInternal__message(WARNING "CMagneto IFW shortcut generation is enabled, but the project entrypoint executable target is not set. Windows shortcuts will not be created.")
        set(${oScriptText} "" PARENT_SCOPE)
        return()
    endif()

    CMagneto__compose_binary_OUTPUT_NAME("${_entrypointExeTargetName}" _entrypointBinaryNameWE)
    CMagneto__platform__add_executable_extension("${_entrypointBinaryNameWE}" _entrypointBinaryName)
    set(_shortcutInstallSubdir "${CMagneto__SUBDIR_EXECUTABLE}")
    string(REGEX REPLACE "/+$" "" _shortcutInstallSubdir "${_shortcutInstallSubdir}")

    set(_shortcutTargetPath "@TargetDir@/${_shortcutInstallSubdir}/${_entrypointBinaryName}")
    set(_shortcutWorkingDirectory "@TargetDir@/${_shortcutInstallSubdir}")
    set(_shortcutDescription "Launch ${CMagneto__PROJECT_JSON__PROJECT_NAME_FOR_UI}")

    CMagnetoInternal__ifw__escape_js_string("${_shortcutTargetPath}" _shortcutTargetPathEscaped)
    CMagnetoInternal__ifw__escape_js_string("${_shortcutWorkingDirectory}" _shortcutWorkingDirectoryEscaped)
    CMagnetoInternal__ifw__escape_js_string("${_shortcutDescription}" _shortcutDescriptionEscaped)

    set(_scriptText [=[
Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType !== "windows")
        return;
]=])

    if(CMagnetoInternal__IFW__CREATE_START_MENU_SHORTCUT)
        set(_startMenuShortcutLink "@StartMenuDir@/${CMagnetoInternal__IFW__START_MENU_SHORTCUT_NAME}.lnk")
        CMagnetoInternal__ifw__escape_js_string("${_startMenuShortcutLink}" _startMenuShortcutLinkEscaped)
        string(APPEND _scriptText
            "\n"
            "    component.addOperation(\"CreateShortcut\", \"${_shortcutTargetPathEscaped}\", \"${_startMenuShortcutLinkEscaped}\",\n"
            "        \"workingDirectory=${_shortcutWorkingDirectoryEscaped}\", \"description=${_shortcutDescriptionEscaped}\");\n"
        )
    endif()

    if(CMagnetoInternal__IFW__CREATE_DESKTOP_SHORTCUT)
        set(_desktopShortcutLink "@DesktopDir@/${CMagnetoInternal__IFW__DESKTOP_SHORTCUT_NAME}.lnk")
        CMagnetoInternal__ifw__escape_js_string("${_desktopShortcutLink}" _desktopShortcutLinkEscaped)
        string(APPEND _scriptText
            "\n"
            "    component.addOperation(\"CreateShortcut\", \"${_shortcutTargetPathEscaped}\", \"${_desktopShortcutLinkEscaped}\",\n"
            "        \"workingDirectory=${_shortcutWorkingDirectoryEscaped}\", \"description=${_shortcutDescriptionEscaped}\");\n"
        )
    endif()

    string(APPEND _scriptText [=[
}
]=])

    set(${oScriptText} "${_scriptText}" PARENT_SCOPE)
endfunction()
