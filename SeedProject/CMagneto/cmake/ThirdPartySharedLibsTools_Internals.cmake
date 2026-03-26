# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines internal functions and variables for handling 3rd-party shared libraries.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Define constants and functions for handling scripts.
include("${CMAKE_CURRENT_LIST_DIR}/Platform.cmake")

# Define general-purpose functions generation and installation of arbitrary files.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpFile.cmake")

# Define functions and variables for setting up targets (common for static/shared libs and exes).
include("${CMAKE_CURRENT_LIST_DIR}/SetUpTarget.cmake")

# Define unctions and variables for setting up static/shared library targets.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpLibTarget.cmake")

# Define unctions and variables for setting up executable targets.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpExeTarget.cmake")


set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE "EXPECT_ON_TARGET_MACHINE")
set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE "BUNDLE_WITH_PACKAGE")

set(CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE ""
    CACHE STRING
    "Semicolon-separated imported shared-library targets expected to be installed on the target machine at the same absolute locations as on the build machine."
)
set(CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE ""
    CACHE STRING
    "Semicolon-separated imported shared-library targets that must be bundled into the installation package."
)


#[[
    CMagnetoInternal__add_path_to_shared_libs

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    iPath - path to a binary of a shared lib, which iTargetName is linked to.
]]
function(CMagnetoInternal__add_path_to_shared_libs iTargetName iBuildType iPath)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "CMagnetoInternal__PathsToSharedLibs__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PathsTo_${_buildType}_SharedLibs__${iTargetName}")
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    if(NOT DEFINED _paths)
        set(_paths "")
    endif()

    list(APPEND _paths ${iPath})
    list(REMOVE_DUPLICATES _paths)

    set_property(GLOBAL PROPERTY "${_propName}" "${_paths}")
endfunction()


#[[
    CMagnetoInternal__get_paths_to_shared_libs

    Returns paths to binaries of shared libraries, which iTargetName is linked to.

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    Paths to shared libs for iTargetName are filled when CMagneto__set_up__library(iTargetName) or CMagneto__set_up__executable(iTargetName) are called.
]]
function(CMagnetoInternal__get_paths_to_shared_libs iTargetName iBuildType oPaths)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "CMagnetoInternal__PathsToSharedLibs__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PathsTo_${_buildType}_SharedLibs__${iTargetName}")
    endif()

    get_property(_isSet GLOBAL PROPERTY "${_propName}" SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


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


function(CMagnetoInternal__register_external_shared_libraries_install_mode iMode iImportedTargets)
    if(NOT (
        iMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE
        OR
        iMode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE
    ))
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__register_external_shared_libraries_install_mode: unsupported mode \"${iMode}\".")
    endif()

    foreach(_target IN LISTS iImportedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_target} _existingMode)
        if(NOT (_existingMode STREQUAL "" OR _existingMode STREQUAL "${iMode}"))
            CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__register_external_shared_libraries_install_mode: target \"${_target}\" is already configured with mode \"${_existingMode}\", cannot change it to \"${iMode}\".")
        endif()

        CMagnetoInternal__get_imported_shared_library_paths(${_target} _validatedPaths)
        set_property(GLOBAL PROPERTY "CMagnetoInternal__ExternalSharedLibraryInstallMode__${_target}" "${iMode}")
        set_property(GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${_target}" "${_validatedPaths}")
    endforeach()
endfunction()


function(CMagnetoInternal__get_configured_external_shared_libraries_install_mode iImportedTarget oMode)
    list(FIND CMagneto__EXTERNAL_SHARED_LIBRARIES__EXPECT_ON_TARGET_MACHINE "${iImportedTarget}" _expectIdx)
    list(FIND CMagneto__EXTERNAL_SHARED_LIBRARIES__BUNDLE_WITH_PACKAGE "${iImportedTarget}" _bundleIdx)

    if(_expectIdx GREATER -1 AND _bundleIdx GREATER -1)
        CMagnetoInternal__message(FATAL_ERROR "Imported shared library target \"${iImportedTarget}\" is configured both as EXPECT_ON_TARGET_MACHINE and BUNDLE_WITH_PACKAGE. Check the current build-variant definition.")
    elseif(_expectIdx GREATER -1)
        set(${oMode} "${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE}" PARENT_SCOPE)
    elseif(_bundleIdx GREATER -1)
        set(${oMode} "${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE}" PARENT_SCOPE)
    else()
        set(${oMode} "" PARENT_SCOPE)
    endif()
endfunction()


function(CMagnetoInternal__get_external_shared_libraries_install_mode iImportedTarget oMode)
    get_property(_isSet GLOBAL PROPERTY "CMagnetoInternal__ExternalSharedLibraryInstallMode__${iImportedTarget}" SET)
    if(NOT _isSet)
        set(${oMode} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_mode GLOBAL PROPERTY "CMagnetoInternal__ExternalSharedLibraryInstallMode__${iImportedTarget}")
    set(${oMode} "${_mode}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_registered_imported_shared_library_paths iImportedTarget oPaths)
    get_property(_isSet GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}" SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}")
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__json_escape_string iInput oEscapedString)
    set(_escapedString "${iInput}")
    string(REPLACE "\\" "\\\\" _escapedString "${_escapedString}")
    string(REPLACE "\"" "\\\"" _escapedString "${_escapedString}")
    string(REPLACE "\n" "\\n" _escapedString "${_escapedString}")
    string(REPLACE "\r" "\\r" _escapedString "${_escapedString}")
    string(REPLACE "\t" "\\t" _escapedString "${_escapedString}")
    set(${oEscapedString} "${_escapedString}" PARENT_SCOPE)
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


function(CMagnetoInternal__ensure_external_shared_library_policy_registered iImportedTarget)
    CMagnetoInternal__get_external_shared_libraries_install_mode(${iImportedTarget} _registeredMode)
    if(NOT _registeredMode STREQUAL "")
        return()
    endif()

    CMagnetoInternal__get_configured_external_shared_libraries_install_mode(${iImportedTarget} _configuredMode)
    if(_configuredMode STREQUAL "")
        return()
    endif()

    CMagnetoInternal__register_external_shared_libraries_install_mode("${_configuredMode}" "${iImportedTarget}")
endfunction()


function(CMagnetoInternal__add_linked_imported_shared_library_target iTargetName iImportedTarget)
    set(_propName "CMagnetoInternal__LinkedImportedSharedLibraryTargets__${iTargetName}")

    get_property(_targets GLOBAL PROPERTY "${_propName}")
    if(NOT DEFINED _targets)
        set(_targets "")
    endif()

    list(APPEND _targets ${iImportedTarget})
    list(REMOVE_DUPLICATES _targets)
    set_property(GLOBAL PROPERTY "${_propName}" "${_targets}")
endfunction()


function(CMagnetoInternal__get_linked_imported_shared_library_targets iTargetName oImportedTargets)
    set(_propName "CMagnetoInternal__LinkedImportedSharedLibraryTargets__${iTargetName}")

    get_property(_isSet GLOBAL PROPERTY "${_propName}" SET)
    if(NOT _isSet)
        set(${oImportedTargets} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_targets GLOBAL PROPERTY "${_propName}")
    set(${oImportedTargets} "${_targets}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get_all_paths_to_shared_libs

    Returns a union of build-type-specific and non-build-type-specific paths to imported shared libraries,
    which iTargetName is linked to.
]]
function(CMagnetoInternal__get_all_paths_to_shared_libs iTargetName oPaths)
    set(_allPaths "")

    CMagnetoInternal__get_paths_to_shared_libs(${iTargetName} "NonSpecific" _nonSpecificPaths)
    list(APPEND _allPaths ${_nonSpecificPaths})

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
    elseif(NOT CMAKE_BUILD_TYPE STREQUAL "")
        set(_buildConfigs "${CMAKE_BUILD_TYPE}")
    else()
        set(_buildConfigs "")
    endif()

    foreach(_config IN LISTS _buildConfigs)
        CMagnetoInternal__get_paths_to_shared_libs(${iTargetName} "${_config}" _configPaths)
        list(APPEND _allPaths ${_configPaths})
    endforeach()

    list(REMOVE_DUPLICATES _allPaths)
    set(${oPaths} "${_allPaths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_shared_library_dirs_for_target iTargetName oLibraryDirs)
    set(_libraryDirs "")

    CMagnetoInternal__get_all_paths_to_shared_libs(${iTargetName} _libPaths)
    foreach(_libPath IN LISTS _libPaths)
        cmake_path(GET _libPath PARENT_PATH _libDir)
        if(NOT _libDir STREQUAL "")
            list(APPEND _libraryDirs ${_libDir})
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_imported_shared_library_dirs_for_target iTargetName iMode oLibraryDirs)
    set(_libraryDirs "")

    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _mode)
        if(NOT (_mode STREQUAL "${iMode}"))
            continue()
        endif()

        CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _libPaths)
        foreach(_libPath IN LISTS _libPaths)
            cmake_path(GET _libPath PARENT_PATH _libDir)
            if(NOT _libDir STREQUAL "")
                list(APPEND _libraryDirs ${_libDir})
            endif()
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get_external_shared_library_paths_to_bundle oPaths)
    set(_pathsToBundle "")

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    foreach(_target IN LISTS _registeredTargets)
        CMagnetoInternal__get_linked_imported_shared_library_targets(${_target} _importedTargets)
        foreach(_importedTarget IN LISTS _importedTargets)
            CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _mode)
            if(_mode STREQUAL CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__BUNDLE_WITH_PACKAGE)
                CMagnetoInternal__get_registered_imported_shared_library_paths(${_importedTarget} _importedTargetPaths)
                foreach(_importedTargetPath IN LISTS _importedTargetPaths)
                    CMagnetoInternal__get_installable_shared_library_path("${_importedTargetPath}" _installablePath)
                    list(APPEND _pathsToBundle ${_installablePath})
                endforeach()
            endif()
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _pathsToBundle)
    set(${oPaths} "${_pathsToBundle}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__warn_about_unclassified_external_shared_libraries iTargetName)
    set(_unclassifiedImportedTargets "")

    CMagnetoInternal__get_linked_imported_shared_library_targets(${iTargetName} _importedTargets)
    foreach(_importedTarget IN LISTS _importedTargets)
        CMagnetoInternal__get_external_shared_libraries_install_mode(${_importedTarget} _mode)
        if(_mode STREQUAL "")
            list(APPEND _unclassifiedImportedTargets ${_importedTarget})
        endif()
    endforeach()

    list(REMOVE_DUPLICATES _unclassifiedImportedTargets)
    if(_unclassifiedImportedTargets STREQUAL "")
        return()
    endif()

    string(JOIN "\", \"" _targetsJoined ${_unclassifiedImportedTargets})
    set(_message
        "CMagneto target \"${iTargetName}\" links imported shared libraries without an install mode decision: "
        "\"${_targetsJoined}\". Installed binaries may still require the legacy `set_env` helper or rely on platform "
        "default search paths. Configure such dependencies in the active build variant with "
        "expectExternalSharedLibrariesOnTargetMachine(...) or bundleExternalSharedLibraries(...), "
        "or mark them explicitly in CMake as a manual override."
    )
    string(CONCAT _message ${_message})
    CMagnetoInternal__message(WARNING "${_message}")
endfunction()


#[[
    CMagnetoInternal__get_shared_library_dirs

    Returns directories, containing 3rd-party shared libraries, which iTargets are linked to.
    If a shared library is in iTargets or defined in the project, it's path is not returned.
]]
function(CMagnetoInternal__get_shared_library_dirs oLibraryDirs iTargets iBuildType)
    set(_libraryDirs "")

    foreach(_target ${iTargets})
        if(NOT TARGET ${_target})
            continue()
        endif()

        get_target_property(_targetLinkLibraries ${_target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        CMagnetoInternal__get_paths_to_shared_libs(${_target} ${iBuildType} _libPaths)
        foreach(_libPath ${_libPaths})
            cmake_path(GET _libPath PARENT_PATH _libDir)
            list(APPEND _libraryDirs ${_libDir})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__collect_paths_to_shared_libs

    The method collects paths to binaries of 3rd-party shared libraries, which iTargetName is linked to,
    and stores them in a global properties CMagnetoInternal__PathsToSharedLibs__${iTargetName} and CMagnetoInternal__PathsTo_${BUILD_TYPE}_SharedLibs__${iTargetName}.
    Should be called from the same folder where iTargetName is declared after libraries are linked to iTargetName.

    The method was written to overcome the following limitation:
        "get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)" does not return all linked libraries, if called from not the same folder where iTargetName is declared.

    Parameters:
    iTargetName - name of a target created in the project.
]]
function(CMagnetoInternal__collect_paths_to_shared_libs iTargetName)
    get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)
    if(_targetLinkLibraries STREQUAL "NOTFOUND")
        return()
    endif()

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    foreach(_lib ${_targetLinkLibraries})
        if(NOT TARGET ${_lib})
            continue()
        endif()

        # Skip, if the linked library is a target of the project.
        list(FIND _registeredTargets ${_lib} _index)
        if (${_index} GREATER -1)
            continue()
        endif()

        CMagnetoInternal__is_imported_shared_library_target(${_lib} _isImportedSharedLibrary)
        if(NOT _isImportedSharedLibrary)
            continue()
        endif()

        CMagnetoInternal__ensure_external_shared_library_policy_registered(${_lib})
        CMagnetoInternal__add_linked_imported_shared_library_target(${iTargetName} ${_lib})

        get_target_property(_nonBuildSpecificLibPath ${_lib} IMPORTED_LOCATION)
        if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
            CMagnetoInternal__is_path_to_shared_library("${_nonBuildSpecificLibPath}" _isSharedLibraryPath)
            if(_isSharedLibraryPath)
                CMagnetoInternal__add_path_to_shared_libs(${iTargetName} "NonSpecific" ${_nonBuildSpecificLibPath})
            endif()
        endif()

        CMagneto__is_multiconfig(IS_MULTICONFIG)
        if(IS_MULTICONFIG)
            set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
        else()
            set(_buildConfigs "${CMAKE_BUILD_TYPE}")
        endif()

        foreach(_config ${_buildConfigs})
            string(TOUPPER "${_config}" _config)

            get_target_property(_libPath ${_lib} IMPORTED_LOCATION_${_config})
            if(NOT (_libPath AND EXISTS ${_libPath}))
                CMagnetoInternal__message(STATUS "CMagnetoInternal__collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\". Trying to get a path to RELEASE or non-build-type-specific binary instead.")
                get_target_property(_libPath ${_lib} IMPORTED_LOCATION_RELEASE)
                if(NOT (_libPath AND EXISTS ${_libPath}))
                    if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
                        set(_libPath ${_nonBuildSpecificLibPath})
                    else()
                        CMagnetoInternal__message(WARNING "CMagnetoInternal__collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\".")
                        continue()
                    endif()
                endif()
            endif()

            CMagnetoInternal__is_path_to_shared_library("${_libPath}" _isSharedLibraryPath)
            if(_isSharedLibraryPath)
                CMagnetoInternal__add_path_to_shared_libs(${iTargetName} ${_config} ${_libPath})
            endif()
        endforeach()
    endforeach()
endfunction()


set(CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")
set(CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_DEPLOYMENT__FILE_NAME "external_shared_library_deployment.json")


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
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_allImportedTargets "")
    foreach(_target IN LISTS _registeredTargets)
        CMagnetoInternal__get_linked_imported_shared_library_targets(${_target} _importedTargets)
        list(APPEND _allImportedTargets ${_importedTargets})
    endforeach()
    list(REMOVE_DUPLICATES _allImportedTargets)

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

    Generates, places to build directory and installs "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file may be used to make distributable packages.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__3rd_party_shared_libs__list)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__3rd_party_shared_libs__file_name" "CMagnetoInternal__generate__3rd_party_shared_libs__content" FALSE TRUE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagnetoInternal__set_up__external_shared_library_deployment__list

    Generates and places the imported shared-library deployment metadata into the build tree.
    The file is consumed by package verification code and is not installed as a build-machine-specific artifact.
]]
function(CMagnetoInternal__set_up__external_shared_library_deployment__list)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__external_shared_library_deployment__file_name" "CMagnetoInternal__generate__external_shared_library_deployment__content" FALSE FALSE "")
endfunction()


#[[
    CMagnetoInternal__set_up_target_runtime_resolution

    Configures runtime dependency lookup for a target in build and install trees.
    On Linux, imported shared-library directories are added to BUILD_RPATH for local runs,
    while relative INSTALL_RPATH values are used for relocatable project binaries.
    On Windows, runtime DLLs are copied next to the target binary in the build tree.
]]
function(CMagnetoInternal__set_up_target_runtime_resolution iTargetName)
    if(NOT TARGET ${iTargetName})
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__set_up_target_runtime_resolution: target \"${iTargetName}\" does not exist.")
    endif()

    get_target_property(_targetType ${iTargetName} TYPE)

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        CMagnetoInternal__warn_about_unclassified_external_shared_libraries(${iTargetName})

        CMagnetoInternal__get_shared_library_dirs_for_target(${iTargetName} _libraryDirs)
        set(_buildRPath "${_libraryDirs}")
        set(_installRPath "")

        CMagnetoInternal__get_imported_shared_library_dirs_for_target(
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
    elseif(WIN32)
        if(_targetType STREQUAL "EXECUTABLE" OR _targetType STREQUAL "SHARED_LIBRARY" OR _targetType STREQUAL "MODULE_LIBRARY")
            add_custom_command(TARGET ${iTargetName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    $<TARGET_RUNTIME_DLLS:${iTargetName}>
                    $<TARGET_FILE_DIR:${iTargetName}>
                COMMAND_EXPAND_LISTS
            )
        endif()
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

    CMagnetoInternal__get_external_shared_library_paths_to_bundle(_libPaths)
    if(_libPaths STREQUAL "")
        return()
    endif()

    set(_installPaths "")
    foreach(_libPath IN LISTS _libPaths)
        list(APPEND _installPaths "${_libPath}")

        get_filename_component(_realPath "${_libPath}" REALPATH)
        if(EXISTS "${_realPath}" AND NOT _realPath STREQUAL "${_libPath}")
            list(APPEND _installPaths "${_realPath}")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES _installPaths)

    install(FILES ${_installPaths}
        DESTINATION ${_destinationDir}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )
endfunction()


set(CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE "set_env")
set(CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")


function(CMagnetoInternal__get__set_env__script_file_name oFileName)
    CMagneto__platform__add_script_extension("${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}" _fileName)
    set(${oFileName} "${_fileName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__set_env__script_content

    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__generate__set_env__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_libraryDirs "")
    CMagnetoInternal__get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    CMagneto__platform__add_script_suffix_and_extension("${CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}" _templateScriptPath)

    file(READ "${_templateScriptPath}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up__set_env__script

    Generates, places to build directory and installs "set_env" script.
    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__set_env__script)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__set_env__script_file_name" "CMagnetoInternal__generate__set_env__script_content" TRUE TRUE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME ".env.vscode")


function(CMagnetoInternal__get__env_vscode__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__env_vscode__file_content

    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__generate__env_vscode__file_content iBuildType oFileContent)# Strings to replace in the template script.
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    # Add paths to dirs with 3rd-party shared libs.
    set(_libraryDirs "")
    CMagnetoInternal__get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_fileContent "Path=\"${_libraryDirsNative}\"")
    else()
        set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
    endif()

    # Add a var, containig an entrypoint executable compiled binary name.
    ## Idea was to set the binary name in VC Code `launch.json` from the `.env.vscode` file.
    ## But VS Code does not use "envFile" during resolving variables in the "program" configuration property in `launch.json`.
    CMagneto__get_project_entrypoint(_exeTargetName)
    if(DEFINED _exeTargetName)
        CMagneto__compose_binary_OUTPUT_NAME(${_exeTargetName} _binaryOutputName)
        CMagneto__platform__add_executable_extension("${_binaryOutputName}" _exeName)
        set(_fileContent "${_fileContent}\nCMagneto__ProjectEntrypointExe=\"${_exeName}\"")
    endif()

    set(${oFileContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up__env_vscode__file

    Generates and places to build directory ".env.vscode" file.
    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__env_vscode__file)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__env_vscode__file_name" "CMagnetoInternal__generate__env_vscode__file_content" FALSE FALSE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(CMagnetoInternal__RUN__SCRIPT_NAME_WE "run")
set(CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/${CMagnetoInternal__RUN__SCRIPT_NAME_WE}__TEMPLATE")


function(CMagnetoInternal__get__run__script_file_name oFileName)
    CMagneto__platform__add_script_extension("${CMagnetoInternal__RUN__SCRIPT_NAME_WE}" _fileName)
    set(${oFileName} "${_fileName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__run__script_content

    If a project entrypoint executable is set (look at CMagneto__set_project_entrypoint(iExeTargetName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after CMagnetoInternal__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__generate__run__script_content iBuildType oScriptContent)
    CMagneto__get_project_entrypoint(_exeTargetName)
    if(NOT DEFINED _exeTargetName)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__generate__run__script_content: The project entrypoint executable target is not set.")
        return()
    endif()

    # Strings to replace in the template script.
    set(_EXECUTABLE_NAME_WE "param\\nEXECUTABLE_NAME_WE\\nparam")
    ####################################################################

    CMagneto__compose_binary_OUTPUT_NAME(${_exeTargetName} _binaryOutputName)
    CMagneto__platform__add_script_suffix_and_extension("${CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX}" _templateScriptPath)
    file(READ "${_templateScriptPath}" _scriptContent)
    string(REPLACE "${_EXECUTABLE_NAME_WE}" "${_binaryOutputName}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up__run__script

    Generates, places to build directory and installs "run" script.
    If a project entrypoint executable is set (look at CMagneto__set_project_entrypoint(iExeTargetName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after CMagnetoInternal__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__set_up__run__script)
    CMagneto__get_project_entrypoint(_exeTargetName)
    if(NOT DEFINED _exeTargetName)
        CMagnetoInternal__message(WARNING "CMagnetoInternal__generate__run__script_content: The project entrypoint executable target is not set. \"${CMagnetoInternal__RUN__SCRIPT_NAME_WE}\" script is not created.")
        return()
    endif()

    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__run__script_file_name" "CMagnetoInternal__generate__run__script_content" TRUE TRUE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()
