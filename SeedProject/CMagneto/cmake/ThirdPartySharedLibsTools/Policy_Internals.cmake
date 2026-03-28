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
