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


#[[
    CMagnetoInternal__set_up_target_runtime_resolution

    Configures runtime dependency lookup for a target in build and install trees.
    The exact behavior is selected through the platform-specific runtime-resolution
    strategy returned by CMagnetoInternal__get_runtime_resolution_strategy().

    For EMBEDDED_RUNTIME_PATHS, imported shared-library directories are added to
    BUILD_RPATH for local runs, while relative INSTALL_RPATH values are used for
    relocatable project binaries. Those directories are queried through the runtime
    dependency manifest layer so the same imported-target classification is reused
    by runtime setup, helper scripts, and verification.

    For TARGET_LOCAL_RUNTIME_FILES, runtime DLLs are copied next to the target
    binary in the build tree.
]]
function(CMagnetoInternal__set_up_target_runtime_resolution iTargetName)
    if(NOT TARGET ${iTargetName})
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__set_up_target_runtime_resolution: target \"${iTargetName}\" does not exist.")
    endif()

    get_target_property(_targetType ${iTargetName} TYPE)
    CMagnetoInternal__get_runtime_resolution_strategy(_runtimeResolutionStrategy)

    if(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__EMBEDDED_RUNTIME_PATHS}")
        CMagnetoInternal__runtime_dependency_manifest__warn_about_target_unclassified_imported_targets(${iTargetName})

        CMagnetoInternal__runtime_dependency_manifest__get_target_resolved_library_dirs(${iTargetName} _libraryDirs)
        set(_buildRPath "${_libraryDirs}")
        set(_installRPath "")

        CMagnetoInternal__runtime_dependency_manifest__get_target_imported_shared_library_dirs_by_mode(
            ${iTargetName}
            ${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE}
            _sameLocationLibraryDirs
        )

        if(_targetType STREQUAL "EXECUTABLE")
            list(APPEND _buildRPath "\$ORIGIN/../lib")
            list(APPEND _installRPath "\$ORIGIN/../lib")
        elseif(_targetType STREQUAL "SHARED_LIBRARY")
            list(APPEND _buildRPath "\$ORIGIN")
            list(APPEND _installRPath "\$ORIGIN")
        else()
            return()
        endif()
        list(APPEND _installRPath ${_sameLocationLibraryDirs})

        list(REMOVE_DUPLICATES _buildRPath)
        list(REMOVE_DUPLICATES _installRPath)

        set_target_properties(${iTargetName}
            PROPERTIES
                BUILD_RPATH "${_buildRPath}"
                BUILD_RPATH_USE_ORIGIN TRUE
                INSTALL_RPATH "${_installRPath}"
        )
    elseif(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__TARGET_LOCAL_RUNTIME_FILES}")
        if(_targetType STREQUAL "EXECUTABLE" OR _targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY")
            add_custom_command(TARGET ${iTargetName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    $<TARGET_RUNTIME_DLLS:${iTargetName}>
                    $<TARGET_FILE_DIR:${iTargetName}>
                COMMAND_EXPAND_LISTS
            )
        endif()
    elseif(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__NONE}")
        return()
    else()
        CMagnetoInternal__message(
            FATAL_ERROR
            "CMagnetoInternal__set_up_target_runtime_resolution: unsupported runtime-resolution strategy "
            "\"${_runtimeResolutionStrategy}\"."
        )
    endif()
endfunction()


function(CMagnetoInternal__set_up_targets_runtime_resolution)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    foreach(_target IN LISTS _registeredTargets)
        CMagnetoInternal__set_up_target_runtime_resolution(${_target})
    endforeach()
endfunction()


function(CMagnetoInternal__install_bundled_external_shared_libraries)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(_destinationDir ${CMagneto__SUBDIR_SHARED})
    elseif(WIN32)
        set(_destinationDir ${CMagneto__SUBDIR_EXECUTABLE})
    else()
        return()
    endif()

    # Direct bundle/external inputs are collected from the manifest query layer so install-time
    # bundling follows the same imported-target decisions as diagnostics and verification.
    CMagnetoInternal__runtime_dependency_manifest__get_bundled_imported_shared_library_paths(_policyBundlePaths)
    CMagnetoInternal__runtime_dependency_manifest__get_expected_external_shared_library_paths(_expectedOnTargetPaths)
    CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_dirs(_knownLibraryDirs)

    CMagnetoInternal__get_bundled_runtime_dependency_files(_explicitBundleFiles)
    CMagnetoInternal__get_bundled_runtime_dependency_file_patterns(_explicitBundlePatterns)
    CMagnetoInternal__get_excluded_bundled_runtime_dependency_files(_excludedBundleFiles)
    CMagnetoInternal__get_excluded_bundled_runtime_dependency_file_patterns(_excludedBundlePatterns)

    CMagnetoInternal__expand_runtime_dependency_file_patterns("${_explicitBundlePatterns}" "${_knownLibraryDirs}" _patternBundlePaths)

    set(_bundleSourcePaths ${_policyBundlePaths} ${_patternBundlePaths})
    foreach(_explicitBundleFile IN LISTS _explicitBundleFiles)
        if(EXISTS "${_explicitBundleFile}")
            list(APPEND _bundleSourcePaths "${_explicitBundleFile}")
        else()
            CMagnetoInternal__message(WARNING "Bundled runtime dependency override file does not exist and will be skipped: \"${_explicitBundleFile}\".")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES _bundleSourcePaths)
    CMagnetoInternal__filter_runtime_dependency_paths_by_excludes(
        "${_bundleSourcePaths}"
        "${_excludedBundleFiles}"
        "${_excludedBundlePatterns}"
        _bundleSourcePaths
    )

    if(_bundleSourcePaths STREQUAL "")
        return()
    endif()

    set(_installPaths "")
    foreach(_libPath IN LISTS _bundleSourcePaths)
        list(APPEND _installPaths "${_libPath}")

        get_filename_component(_realPath "${_libPath}" REALPATH)
        if(EXISTS "${_realPath}" AND NOT _realPath STREQUAL "${_libPath}")
            list(APPEND _installPaths "${_realPath}")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES _installPaths)
    CMagnetoInternal__filter_runtime_dependency_paths_by_excludes(
        "${_installPaths}"
        "${_excludedBundleFiles}"
        "${_excludedBundlePatterns}"
        _installPaths
    )

    if(_installPaths STREQUAL "")
        return()
    endif()

    install(FILES ${_installPaths}
        DESTINATION ${_destinationDir}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )

    cmake_path(CONVERT "${_bundleSourcePaths}" TO_CMAKE_PATH_LIST _libPathsCMake)
    cmake_path(CONVERT "${_expectedOnTargetPaths}" TO_CMAKE_PATH_LIST _expectedOnTargetPathsCMake)
    cmake_path(CONVERT "${_knownLibraryDirs}" TO_CMAKE_PATH_LIST _knownLibraryDirsCMake)
    cmake_path(CONVERT "${_explicitBundleFiles}" TO_CMAKE_PATH_LIST _explicitBundleFilesCMake)
    string(JOIN ";" _explicitBundlePatternsCMake ${_explicitBundlePatterns})
    cmake_path(CONVERT "${_excludedBundleFiles}" TO_CMAKE_PATH_LIST _excludedBundleFilesCMake)
    string(JOIN ";" _excludedBundlePatternsCMake ${_excludedBundlePatterns})
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(_cmagneto_install_script_platform "Linux")
    elseif(WIN32)
        set(_cmagneto_install_script_platform "Windows")
    else()
        set(_cmagneto_install_script_platform "")
    endif()

    set(_installScriptTemplate [=[
set(_cmagneto_bundled_source_paths "@_libPathsCMake@")
set(_cmagneto_expected_external_source_paths "@_expectedOnTargetPathsCMake@")
set(_cmagneto_known_library_dirs "@_knownLibraryDirsCMake@")
set(_cmagneto_destination_dir "@_destinationDir@")
set(_cmagneto_user_included_source_paths "@_explicitBundleFilesCMake@")
set(_cmagneto_user_included_patterns "@_explicitBundlePatternsCMake@")
set(_cmagneto_user_excluded_source_paths "@_excludedBundleFilesCMake@")
set(_cmagneto_user_excluded_patterns "@_excludedBundlePatternsCMake@")
set(_cmagneto_platform "@_cmagneto_install_script_platform@")

function(_cmagneto_append_existing_path_variants iPaths oOutputPaths)
    set(_outputPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        list(APPEND _outputPaths "${_path}")
        get_filename_component(_realPath "${_path}" REALPATH)
        if(EXISTS "${_realPath}" AND NOT _realPath STREQUAL "${_path}")
            list(APPEND _outputPaths "${_realPath}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _outputPaths)
    set(${oOutputPaths} "${_outputPaths}" PARENT_SCOPE)
endfunction()

function(_cmagneto_glob_pattern_to_regex iPattern oRegex)
    set(_regex "${iPattern}")
    string(REGEX REPLACE "([][+.^$(){}|\\\\])" "\\\\\\1" _regex "${_regex}")
    string(REPLACE "?" "." _regex "${_regex}")
    string(REPLACE "*" ".*" _regex "${_regex}")
    set(${oRegex} "${_regex}" PARENT_SCOPE)
endfunction()

function(_cmagneto_path_matches_patterns iPath iPatterns oMatches)
    file(TO_CMAKE_PATH "${iPath}" _pathNormalized)
    get_filename_component(_pathBasename "${_pathNormalized}" NAME)
    foreach(_pattern IN LISTS iPatterns)
        if(_pattern STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_pattern}" _patternNormalized)
        cmake_path(IS_ABSOLUTE _patternNormalized _patternIsAbsolute)
        _cmagneto_glob_pattern_to_regex("${_patternNormalized}" _patternRegex)
        if(_patternIsAbsolute)
            if(_pathNormalized MATCHES "^${_patternRegex}$")
                set(${oMatches} TRUE PARENT_SCOPE)
                return()
            endif()
        else()
            if(_pathBasename MATCHES "^${_patternRegex}$" OR _pathNormalized MATCHES "(^|.*/)${_patternRegex}$")
                set(${oMatches} TRUE PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    set(${oMatches} FALSE PARENT_SCOPE)
endfunction()

function(_cmagneto_filter_paths_by_user_excludes iPaths oFilteredPaths)
    _cmagneto_append_existing_path_variants("${_cmagneto_user_excluded_source_paths}" _cmagneto_user_excluded_path_variants)
    set(_filteredPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_path}" _pathNormalized)
        list(FIND _cmagneto_user_excluded_path_variants "${_pathNormalized}" _excludedIndex)
        if(_excludedIndex GREATER -1)
            continue()
        endif()

        get_filename_component(_realPath "${_pathNormalized}" REALPATH)
        if(EXISTS "${_realPath}")
            file(TO_CMAKE_PATH "${_realPath}" _realPathNormalized)
            list(FIND _cmagneto_user_excluded_path_variants "${_realPathNormalized}" _excludedRealPathIndex)
            if(_excludedRealPathIndex GREATER -1)
                continue()
            endif()
        endif()

        _cmagneto_path_matches_patterns("${_pathNormalized}" "${_cmagneto_user_excluded_patterns}" _matchesUserExcludedPattern)
        if(_matchesUserExcludedPattern)
            continue()
        endif()

        list(APPEND _filteredPaths "${_pathNormalized}")
    endforeach()

    list(REMOVE_DUPLICATES _filteredPaths)
    set(${oFilteredPaths} "${_filteredPaths}" PARENT_SCOPE)
endfunction()

function(_cmagneto_path_is_included_by_user_overrides iPath oIsIncluded)
    _cmagneto_append_existing_path_variants("${_cmagneto_user_included_source_paths}" _cmagneto_user_included_path_variants)

    file(TO_CMAKE_PATH "${iPath}" _pathNormalized)
    list(FIND _cmagneto_user_included_path_variants "${_pathNormalized}" _includedIndex)
    if(_includedIndex GREATER -1)
        set(${oIsIncluded} TRUE PARENT_SCOPE)
        return()
    endif()

    get_filename_component(_realPath "${_pathNormalized}" REALPATH)
    if(EXISTS "${_realPath}")
        file(TO_CMAKE_PATH "${_realPath}" _realPathNormalized)
        list(FIND _cmagneto_user_included_path_variants "${_realPathNormalized}" _includedRealPathIndex)
        if(_includedRealPathIndex GREATER -1)
            set(${oIsIncluded} TRUE PARENT_SCOPE)
            return()
        endif()
    endif()

    _cmagneto_path_matches_patterns("${_pathNormalized}" "${_cmagneto_user_included_patterns}" _matchesUserIncludedPattern)
    if(_matchesUserIncludedPattern)
        set(${oIsIncluded} TRUE PARENT_SCOPE)
        return()
    endif()

    set(${oIsIncluded} FALSE PARENT_SCOPE)
endfunction()

function(_cmagneto_filter_transitive_paths_by_precedence iPaths iDefaultExcludeRegexes oFilteredPaths)
    _cmagneto_append_existing_path_variants("${_cmagneto_user_excluded_source_paths}" _cmagneto_user_excluded_path_variants)
    set(_filteredPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_path}" _pathNormalized)

        list(FIND _cmagneto_user_excluded_path_variants "${_pathNormalized}" _excludedIndex)
        if(_excludedIndex GREATER -1)
            continue()
        endif()

        get_filename_component(_realPath "${_pathNormalized}" REALPATH)
        if(EXISTS "${_realPath}")
            file(TO_CMAKE_PATH "${_realPath}" _realPathNormalized)
            list(FIND _cmagneto_user_excluded_path_variants "${_realPathNormalized}" _excludedRealPathIndex)
            if(_excludedRealPathIndex GREATER -1)
                continue()
            endif()
        endif()

        _cmagneto_path_matches_patterns("${_pathNormalized}" "${_cmagneto_user_excluded_patterns}" _matchesUserExcludedPattern)
        if(_matchesUserExcludedPattern)
            continue()
        endif()

        _cmagneto_path_is_included_by_user_overrides("${_pathNormalized}" _isIncludedByUser)
        if(_isIncludedByUser)
            list(APPEND _filteredPaths "${_pathNormalized}")
            continue()
        endif()

        set(_isDefaultExcluded FALSE)
        foreach(_excludeRegex IN LISTS iDefaultExcludeRegexes)
            if(_pathNormalized MATCHES "${_excludeRegex}")
                set(_isDefaultExcluded TRUE)
                break()
            endif()
        endforeach()
        if(_isDefaultExcluded)
            continue()
        endif()

        list(APPEND _filteredPaths "${_pathNormalized}")
    endforeach()

    list(REMOVE_DUPLICATES _filteredPaths)
    set(${oFilteredPaths} "${_filteredPaths}" PARENT_SCOPE)
endfunction()

function(_cmagneto_get_elf_soname iLibraryPath oSoname)
    if(NOT _cmagneto_platform STREQUAL "Linux")
        set(${oSoname} "" PARENT_SCOPE)
        return()
    endif()

    execute_process(
        COMMAND readelf -d "${iLibraryPath}"
        OUTPUT_VARIABLE _readelfOutput
        ERROR_QUIET
        RESULT_VARIABLE _readelfResult
    )
    if(NOT _readelfResult EQUAL 0)
        set(${oSoname} "" PARENT_SCOPE)
        return()
    endif()

    string(REGEX MATCH "Library soname: \\[([^]]+)\\]" _match "${_readelfOutput}")
    if(CMAKE_MATCH_1)
        set(${oSoname} "${CMAKE_MATCH_1}" PARENT_SCOPE)
    else()
        set(${oSoname} "" PARENT_SCOPE)
    endif()
endfunction()

function(_cmagneto_get_installable_shared_library_path iLibraryPath oInstallablePath)
    if(NOT _cmagneto_platform STREQUAL "Linux")
        set(${oInstallablePath} "${iLibraryPath}" PARENT_SCOPE)
        return()
    endif()

    _cmagneto_get_elf_soname("${iLibraryPath}" _soname)
    if(_soname STREQUAL "")
        set(${oInstallablePath} "${iLibraryPath}" PARENT_SCOPE)
        return()
    endif()

    get_filename_component(_libraryDir "${iLibraryPath}" DIRECTORY)
    set(_sonamePath "${_libraryDir}/${_soname}")
    if(EXISTS "${_sonamePath}")
        set(${oInstallablePath} "${_sonamePath}" PARENT_SCOPE)
    else()
        set(${oInstallablePath} "${iLibraryPath}" PARENT_SCOPE)
    endif()
endfunction()

set(_cmagneto_install_root "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}")
file(TO_CMAKE_PATH "${_cmagneto_install_root}" _cmagneto_install_root_normalized)
string(REGEX REPLACE "([][+.*^$()|?\\\\])" "\\\\\\1" _cmagneto_install_root_regex "${_cmagneto_install_root_normalized}")
set(_cmagneto_installed_bundled_paths "")
foreach(_sourcePath IN LISTS _cmagneto_bundled_source_paths)
    get_filename_component(_fileName "${_sourcePath}" NAME)
    list(APPEND _cmagneto_installed_bundled_paths "${_cmagneto_install_root}/${_cmagneto_destination_dir}/${_fileName}")
endforeach()

_cmagneto_append_existing_path_variants("${_cmagneto_expected_external_source_paths}" _cmagneto_excluded_paths)
foreach(_installedPath IN LISTS _cmagneto_installed_bundled_paths)
    if(_installedPath STREQUAL "")
        continue()
    endif()

    list(APPEND _cmagneto_excluded_paths "${_installedPath}")
    get_filename_component(_realInstalledPath "${_installedPath}" REALPATH)
    if(EXISTS "${_realInstalledPath}" AND NOT _realInstalledPath STREQUAL "${_installedPath}")
        list(APPEND _cmagneto_excluded_paths "${_realInstalledPath}")
    endif()
endforeach()
list(REMOVE_DUPLICATES _cmagneto_excluded_paths)

set(_cmagneto_pre_exclude_regexes "")
set(_cmagneto_post_exclude_regexes "")
set(_cmagneto_default_post_exclude_regexes "")
if(_cmagneto_platform STREQUAL "Windows")
    list(APPEND _cmagneto_pre_exclude_regexes "^api-ms-win-" "^ext-ms-")
    if(DEFINED ENV{SystemRoot} AND NOT "$ENV{SystemRoot}" STREQUAL "")
        file(TO_CMAKE_PATH "$ENV{SystemRoot}" _cmagneto_system_root)
        list(APPEND _cmagneto_post_exclude_regexes
            "^${_cmagneto_system_root}/System32/.*"
            "^${_cmagneto_system_root}/SysWOW64/.*"
        )
    endif()
elseif(_cmagneto_platform STREQUAL "Linux")
    list(APPEND _cmagneto_default_post_exclude_regexes
        ".*/ld-linux[^/]*\\.so[^/]*$"
        ".*/libc\\.so[^/]*$"
        ".*/libm\\.so[^/]*$"
        ".*/libgcc_s\\.so[^/]*$"
        ".*/libstdc\\+\\+\\.so[^/]*$"
        ".*/libpthread\\.so[^/]*$"
        ".*/librt\\.so[^/]*$"
        ".*/libdl\\.so[^/]*$"
    )
endif()

set(_cmagneto_runtime_dependency_args
    LIBRARIES ${_cmagneto_installed_bundled_paths}
)
if(NOT _cmagneto_known_library_dirs STREQUAL "")
    list(APPEND _cmagneto_runtime_dependency_args
        DIRECTORIES ${_cmagneto_known_library_dirs}
    )
endif()
if(NOT _cmagneto_pre_exclude_regexes STREQUAL "")
    list(APPEND _cmagneto_runtime_dependency_args
        PRE_EXCLUDE_REGEXES ${_cmagneto_pre_exclude_regexes}
    )
endif()
if(NOT _cmagneto_post_exclude_regexes STREQUAL "")
    list(APPEND _cmagneto_runtime_dependency_args
        POST_EXCLUDE_REGEXES ${_cmagneto_post_exclude_regexes}
    )
endif()
if(NOT _cmagneto_excluded_paths STREQUAL "")
    list(APPEND _cmagneto_runtime_dependency_args
        POST_EXCLUDE_FILES ${_cmagneto_excluded_paths}
    )
endif()

file(GET_RUNTIME_DEPENDENCIES
    RESOLVED_DEPENDENCIES_VAR _cmagneto_resolved_dependencies
    UNRESOLVED_DEPENDENCIES_VAR _cmagneto_unresolved_dependencies
    CONFLICTING_DEPENDENCIES_PREFIX _cmagneto_conflicting_dependencies
    ${_cmagneto_runtime_dependency_args}
)

if(NOT _cmagneto_unresolved_dependencies STREQUAL "")
    message(FATAL_ERROR
        "CMagneto failed to resolve transitive runtime dependencies of bundled external shared libraries: "
        "${_cmagneto_unresolved_dependencies}"
    )
endif()

if(DEFINED _cmagneto_conflicting_dependencies_FILENAMES AND NOT _cmagneto_conflicting_dependencies_FILENAMES STREQUAL "")
    message(FATAL_ERROR
        "CMagneto found conflicting transitive runtime dependencies of bundled external shared libraries: "
        "${_cmagneto_conflicting_dependencies_FILENAMES}"
    )
endif()

set(_cmagneto_additional_install_paths "")
foreach(_resolvedPath IN LISTS _cmagneto_resolved_dependencies)
    file(TO_CMAKE_PATH "${_resolvedPath}" _resolvedPathNormalized)
    if(_resolvedPathNormalized MATCHES "^${_cmagneto_install_root_regex}(/|$)")
        continue()
    endif()

    _cmagneto_get_installable_shared_library_path("${_resolvedPath}" _installablePath)
    list(APPEND _cmagneto_additional_install_paths "${_installablePath}")
endforeach()
list(REMOVE_DUPLICATES _cmagneto_additional_install_paths)
_cmagneto_filter_transitive_paths_by_precedence(
    "${_cmagneto_additional_install_paths}"
    "${_cmagneto_default_post_exclude_regexes}"
    _cmagneto_additional_install_paths
)

if(NOT _cmagneto_additional_install_paths STREQUAL "")
    file(COPY ${_cmagneto_additional_install_paths}
        DESTINATION "${_cmagneto_install_root}/${_cmagneto_destination_dir}"
        FOLLOW_SYMLINK_CHAIN
    )
endif()
]=])
    string(CONFIGURE "${_installScriptTemplate}" _installScriptContent @ONLY)

    set(_installScriptPath "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_TMP}/install_bundled_external_shared_libraries_runtime_dependencies.cmake")
    file(WRITE "${_installScriptPath}" "${_installScriptContent}")
    install(SCRIPT "${_installScriptPath}")
endfunction()
