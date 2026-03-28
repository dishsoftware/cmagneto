# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)

set(CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")
set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_DEPLOYMENT__FILE_NAME "external_shared_library_deployment.json")


function(CMagnetoInternal__json_escape_string iInput oEscapedString)
    set(_escapedString "${iInput}")
    string(REPLACE "\\" "\\\\" _escapedString "${_escapedString}")
    string(REPLACE "\"" "\\\"" _escapedString "${_escapedString}")
    string(REPLACE "\n" "\\n" _escapedString "${_escapedString}")
    string(REPLACE "\r" "\\r" _escapedString "${_escapedString}")
    string(REPLACE "\t" "\\t" _escapedString "${_escapedString}")
    set(${oEscapedString} "${_escapedString}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__3rd_party_shared_libs__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get__external_shared_library_deployment__file_name

    Returns file name of the JSON metadata describing how imported shared libraries must be deployed.
]]
function(CMagnetoInternal__get__external_shared_library_deployment__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_DEPLOYMENT__FILE_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__3rd_party_shared_libs__content

    Returns content of the "3rd_party_shared_libs.json" file.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__generate__3rd_party_shared_libs__content iBuildType oContent)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    list(LENGTH _registeredTargets _registeredTargetsLength)

    set(_fileContent "{\n")
    set(_targetIdx 0)
    foreach(_target ${_registeredTargets})
        set(_fileContent "${_fileContent}\t\"${_target}\": [")

        CMagnetoInternal__get_paths_to_shared_libs(${_target} "${iBuildType}" _libPaths)
        list(LENGTH _libPaths _libPathsLength)
        if(NOT _libPathsLength EQUAL 0)
            string(JOIN "\",\n\t\t\"" _libPathsJoined ${_libPaths})
            set(_fileContent "${_fileContent}\n\t\t\"${_libPathsJoined}\"\n\t]")
        endif()

        math(EXPR _targetIdx "${_targetIdx} + 1")
        if(_targetIdx LESS ${_registeredTargetsLength})
            set(_fileContent "${_fileContent},\n")
        else()
            set(_fileContent "${_fileContent}\n")
        endif()
    endforeach()
    set(_fileContent "${_fileContent}}")

    set(${oContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__external_shared_library_deployment__content

    Returns content of the "external_shared_library_deployment.json" file.
    The file records imported shared-library targets grouped by install mode together with
    runtime file paths used later for package verification.
]]
function(CMagnetoInternal__generate__external_shared_library_deployment__content iBuildType oContent)
    CMagnetoInternal__runtime_dependency_manifest__collect_all_imported_targets(_allImportedTargets)
    set(_expectEntries "")
    set(_bundleEntries "")

    foreach(_importedTarget IN LISTS _allImportedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
        if(_installMode STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        CMagnetoInternal__json_escape_string("${_importedTarget}" _importedTargetEscaped)

        set(_entryPathItems "")
        foreach(_path IN LISTS _importedTargetPaths)
            if(_installMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE)
                CMagnetoInternal__get_installable_shared_library_path("${_path}" _pathForDeploymentInfo)
            else()
                set(_pathForDeploymentInfo "${_path}")
            endif()

            CMagnetoInternal__json_escape_string("${_pathForDeploymentInfo}" _pathEscaped)
            if(_entryPathItems STREQUAL "")
                set(_entryPathItems "\n\t\t\t\"${_pathEscaped}\"")
            else()
                set(_entryPathItems "${_entryPathItems},\n\t\t\t\"${_pathEscaped}\"")
            endif()
        endforeach()
        if(NOT _entryPathItems STREQUAL "")
            set(_entryPathItems "${_entryPathItems}\n\t\t")
        endif()

        set(_entry
            "\n\t\t{\n"
            "\t\t\t\"ImportedTarget\": \"${_importedTargetEscaped}\",\n"
            "\t\t\t\"Paths\": [${_entryPathItems}]\n"
            "\t\t}"
        )
        string(CONCAT _entry ${_entry})

        if(_installMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE)
            if(_expectEntries STREQUAL "")
                set(_expectEntries "${_entry}")
            else()
                set(_expectEntries "${_expectEntries},${_entry}")
            endif()
        elseif(_installMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE)
            if(_bundleEntries STREQUAL "")
                set(_bundleEntries "${_entry}")
            else()
                set(_bundleEntries "${_bundleEntries},${_entry}")
            endif()
        endif()
    endforeach()

    set(_fileContent "{\n\t\"EXPECT_ON_TARGET_MACHINE\": [")
    if(NOT _expectEntries STREQUAL "")
        set(_fileContent "${_fileContent}${_expectEntries}\n\t")
    else()
        set(_fileContent "${_fileContent}\n\t")
    endif()

    set(_fileContent "${_fileContent}],\n\t\"BUNDLE_WITH_PACKAGE\": [")
    if(NOT _bundleEntries STREQUAL "")
        set(_fileContent "${_fileContent}${_bundleEntries}\n\t")
    else()
        set(_fileContent "${_fileContent}\n\t")
    endif()
    set(_fileContent "${_fileContent}]\n}")

    set(${oContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up__3rd_party_shared_libs__list

    Generates and places to build directory "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file is intended only for build-machine-side diagnostics and must not be distributed.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__3rd_party_shared_libs__list)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__3rd_party_shared_libs__file_name" "CMagnetoInternal__generate__3rd_party_shared_libs__content" FALSE FALSE "")
endfunction()


#[[
    CMagnetoInternal__set_up__external_shared_library_deployment__list

    Generates and places the imported shared-library deployment metadata into the build tree.
    The file is consumed by package verification code and is not installed as a build-machine-specific artifact.
]]
function(CMagnetoInternal__set_up__external_shared_library_deployment__list)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__external_shared_library_deployment__file_name" "CMagnetoInternal__generate__external_shared_library_deployment__content" FALSE FALSE "")
endfunction()
