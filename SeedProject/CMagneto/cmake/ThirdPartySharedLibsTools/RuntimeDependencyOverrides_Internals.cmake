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


function(CMagnetoInternal__append_unique_global_list_property iPropertyName iValues)
    get_property(_currentValues GLOBAL PROPERTY "${iPropertyName}")
    if(NOT DEFINED _currentValues)
        set(_currentValues "")
    endif()

    list(APPEND _currentValues ${iValues})
    list(REMOVE_DUPLICATES _currentValues)
    set_property(GLOBAL PROPERTY "${iPropertyName}" "${_currentValues}")
endfunction()


function(CMagnetoInternal__append_existing_path_variants iPaths oOutputPaths)
    set(_outputPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_path}" _pathNormalized)
        list(APPEND _outputPaths "${_pathNormalized}")

        get_filename_component(_realPath "${_pathNormalized}" REALPATH)
        if(EXISTS "${_realPath}" AND NOT _realPath STREQUAL "${_pathNormalized}")
            file(TO_CMAKE_PATH "${_realPath}" _realPathNormalized)
            list(APPEND _outputPaths "${_realPathNormalized}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _outputPaths)
    set(${oOutputPaths} "${_outputPaths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__normalize_runtime_dependency_path iRawPath iBaseDir oPath)
    file(TO_CMAKE_PATH "${iRawPath}" _pathNormalized)
    cmake_path(IS_ABSOLUTE _pathNormalized _isAbsolute)
    if(_isAbsolute)
        cmake_path(NORMAL_PATH _pathNormalized OUTPUT_VARIABLE _normalizedAbsolutePath)
        set(${oPath} "${_normalizedAbsolutePath}" PARENT_SCOPE)
        return()
    endif()

    cmake_path(ABSOLUTE_PATH _pathNormalized BASE_DIRECTORY "${iBaseDir}" NORMALIZE OUTPUT_VARIABLE _normalizedAbsolutePath)
    set(${oPath} "${_normalizedAbsolutePath}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__normalize_runtime_dependency_pattern iRawPattern iBaseDir oPattern)
    file(TO_CMAKE_PATH "${iRawPattern}" _patternNormalized)
    cmake_path(IS_ABSOLUTE _patternNormalized _isAbsolute)
    if(_isAbsolute)
        cmake_path(NORMAL_PATH _patternNormalized OUTPUT_VARIABLE _normalizedPattern)
        set(${oPattern} "${_normalizedPattern}" PARENT_SCOPE)
        return()
    endif()

    if("${_patternNormalized}" MATCHES "/")
        cmake_path(ABSOLUTE_PATH _patternNormalized BASE_DIRECTORY "${iBaseDir}" NORMALIZE OUTPUT_VARIABLE _normalizedPattern)
        set(${oPattern} "${_normalizedPattern}" PARENT_SCOPE)
    else()
        set(${oPattern} "${_patternNormalized}" PARENT_SCOPE)
    endif()
endfunction()


function(CMagnetoInternal__glob_pattern_to_regex iPattern oRegex)
    set(_regex "${iPattern}")
    string(REGEX REPLACE "([][+.^$(){}|\\\\])" "\\\\\\1" _regex "${_regex}")
    string(REPLACE "?" "." _regex "${_regex}")
    string(REPLACE "*" ".*" _regex "${_regex}")
    set(${oRegex} "${_regex}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__path_matches_runtime_dependency_patterns iPath iPatterns oMatches)
    file(TO_CMAKE_PATH "${iPath}" _pathNormalized)
    get_filename_component(_pathBasename "${_pathNormalized}" NAME)

    foreach(_pattern IN LISTS iPatterns)
        if(_pattern STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_pattern}" _patternNormalized)
        cmake_path(IS_ABSOLUTE _patternNormalized _patternIsAbsolute)
        CMagnetoInternal__glob_pattern_to_regex("${_patternNormalized}" _patternRegex)

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


function(CMagnetoInternal__filter_runtime_dependency_paths_by_excludes iPaths iExcludedFiles iExcludedPatterns oFilteredPaths)
    CMagnetoInternal__append_existing_path_variants("${iExcludedFiles}" _excludedFileVariants)

    set(_filteredPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_path}" _pathNormalized)

        set(_isExcluded FALSE)
        list(FIND _excludedFileVariants "${_pathNormalized}" _excludedFileIndex)
        if(_excludedFileIndex GREATER -1)
            set(_isExcluded TRUE)
        endif()

        if(NOT _isExcluded)
            get_filename_component(_realPath "${_pathNormalized}" REALPATH)
            if(EXISTS "${_realPath}")
                file(TO_CMAKE_PATH "${_realPath}" _realPathNormalized)
                list(FIND _excludedFileVariants "${_realPathNormalized}" _excludedRealPathIndex)
                if(_excludedRealPathIndex GREATER -1)
                    set(_isExcluded TRUE)
                endif()
            endif()
        endif()

        if(NOT _isExcluded)
            CMagnetoInternal__path_matches_runtime_dependency_patterns("${_pathNormalized}" "${iExcludedPatterns}" _matchesExcludedPattern)
            if(_matchesExcludedPattern)
                set(_isExcluded TRUE)
            endif()
        endif()

        if(NOT _isExcluded)
            list(APPEND _filteredPaths "${_pathNormalized}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _filteredPaths)
    set(${oFilteredPaths} "${_filteredPaths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__register_bundled_runtime_dependency_files iPaths iBaseDir)
    set(_normalizedPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__normalize_runtime_dependency_path("${_path}" "${iBaseDir}" _normalizedPath)
        list(APPEND _normalizedPaths "${_normalizedPath}")
    endforeach()

    CMagnetoInternal__append_unique_global_list_property("CMagnetoInternal__BundledRuntimeDependencyFiles" "${_normalizedPaths}")
endfunction()


function(CMagnetoInternal__register_bundled_runtime_dependency_file_patterns iPatterns iBaseDir)
    set(_normalizedPatterns "")
    foreach(_pattern IN LISTS iPatterns)
        if(_pattern STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__normalize_runtime_dependency_pattern("${_pattern}" "${iBaseDir}" _normalizedPattern)
        list(APPEND _normalizedPatterns "${_normalizedPattern}")
    endforeach()

    CMagnetoInternal__append_unique_global_list_property("CMagnetoInternal__BundledRuntimeDependencyFilePatterns" "${_normalizedPatterns}")
endfunction()


function(CMagnetoInternal__register_excluded_bundled_runtime_dependency_files iPaths iBaseDir)
    set(_normalizedPaths "")
    foreach(_path IN LISTS iPaths)
        if(_path STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__normalize_runtime_dependency_path("${_path}" "${iBaseDir}" _normalizedPath)
        list(APPEND _normalizedPaths "${_normalizedPath}")
    endforeach()

    CMagnetoInternal__append_unique_global_list_property("CMagnetoInternal__ExcludedBundledRuntimeDependencyFiles" "${_normalizedPaths}")
endfunction()


function(CMagnetoInternal__register_excluded_bundled_runtime_dependency_file_patterns iPatterns iBaseDir)
    set(_normalizedPatterns "")
    foreach(_pattern IN LISTS iPatterns)
        if(_pattern STREQUAL "")
            continue()
        endif()

        CMagnetoInternal__normalize_runtime_dependency_pattern("${_pattern}" "${iBaseDir}" _normalizedPattern)
        list(APPEND _normalizedPatterns "${_normalizedPattern}")
    endforeach()

    CMagnetoInternal__append_unique_global_list_property("CMagnetoInternal__ExcludedBundledRuntimeDependencyFilePatterns" "${_normalizedPatterns}")
endfunction()


function(CMagnetoInternal__get_runtime_dependency_override_list iCacheVarName iPropertyName iNormalizeKind oValues)
    set(_values ${${iCacheVarName}})

    get_property(_isSet GLOBAL PROPERTY "${iPropertyName}" SET)
    if(_isSet)
        get_property(_propertyValues GLOBAL PROPERTY "${iPropertyName}")
        list(APPEND _values ${_propertyValues})
    endif()

    set(_normalizedValues "")
    foreach(_value IN LISTS _values)
        if(_value STREQUAL "")
            continue()
        endif()

        if(iNormalizeKind STREQUAL "PATH")
            CMagnetoInternal__normalize_runtime_dependency_path("${_value}" "${CMAKE_SOURCE_DIR}" _normalizedValue)
        elseif(iNormalizeKind STREQUAL "PATTERN")
            CMagnetoInternal__normalize_runtime_dependency_pattern("${_value}" "${CMAKE_SOURCE_DIR}" _normalizedValue)
        else()
            CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_runtime_dependency_override_list: unsupported normalization kind \"${iNormalizeKind}\".")
        endif()

        list(APPEND _normalizedValues "${_normalizedValue}")
    endforeach()

    list(REMOVE_DUPLICATES _normalizedValues)
    set(${oValues} "${_normalizedValues}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_bundled_runtime_dependency_files oPaths)
    CMagnetoInternal__get_runtime_dependency_override_list(
        "CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILES"
        "CMagnetoInternal__BundledRuntimeDependencyFiles"
        "PATH"
        _paths
    )
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_bundled_runtime_dependency_file_patterns oPatterns)
    CMagnetoInternal__get_runtime_dependency_override_list(
        "CMagneto__BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS"
        "CMagnetoInternal__BundledRuntimeDependencyFilePatterns"
        "PATTERN"
        _patterns
    )
    set(${oPatterns} "${_patterns}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_excluded_bundled_runtime_dependency_files oPaths)
    CMagnetoInternal__get_runtime_dependency_override_list(
        "CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILES"
        "CMagnetoInternal__ExcludedBundledRuntimeDependencyFiles"
        "PATH"
        _paths
    )
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_excluded_bundled_runtime_dependency_file_patterns oPatterns)
    CMagnetoInternal__get_runtime_dependency_override_list(
        "CMagneto__EXCLUDED_BUNDLED_RUNTIME_DEPENDENCY_FILE_PATTERNS"
        "CMagnetoInternal__ExcludedBundledRuntimeDependencyFilePatterns"
        "PATTERN"
        _patterns
    )
    set(${oPatterns} "${_patterns}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__expand_runtime_dependency_file_patterns iPatterns iSearchDirs oPaths)
    set(_paths "")

    foreach(_pattern IN LISTS iPatterns)
        if(_pattern STREQUAL "")
            continue()
        endif()

        file(TO_CMAKE_PATH "${_pattern}" _patternNormalized)
        cmake_path(IS_ABSOLUTE _patternNormalized _patternIsAbsolute)
        if(_patternIsAbsolute)
            file(GLOB _matches LIST_DIRECTORIES FALSE "${_patternNormalized}")
            list(APPEND _paths ${_matches})
            continue()
        endif()

        foreach(_searchDir IN LISTS iSearchDirs)
            if(_searchDir STREQUAL "")
                continue()
            endif()
            file(GLOB _matches LIST_DIRECTORIES FALSE "${_searchDir}/${_patternNormalized}")
            list(APPEND _paths ${_matches})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _paths)
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()
