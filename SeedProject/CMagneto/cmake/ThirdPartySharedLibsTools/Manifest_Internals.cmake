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

set(CMagnetoInternal__RUNTIME_DEPENDENCY_MANIFEST__FILE_NAME "runtime_dependency_manifest.json")

#[[
    The runtime dependency manifest is intended to be the canonical build-tree description
    of imported shared-library runtime state.

    Runtime setup, helper scripts, diagnostic metadata, and package verification are all
    expected to query this layer instead of reconstructing parallel views from scattered
    global properties.
]]


function(CMagnetoInternal__runtime_dependency_manifest__json_escape_string iInput oEscapedString)
    set(_escapedString "${iInput}")
    string(REPLACE "\\" "\\\\" _escapedString "${_escapedString}")
    string(REPLACE "\"" "\\\"" _escapedString "${_escapedString}")
    string(REPLACE "\n" "\\n" _escapedString "${_escapedString}")
    string(REPLACE "\r" "\\r" _escapedString "${_escapedString}")
    string(REPLACE "\t" "\\t" _escapedString "${_escapedString}")
    set(${oEscapedString} "${_escapedString}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__format_string_list iValues oContent)
    set(_items "")
    foreach(_value IN LISTS iValues)
        if(_value STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__runtime_dependency_manifest__json_escape_string("${_value}" _escapedValue)
        if(_items STREQUAL "")
            set(_items "\n\t\t\t\"${_escapedValue}\"")
        else()
            set(_items "${_items},\n\t\t\t\"${_escapedValue}\"")
        endif()
    endforeach()

    if(_items STREQUAL "")
        set(${oContent} "" PARENT_SCOPE)
    else()
        set(${oContent} "${_items}\n\t\t" PARENT_SCOPE)
    endif()
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__collect_all_imported_targets oImportedTargets)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_allImportedTargets "")
    foreach(_target IN LISTS _registeredTargets)
        CMagnetoInternal__get_linked_imported_shared_library_targets(${_target} _targetImportedTargets)
        list(APPEND _allImportedTargets ${_targetImportedTargets})
    endforeach()

    list(REMOVE_DUPLICATES _allImportedTargets)
    set(${oImportedTargets} "${_allImportedTargets}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__collect_linked_owner_targets iImportedTarget oOwnerTargets)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_ownerTargets "")
    foreach(_target IN LISTS _registeredTargets)
        CMagnetoInternal__get_linked_imported_shared_library_targets(${_target} _targetImportedTargets)
        list(FIND _targetImportedTargets "${iImportedTarget}" _linkedTargetIdx)
        if(_linkedTargetIdx GREATER -1)
            list(APPEND _ownerTargets "${_target}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _ownerTargets)
    set(${oOwnerTargets} "${_ownerTargets}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_unclassified_imported_targets iTargetName oImportedTargets)
    set(_unclassifiedImportedTargets "")

    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
        if(_installMode STREQUAL "")
            list(APPEND _unclassifiedImportedTargets "${_importedTarget}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _unclassifiedImportedTargets)
    set(${oImportedTargets} "${_unclassifiedImportedTargets}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__warn_about_target_unclassified_imported_targets iTargetName)
    CMagnetoInternal__runtime_dependency_manifest__get_target_unclassified_imported_targets(${iTargetName} _unclassifiedImportedTargets)
    if(_unclassifiedImportedTargets STREQUAL "")
        return()
    endif()

    string(JOIN "\", \"" _targetsJoined ${_unclassifiedImportedTargets})
    set(_message
        "CMagneto target \"${iTargetName}\" links imported shared libraries without an install mode decision: "
        "\"${_targetsJoined}\". Installed binaries may still require the `set_env` helper or rely on platform "
        "default search paths. Configure such dependencies in the active build variant with "
        "expectExternalSharedLibrariesOnTargetMachine(...) or bundleExternalSharedLibraries(...), "
        "or mark them explicitly in CMake as a manual override."
    )
    string(CONCAT _message ${_message})
    CMagnetoInternal__message(WARNING "${_message}")
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_paths iTargetName oPaths)
    set(_resolvedPaths "")

    # Target-level runtime paths are derived from imported-target registrations.
    # A separate per-project-target path cache is intentionally not used.
    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        list(APPEND _resolvedPaths ${_importedTargetPaths})
    endforeach()

    list(REMOVE_DUPLICATES _resolvedPaths)
    set(${oPaths} "${_resolvedPaths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_paths_for_build_type iTargetName iBuildType oPaths)
    set(_resolvedPaths "")

    # Build-type-specific paths are read from imported-target registrations so that
    # manifest consumers observe the same fallback rules as the detection layer.
    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_registered_imported_shared_library_paths_for_build_type(${_importedTarget} "${iBuildType}" _configPaths)
        list(APPEND _resolvedPaths ${_configPaths})
    endforeach()

    list(REMOVE_DUPLICATES _resolvedPaths)
    set(${oPaths} "${_resolvedPaths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_library_dirs iTargetName oLibraryDirs)
    CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_paths(${iTargetName} _resolvedPaths)

    set(_libraryDirs "")
    foreach(_resolvedPath IN LISTS _resolvedPaths)
        cmake_path(GET _resolvedPath PARENT_PATH _libraryDir)
        if(NOT _libraryDir STREQUAL "")
            list(APPEND _libraryDirs "${_libraryDir}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_imported_shared_library_paths_by_mode iTargetName iMode oPaths)
    set(_paths "")

    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
        if(NOT _installMode STREQUAL "${iMode}")
            continue()
        endif()

        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        if(_installMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE)
            foreach(_importedTargetPath IN LISTS _importedTargetPaths)
                CMagnetoInternal__get_installable_shared_library_path("${_importedTargetPath}" _installablePath)
                list(APPEND _paths "${_installablePath}")
            endforeach()
        else()
            list(APPEND _paths ${_importedTargetPaths})
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _paths)
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_target_imported_shared_library_dirs_by_mode iTargetName iMode oLibraryDirs)
    CMagnetoInternal__runtime_dependency_manifest__get_target_imported_shared_library_paths_by_mode(${iTargetName} "${iMode}" _paths)

    set(_libraryDirs "")
    foreach(_path IN LISTS _paths)
        cmake_path(GET _path PARENT_PATH _libraryDir)
        if(NOT _libraryDir STREQUAL "")
            list(APPEND _libraryDirs "${_libraryDir}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_dirs_for_targets_by_mode iTargets iMode oLibraryDirs)
    set(_libraryDirs "")

    foreach(_target IN LISTS iTargets)
        if(NOT TARGET ${_target})
            continue()
        endif()

        CMagnetoInternal__runtime_dependency_manifest__get_target_imported_shared_library_dirs_by_mode(${_target} "${iMode}" _targetLibraryDirs)
        list(APPEND _libraryDirs ${_targetLibraryDirs})
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_paths_by_mode iMode oPaths)
    CMagnetoInternal__runtime_dependency_manifest__collect_all_imported_targets(_allImportedTargets)

    set(_paths "")
    foreach(_importedTarget IN LISTS _allImportedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
        if(NOT _installMode STREQUAL "${iMode}")
            continue()
        endif()

        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        if(_installMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE)
            foreach(_importedTargetPath IN LISTS _importedTargetPaths)
                CMagnetoInternal__get_installable_shared_library_path("${_importedTargetPath}" _installablePath)
                list(APPEND _paths "${_installablePath}")
            endforeach()
        else()
            list(APPEND _paths ${_importedTargetPaths})
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _paths)
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_bundled_imported_shared_library_paths oPaths)
    CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_paths_by_mode(
        ${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE}
        _paths
    )
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_expected_external_shared_library_paths oPaths)
    CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_paths_by_mode(
        ${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE}
        _paths
    )
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_dirs oLibraryDirs)
    CMagnetoInternal__runtime_dependency_manifest__collect_all_imported_targets(_allImportedTargets)

    set(_libraryDirs "")
    foreach(_importedTarget IN LISTS _allImportedTargets)
        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        foreach(_importedTargetPath IN LISTS _importedTargetPaths)
            cmake_path(GET _importedTargetPath PARENT_PATH _libraryDir)
            if(NOT _libraryDir STREQUAL "")
                list(APPEND _libraryDirs "${_libraryDir}")
            endif()
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__generate_imported_shared_libraries_section oContent)
    CMagnetoInternal__runtime_dependency_manifest__collect_all_imported_targets(_allImportedTargets)

    set(_entries "")
    foreach(_importedTarget IN LISTS _allImportedTargets)
        # Imported targets are emitted once here together with their install-mode decision.
        # Downstream consumers are expected to treat this section as the canonical policy view.
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
        if(_installMode STREQUAL "")
            set(_installMode "UNCLASSIFIED")
        endif()

        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
        CMagnetoInternal__runtime_dependency_manifest__collect_linked_owner_targets("${_importedTarget}" _ownerTargets)

        CMagnetoInternal__runtime_dependency_manifest__json_escape_string("${_importedTarget}" _importedTargetEscaped)
        CMagnetoInternal__runtime_dependency_manifest__json_escape_string("${_installMode}" _installModeEscaped)
        CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_importedTargetPaths}" _pathsJson)
        CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_ownerTargets}" _ownerTargetsJson)

        set(_entry
            "\n\t\t{\n"
            "\t\t\t\"ImportedTarget\": \"${_importedTargetEscaped}\",\n"
            "\t\t\t\"InstallMode\": \"${_installModeEscaped}\",\n"
            "\t\t\t\"Paths\": [${_pathsJson}],\n"
            "\t\t\t\"LinkedByTargets\": [${_ownerTargetsJson}]\n"
            "\t\t}"
        )
        string(CONCAT _entry ${_entry})

        if(_entries STREQUAL "")
            set(_entries "${_entry}")
        else()
            set(_entries "${_entries},${_entry}")
        endif()
    endforeach()

    if(NOT _entries STREQUAL "")
        set(_entries "${_entries}\n\t")
    else()
        set(_entries "\n\t")
    endif()

    set(${oContent} "${_entries}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__generate_project_targets_section iBuildType oContent)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_entries "")
    foreach(_target IN LISTS _registeredTargets)
        # Project-target entries are generated as a derived view over linked imported targets.
        # They remain useful for diagnostics, but the imported-target section stays authoritative.
        CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_paths_for_build_type(${_target} "${iBuildType}" _resolvedPaths)
        CMagnetoInternal__get_linked_imported_shared_library_targets(${_target} _linkedImportedTargets)

        set(_unclassifiedImportedTargets "")
        foreach(_importedTarget IN LISTS _linkedImportedTargets)
            CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _installMode)
            if(_installMode STREQUAL "")
                list(APPEND _unclassifiedImportedTargets "${_importedTarget}")
            endif()
        endforeach()
        list(REMOVE_DUPLICATES _unclassifiedImportedTargets)

        CMagnetoInternal__runtime_dependency_manifest__json_escape_string("${_target}" _targetEscaped)
        CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_resolvedPaths}" _resolvedPathsJson)
        CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_linkedImportedTargets}" _linkedImportedTargetsJson)
        CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_unclassifiedImportedTargets}" _unclassifiedImportedTargetsJson)

        set(_entry
            "\n\t\t{\n"
            "\t\t\t\"Target\": \"${_targetEscaped}\",\n"
            "\t\t\t\"ResolvedPaths\": [${_resolvedPathsJson}],\n"
            "\t\t\t\"LinkedImportedTargets\": [${_linkedImportedTargetsJson}],\n"
            "\t\t\t\"UnclassifiedImportedTargets\": [${_unclassifiedImportedTargetsJson}]\n"
            "\t\t}"
        )
        string(CONCAT _entry ${_entry})

        if(_entries STREQUAL "")
            set(_entries "${_entry}")
        else()
            set(_entries "${_entries},${_entry}")
        endif()
    endforeach()

    if(NOT _entries STREQUAL "")
        set(_entries "${_entries}\n\t")
    else()
        set(_entries "\n\t")
    endif()

    set(${oContent} "${_entries}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__runtime_dependency_manifest__generate_bundling_overrides_section oContent)
    CMagnetoInternal__get_bundled_runtime_dependency_files(_includeFiles)
    CMagnetoInternal__get_bundled_runtime_dependency_file_patterns(_includePatterns)
    CMagnetoInternal__get_excluded_bundled_runtime_dependency_files(_excludeFiles)
    CMagnetoInternal__get_excluded_bundled_runtime_dependency_file_patterns(_excludePatterns)

    CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_includeFiles}" _includeFilesJson)
    CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_includePatterns}" _includePatternsJson)
    CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_excludeFiles}" _excludeFilesJson)
    CMagnetoInternal__runtime_dependency_manifest__format_string_list("${_excludePatterns}" _excludePatternsJson)

    set(_content
        "{\n"
        "\t\t\"IncludeFiles\": [${_includeFilesJson}],\n"
        "\t\t\"IncludePatterns\": [${_includePatternsJson}],\n"
        "\t\t\"ExcludeFiles\": [${_excludeFilesJson}],\n"
        "\t\t\"ExcludePatterns\": [${_excludePatternsJson}]\n"
        "\t}"
    )
    string(CONCAT _content ${_content})
    set(${oContent} "${_content}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__runtime_dependency_manifest__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__RUNTIME_DEPENDENCY_MANIFEST__FILE_NAME}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__generate__runtime_dependency_manifest__content iBuildType oContent)
    # The manifest is generated once after target setup so later stages can consume
    # one shared artifact instead of rebuilding deployment state independently.
    CMagnetoInternal__runtime_dependency_manifest__generate_imported_shared_libraries_section(_importedSharedLibrariesJson)
    CMagnetoInternal__runtime_dependency_manifest__generate_project_targets_section("${iBuildType}" _projectTargetsJson)
    CMagnetoInternal__runtime_dependency_manifest__generate_bundling_overrides_section(_bundlingOverridesJson)

    set(_fileContent
        "{\n"
        "\t\"SchemaVersion\": 1,\n"
        "\t\"BuildType\": \"${iBuildType}\",\n"
        "\t\"ImportedSharedLibraries\": [${_importedSharedLibrariesJson}],\n"
        "\t\"ProjectTargets\": [${_projectTargetsJson}],\n"
        "\t\"BundlingOverrides\": ${_bundlingOverridesJson}\n"
        "}"
    )
    string(CONCAT _fileContent ${_fileContent})
    set(${oContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__set_up__runtime_dependency_manifest)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__runtime_dependency_manifest__file_name" "CMagnetoInternal__generate__runtime_dependency_manifest__content" FALSE FALSE "")
endfunction()
