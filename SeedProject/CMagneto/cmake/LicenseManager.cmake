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
    This submodule resolves the active license bundle and registers install() rules
    for all declared license and notice files. The same install rules are then used
    by both plain `cmake --install` and CPack-based package generation.

    It intentionally stays generator-agnostic. Packaging-generator-specific
    adaptations (for example, Qt IFW staging of license-agreement files) belong
    to the corresponding packaging submodules.
]]

cmake_path(SET CMagneto__LICENSES_DIR NORMALIZE "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_LICENSES}")
cmake_path(SET CMagneto__LICENSE_COMPONENTS_DIR NORMALIZE "${CMagneto__LICENSES_DIR}/${CMagneto__SUBDIR_LICENSES_COMPONENTS}")
cmake_path(SET CMagneto__LICENSE_BUNDLES_DIR NORMALIZE "${CMagneto__LICENSES_DIR}/${CMagneto__SUBDIR_LICENSE_BUNDLES}")
cmake_path(SET CMagneto__PROJECT_LICENSE_FILE NORMALIZE "${CMAKE_SOURCE_DIR}/LICENSE")

set(CMagneto__LICENSE_BUNDLE "runtime/default"
    CACHE STRING "License bundle to install and package, resolved relative to licenses/bundles/."
)

function(CMagnetoInternal__licenses__normalize_relative_path iValue oValue)
    if(IS_ABSOLUTE "${iValue}")
        message(FATAL_ERROR "License manifest path must be relative to the project root: \"${iValue}\".")
    endif()

    set(_normalized "${iValue}")
    string(REPLACE "\\" "/" _normalized "${_normalized}")
    cmake_path(SET _normalized NORMALIZE "${_normalized}")
    if(_normalized MATCHES "(^|/)\\.\\.(/|$)")
        message(FATAL_ERROR "License manifest path must stay within the project root: \"${iValue}\".")
    endif()

    set(${oValue} "${_normalized}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__licenses__expand_env_tokens iValue oValue)
    set(_expanded "${iValue}")
    string(REGEX MATCHALL "\\$env\\{[^}]+\\}" _envTokens "${_expanded}")
    foreach(_envToken IN LISTS _envTokens)
        string(REGEX REPLACE "^\\$env\\{([^}]+)\\}$" "\\1" _envName "${_envToken}")
        if(NOT DEFINED ENV{${_envName}} OR "$ENV{${_envName}}" STREQUAL "")
            message(FATAL_ERROR
                "Environment variable \"${_envName}\" referenced by a license manifest is not defined."
            )
        endif()
        string(REPLACE "${_envToken}" "$ENV{${_envName}}" _expanded "${_expanded}")
    endforeach()

    set(${oValue} "${_expanded}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__licenses__resolve_json_path iBaseDir iReference oPath)
    set(_candidate "${iReference}")
    if(NOT IS_ABSOLUTE "${_candidate}")
        cmake_path(SET _candidate NORMALIZE "${iBaseDir}/${_candidate}")
    else()
        cmake_path(SET _candidate NORMALIZE "${_candidate}")
    endif()

    if(EXISTS "${_candidate}")
        set(${oPath} "${_candidate}" PARENT_SCOPE)
        return()
    endif()

    if(NOT _candidate MATCHES "\\.json$")
        set(_candidateWithExt "${_candidate}.json")
        if(EXISTS "${_candidateWithExt}")
            set(${oPath} "${_candidateWithExt}" PARENT_SCOPE)
            return()
        endif()
    endif()

    message(FATAL_ERROR "License manifest was not found: \"${iReference}\".")
endfunction()

function(CMagnetoInternal__licenses__resolve_source_path iSourceValue oSourceAbsPath)
    CMagnetoInternal__licenses__expand_env_tokens("${iSourceValue}" _sourceExpanded)
    string(REPLACE "\\" "/" _sourceExpanded "${_sourceExpanded}")

    if(IS_ABSOLUTE "${_sourceExpanded}")
        cmake_path(SET _sourceAbs NORMALIZE "${_sourceExpanded}")
        if(NOT EXISTS "${_sourceAbs}")
            message(FATAL_ERROR "License source file does not exist: \"${_sourceAbs}\".")
        endif()
        set(${oSourceAbsPath} "${_sourceAbs}" PARENT_SCOPE)
        return()
    endif()

    CMagnetoInternal__licenses__normalize_relative_path("${_sourceExpanded}" _sourceRelNormalized)
    cmake_path(SET _sourceAbs NORMALIZE "${CMAKE_SOURCE_DIR}/${_sourceRelNormalized}")
    if(NOT EXISTS "${_sourceAbs}")
        message(FATAL_ERROR "License source file does not exist: \"${_sourceAbs}\".")
    endif()

    set(${oSourceAbsPath} "${_sourceAbs}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__licenses__install_file iSourceAbs iInstallRel)
    CMagnetoInternal__licenses__normalize_relative_path("${iInstallRel}" _installRelNormalized)

    cmake_path(GET _installRelNormalized PARENT_PATH _installDest)
    if(_installDest STREQUAL "")
        set(_installDest ".")
    endif()
    cmake_path(GET _installRelNormalized FILENAME _installFileName)

    install(FILES "${iSourceAbs}"
        DESTINATION "${_installDest}"
        RENAME "${_installFileName}"
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )
endfunction()

function(CMagnetoInternal__licenses__install_component_from_manifest iComponentManifestPath oBundleFileEntries)
    file(READ "${iComponentManifestPath}" _componentJson)

    string(JSON _componentId GET "${_componentJson}" id)
    string(JSON _componentName GET "${_componentJson}" name)
    string(JSON _filesCount LENGTH "${_componentJson}" files)
    if(_filesCount EQUAL 0)
        CMagnetoInternal__message(WARNING
            "License component \"${_componentId}\" from \"${iComponentManifestPath}\" does not define any files."
        )
        set(${oBundleFileEntries} "" PARENT_SCOPE)
        return()
    endif()

    set(_componentBundleFileEntries)
    math(EXPR _lastFileIndex "${_filesCount} - 1")
    foreach(_fileIndex RANGE 0 ${_lastFileIndex})
        set(_kind "unspecified")
        string(JSON _kind ERROR_VARIABLE _kindError GET "${_componentJson}" files ${_fileIndex} kind)
        if(_kindError)
            set(_kind "unspecified")
        endif()

        string(JSON _sourceRel GET "${_componentJson}" files ${_fileIndex} source)
        string(JSON _installRel GET "${_componentJson}" files ${_fileIndex} install)
        CMagnetoInternal__licenses__resolve_source_path("${_sourceRel}" _sourceAbs)
        CMagnetoInternal__licenses__install_file("${_sourceAbs}" "${_installRel}")
        CMagnetoInternal__licenses__normalize_relative_path("${_installRel}" _installRelNormalized)
        list(APPEND _componentBundleFileEntries
            "${_componentName}"
            "${_filesCount}"
            "${_kind}"
            "${_installRelNormalized}"
            "${_sourceAbs}"
        )
    endforeach()

    set(${oBundleFileEntries} "${_componentBundleFileEntries}" PARENT_SCOPE)
endfunction()

function(CMagneto__set_up__license_bundle_installation)
    if(NOT EXISTS "${CMagneto__PROJECT_LICENSE_FILE}")
        message(FATAL_ERROR "Primary project license file was not found: \"${CMagneto__PROJECT_LICENSE_FILE}\".")
    endif()

    CMagnetoInternal__licenses__resolve_json_path(
        "${CMagneto__LICENSE_BUNDLES_DIR}"
        "${CMagneto__LICENSE_BUNDLE}"
        _bundleManifestPath
    )

    file(READ "${_bundleManifestPath}" _bundleJson)
    string(JSON _bundleId GET "${_bundleJson}" id)
    string(JSON _componentsCount LENGTH "${_bundleJson}" components)
    if(_componentsCount EQUAL 0)
        message(FATAL_ERROR "License bundle \"${_bundleId}\" does not define any components.")
    endif()

    set(_bundleFileEntries)
    math(EXPR _lastComponentIndex "${_componentsCount} - 1")
    foreach(_componentIndex RANGE 0 ${_lastComponentIndex})
        string(JSON _componentRef GET "${_bundleJson}" components ${_componentIndex})
        CMagnetoInternal__licenses__resolve_json_path(
            "${CMagneto__LICENSE_COMPONENTS_DIR}"
            "${_componentRef}"
            _componentManifestPath
        )
        CMagnetoInternal__licenses__install_component_from_manifest(
            "${_componentManifestPath}"
            _componentBundleFileEntries
        )
        list(APPEND _bundleFileEntries ${_componentBundleFileEntries})
    endforeach()

    set(CMagneto__LICENSE_BUNDLE_FILE_ENTRIES "${_bundleFileEntries}" PARENT_SCOPE)
    set_property(GLOBAL PROPERTY CMagneto__LICENSE_BUNDLE_FILE_ENTRIES "${_bundleFileEntries}")
    CMagnetoInternal__message(STATUS
        "License bundle \"${_bundleId}\" selected from \"${_bundleManifestPath}\"."
    )
endfunction()
