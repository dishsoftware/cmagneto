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

function(CMagnetoInternal__ifw__escape_js_string iInputText oEscapedText)
    set(_text "${iInputText}")
    string(REPLACE "\\" "\\\\" _text "${_text}")
    string(REPLACE "\"" "\\\"" _text "${_text}")
    string(REPLACE "\r" "" _text "${_text}")
    string(REPLACE "\n" "\\n" _text "${_text}")
    set(${oEscapedText} "${_text}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw__write_runtime_component_script iScriptText oScriptPath)
    if(iScriptText STREQUAL "")
        set(${oScriptPath} "" PARENT_SCOPE)
        return()
    endif()

    cmake_path(SET _generatedScriptPath NORMALIZE "${CMAKE_CURRENT_BINARY_DIR}/CMagnetoGeneratedIfwRuntimeComponentScript.qs")
    file(WRITE "${_generatedScriptPath}" "${iScriptText}")
    set(${oScriptPath} "${_generatedScriptPath}" PARENT_SCOPE)
endfunction()
