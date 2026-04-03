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

function(CMagnetoInternal__ifw__stage_license_file iSourceAbs iInstallRel oStagedSourceAbs)
    string(REPLACE "\\" "/" _installRelNormalized "${iInstallRel}")
    cmake_path(SET _installRelNormalized NORMALIZE "${_installRelNormalized}")
    string(REPLACE "/" "__" _stagedFileName "${_installRelNormalized}")

    cmake_path(SET _ifwLicenseStagingDir NORMALIZE "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_TMP}/IFWLicenses")
    file(MAKE_DIRECTORY "${_ifwLicenseStagingDir}")

    cmake_path(SET _stagedSourceAbs NORMALIZE "${_ifwLicenseStagingDir}/${_stagedFileName}")
    file(COPY_FILE "${iSourceAbs}" "${_stagedSourceAbs}" ONLY_IF_DIFFERENT)

    set(${oStagedSourceAbs} "${_stagedSourceAbs}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw__make_license_display_name iComponentName iFilesCount iKind iInstallRel oDisplayName)
    string(REPLACE "\\" "/" _installRelNormalized "${iInstallRel}")
    cmake_path(SET _installRelNormalized NORMALIZE "${_installRelNormalized}")
    cmake_path(GET _installRelNormalized FILENAME _fileName)

    if(_installRelNormalized STREQUAL "licenses/ProjectLicense.txt")
        set(_displayName "Project License")
    elseif(_installRelNormalized MATCHES "^licenses/3rd-party/")
        set(_displayName "Third-party: ${iComponentName}")
    else()
        set(_displayName "${iComponentName}")
    endif()

    if(iFilesCount GREATER 1)
        string(APPEND _displayName ": ${_fileName}")
    endif()

    set(${oDisplayName} "${_displayName}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw__make_component_licenses oIfwLicenses)
    set(_bundleFileEntries ${CMagneto__LICENSE_BUNDLE_FILE_ENTRIES})
    if(NOT _bundleFileEntries)
        get_property(_bundleFileEntries GLOBAL PROPERTY CMagneto__LICENSE_BUNDLE_FILE_ENTRIES)
    endif()

    set(_ifwLicenses)
    list(LENGTH _bundleFileEntries _entriesCount)
    if(_entriesCount EQUAL 0)
        set(${oIfwLicenses} "" PARENT_SCOPE)
        return()
    endif()

    math(EXPR _lastEntryIndex "${_entriesCount} - 5")
    foreach(_entryIndex RANGE 0 ${_lastEntryIndex} 5)
        math(EXPR _componentNameIndex "${_entryIndex}")
        math(EXPR _filesCountIndex "${_entryIndex} + 1")
        math(EXPR _kindIndex "${_entryIndex} + 2")
        math(EXPR _installRelIndex "${_entryIndex} + 3")
        math(EXPR _sourceAbsIndex "${_entryIndex} + 4")

        list(GET _bundleFileEntries ${_componentNameIndex} _componentName)
        list(GET _bundleFileEntries ${_filesCountIndex} _filesCount)
        list(GET _bundleFileEntries ${_kindIndex} _kind)
        list(GET _bundleFileEntries ${_installRelIndex} _installRel)
        list(GET _bundleFileEntries ${_sourceAbsIndex} _sourceAbs)

        CMagnetoInternal__ifw__stage_license_file("${_sourceAbs}" "${_installRel}" _ifwSourceAbs)
        CMagnetoInternal__ifw__make_license_display_name(
            "${_componentName}"
            ${_filesCount}
            "${_kind}"
            "${_installRel}"
            _ifwDisplayName
        )
        list(APPEND _ifwLicenses "${_ifwDisplayName}" "${_ifwSourceAbs}")
    endforeach()

    set(${oIfwLicenses} "${_ifwLicenses}" PARENT_SCOPE)
endfunction()
