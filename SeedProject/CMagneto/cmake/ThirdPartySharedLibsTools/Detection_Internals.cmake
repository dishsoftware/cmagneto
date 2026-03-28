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
    CMagnetoInternal__is_path_to_shared_library

    Returns whether iPath points to a runtime shared-library binary on the current platform.
    This helper is needed because some imported runtime-library targets are exposed by CMake
    as UNKNOWN_LIBRARY even though their resolved artifact is a shared library.
]]
function(CMagnetoInternal__is_path_to_shared_library iPath oIsSharedLibrary)
    if(NOT EXISTS "${iPath}")
        set(${oIsSharedLibrary} FALSE PARENT_SCOPE)
        return()
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        execute_process(
            COMMAND readelf -h "${iPath}"
            RESULT_VARIABLE _readelfResult
            OUTPUT_VARIABLE _readelfOutput
            ERROR_QUIET
        )
        if(_readelfResult EQUAL 0 AND _readelfOutput MATCHES "Type:[ \t]+DYN")
            set(${oIsSharedLibrary} TRUE PARENT_SCOPE)
            return()
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        get_filename_component(_extension "${iPath}" EXT)
        if(_extension STREQUAL ".dll")
            set(${oIsSharedLibrary} TRUE PARENT_SCOPE)
            return()
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        if("${iPath}" MATCHES "\\.dylib$")
            set(${oIsSharedLibrary} TRUE PARENT_SCOPE)
            return()
        endif()
    endif()

    set(${oIsSharedLibrary} FALSE PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__is_imported_shared_library_target

    Returns whether iTargetName is an imported target representing a runtime shared library.
    Targets with CMake type UNKNOWN_LIBRARY are accepted as well if their resolved runtime
    artifacts are detected as shared-library binaries.
]]
function(CMagnetoInternal__is_imported_shared_library_target iTargetName oIsImportedSharedLibrary)
    if(NOT TARGET ${iTargetName})
        set(${oIsImportedSharedLibrary} FALSE PARENT_SCOPE)
        return()
    endif()

    get_target_property(_isImported ${iTargetName} IMPORTED)
    if(NOT _isImported)
        set(${oIsImportedSharedLibrary} FALSE PARENT_SCOPE)
        return()
    endif()

    get_target_property(_targetType ${iTargetName} TYPE)
    if(_targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY")
        set(${oIsImportedSharedLibrary} TRUE PARENT_SCOPE)
        return()
    endif()

    if(NOT _targetType STREQUAL "UNKNOWN_LIBRARY")
        set(${oIsImportedSharedLibrary} FALSE PARENT_SCOPE)
        return()
    endif()

    set(_candidatePaths "")

    get_target_property(_nonBuildSpecificLibPath ${iTargetName} IMPORTED_LOCATION)
    if(_nonBuildSpecificLibPath AND EXISTS "${_nonBuildSpecificLibPath}")
        list(APPEND _candidatePaths "${_nonBuildSpecificLibPath}")
    endif()

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
    elseif(NOT CMAKE_BUILD_TYPE STREQUAL "")
        set(_buildConfigs "${CMAKE_BUILD_TYPE}")
    else()
        set(_buildConfigs "")
    endif()

    foreach(_config IN LISTS _buildConfigs)
        string(TOUPPER "${_config}" _configUpper)
        get_target_property(_libPath ${iTargetName} IMPORTED_LOCATION_${_configUpper})
        if(_libPath AND EXISTS "${_libPath}")
            list(APPEND _candidatePaths "${_libPath}")
            continue()
        endif()

        get_target_property(_releaseLibPath ${iTargetName} IMPORTED_LOCATION_RELEASE)
        if(_releaseLibPath AND EXISTS "${_releaseLibPath}")
            list(APPEND _candidatePaths "${_releaseLibPath}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _candidatePaths)
    foreach(_candidatePath IN LISTS _candidatePaths)
        CMagnetoInternal__is_path_to_shared_library("${_candidatePath}" _isSharedLibraryPath)
        if(_isSharedLibraryPath)
            set(${oIsImportedSharedLibrary} TRUE PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${oIsImportedSharedLibrary} FALSE PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_imported_shared_library_paths iTargetName oPaths)
    if(NOT TARGET ${iTargetName})
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths: target \"${iTargetName}\" does not exist.")
    endif()

    get_target_property(_isImported ${iTargetName} IMPORTED)
    if(NOT _isImported)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths: target \"${iTargetName}\" is not imported.")
    endif()

    CMagnetoInternal__is_imported_shared_library_target(${iTargetName} _isImportedSharedLibrary)
    if(NOT _isImportedSharedLibrary)
        get_target_property(_targetType ${iTargetName} TYPE)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths: target \"${iTargetName}\" must resolve to an imported shared or module library, got type \"${_targetType}\".")
    endif()

    set(_paths "")
    get_target_property(_targetType ${iTargetName} TYPE)

    get_target_property(_nonBuildSpecificLibPath ${iTargetName} IMPORTED_LOCATION)
    if(_nonBuildSpecificLibPath AND EXISTS "${_nonBuildSpecificLibPath}")
        CMagnetoInternal__is_path_to_shared_library("${_nonBuildSpecificLibPath}" _isSharedLibraryPath)
        if(_targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY" OR _isSharedLibraryPath)
            list(APPEND _paths "${_nonBuildSpecificLibPath}")
        endif()
    endif()

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
    elseif(NOT CMAKE_BUILD_TYPE STREQUAL "")
        set(_buildConfigs "${CMAKE_BUILD_TYPE}")
    else()
        set(_buildConfigs "")
    endif()

    foreach(_config IN LISTS _buildConfigs)
        string(TOUPPER "${_config}" _configUpper)
        get_target_property(_libPath ${iTargetName} IMPORTED_LOCATION_${_configUpper})
        if(NOT (_libPath AND EXISTS "${_libPath}"))
            get_target_property(_libPath ${iTargetName} IMPORTED_LOCATION_RELEASE)
            if(NOT (_libPath AND EXISTS "${_libPath}"))
                set(_libPath "${_nonBuildSpecificLibPath}")
            endif()
        endif()

        if(_libPath AND EXISTS "${_libPath}")
            CMagnetoInternal__is_path_to_shared_library("${_libPath}" _isSharedLibraryPath)
            if(_targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY" OR _isSharedLibraryPath)
                list(APPEND _paths "${_libPath}")
            endif()
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _paths)
    if(_paths STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths: no valid runtime artifact paths were found for imported target \"${iTargetName}\".")
    endif()

    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get_imported_shared_library_paths_for_build_type

    Returns runtime artifact paths for one build type of an imported shared library target.
    For a requested configuration, falls back to RELEASE and then to IMPORTED_LOCATION.
    For "NonSpecific", returns only IMPORTED_LOCATION when it resolves to a shared library.
    The helper exists so imported-target path registration can persist both build-type-specific
    and non-build-type-specific runtime artifact views for later manifest queries.
]]
function(CMagnetoInternal__get_imported_shared_library_paths_for_build_type iTargetName iBuildType oPaths)
    if(NOT TARGET ${iTargetName})
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths_for_build_type: target \"${iTargetName}\" does not exist.")
    endif()

    get_target_property(_isImported ${iTargetName} IMPORTED)
    if(NOT _isImported)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths_for_build_type: target \"${iTargetName}\" is not imported.")
    endif()

    CMagnetoInternal__is_imported_shared_library_target(${iTargetName} _isImportedSharedLibrary)
    if(NOT _isImportedSharedLibrary)
        get_target_property(_targetType ${iTargetName} TYPE)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__get_imported_shared_library_paths_for_build_type: target \"${iTargetName}\" must resolve to an imported shared or module library, got type \"${_targetType}\".")
    endif()

    set(_paths "")
    get_target_property(_targetType ${iTargetName} TYPE)

    get_target_property(_nonBuildSpecificLibPath ${iTargetName} IMPORTED_LOCATION)
    if(_nonBuildSpecificLibPath AND EXISTS "${_nonBuildSpecificLibPath}")
        CMagnetoInternal__is_path_to_shared_library("${_nonBuildSpecificLibPath}" _isSharedLibraryPath)
        if(_targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY" OR _isSharedLibraryPath)
            string(TOUPPER "${iBuildType}" _buildTypeUpper)
            if(_buildTypeUpper STREQUAL "" OR _buildTypeUpper STREQUAL "NONSPECIFIC")
                list(APPEND _paths "${_nonBuildSpecificLibPath}")
            endif()
        endif()
    endif()

    string(TOUPPER "${iBuildType}" _buildTypeUpper)
    if(_buildTypeUpper STREQUAL "" OR _buildTypeUpper STREQUAL "NONSPECIFIC")
        list(REMOVE_DUPLICATES _paths)
        set(${oPaths} "${_paths}" PARENT_SCOPE)
        return()
    endif()

    get_target_property(_libPath ${iTargetName} IMPORTED_LOCATION_${_buildTypeUpper})
    if(NOT (_libPath AND EXISTS "${_libPath}"))
        CMagnetoInternal__message(STATUS "CMagnetoInternal__get_imported_shared_library_paths_for_build_type(\"${iTargetName}\" \"${iBuildType}\"): path to ${_buildTypeUpper} binary is not found or invalid: \"${_libPath}\". Trying RELEASE or non-build-type-specific binary instead.")
        get_target_property(_libPath ${iTargetName} IMPORTED_LOCATION_RELEASE)
        if(NOT (_libPath AND EXISTS "${_libPath}"))
            if(_nonBuildSpecificLibPath AND EXISTS "${_nonBuildSpecificLibPath}")
                set(_libPath "${_nonBuildSpecificLibPath}")
            else()
                CMagnetoInternal__message(WARNING "CMagnetoInternal__get_imported_shared_library_paths_for_build_type(\"${iTargetName}\" \"${iBuildType}\"): no valid runtime artifact path was found.")
                set(${oPaths} "" PARENT_SCOPE)
                return()
            endif()
        endif()
    endif()

    CMagnetoInternal__is_path_to_shared_library("${_libPath}" _isSharedLibraryPath)
    if(_targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY" OR _isSharedLibraryPath)
        list(APPEND _paths "${_libPath}")
    endif()

    list(REMOVE_DUPLICATES _paths)
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get_elf_soname

    Returns SONAME of an ELF shared library if it is present and can be read with `readelf`.
    On failure or if SONAME is absent, returns an empty string.
]]
function(CMagnetoInternal__get_elf_soname iLibraryPath oSoname)
    execute_process(
        COMMAND readelf -d "${iLibraryPath}"
        RESULT_VARIABLE _readelfResult
        OUTPUT_VARIABLE _readelfOutput
        ERROR_QUIET
    )
    if(NOT _readelfResult EQUAL 0)
        set(${oSoname} "" PARENT_SCOPE)
        return()
    endif()

    string(REGEX MATCH "Library soname: \\[([^]]+)\\]" _sonameMatch "${_readelfOutput}")
    set(${oSoname} "${CMAKE_MATCH_1}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get_installable_shared_library_path

    Returns the path that should be copied into a package for an imported shared library.
    On Linux, prefers the SONAME file when it exists so packaged binaries resolve the deployed runtime name.
]]
function(CMagnetoInternal__get_installable_shared_library_path iLibraryPath oInstallablePath)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        CMagnetoInternal__get_elf_soname("${iLibraryPath}" _soname)
        if(NOT _soname STREQUAL "")
            cmake_path(GET iLibraryPath PARENT_PATH _libraryParentDir)
            set(_sonamePath "${_libraryParentDir}/${_soname}")
            if(EXISTS "${_sonamePath}")
                set(${oInstallablePath} "${_sonamePath}" PARENT_SCOPE)
                return()
            endif()
        endif()
    endif()

    set(${oInstallablePath} "${iLibraryPath}" PARENT_SCOPE)
endfunction()
