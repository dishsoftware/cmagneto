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

        CMagnetoInternal__ensure_imported_shared_library_paths_registered(${_target})
        set_property(GLOBAL PROPERTY "CMagnetoInternal__ExternalSharedLibraryInstallMode__${_target}" "${iMode}")
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


#[[
    CMagnetoInternal__register_imported_shared_library_paths

    Records runtime artifact paths once per imported target, including build-type-specific
    variants so every later consumer can query the same imported-target source of truth.
]]
function(CMagnetoInternal__register_imported_shared_library_paths iImportedTarget)
    CMagnetoInternal__get_imported_shared_library_paths(${iImportedTarget} _allPaths)
    set_property(GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}" "${_allPaths}")

    CMagnetoInternal__get_imported_shared_library_paths_for_build_type(${iImportedTarget} "NonSpecific" _nonSpecificPaths)
    set_property(GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}__NONSPECIFIC" "${_nonSpecificPaths}")

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
        CMagnetoInternal__get_imported_shared_library_paths_for_build_type(${iImportedTarget} "${_configUpper}" _configPaths)
        set_property(GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}__${_configUpper}" "${_configPaths}")
    endforeach()
endfunction()


#[[
    CMagnetoInternal__ensure_imported_shared_library_paths_registered

    Ensures that imported-target runtime paths are registered before install mode, manifest,
    runtime setup, or helper scripts query them.
]]
function(CMagnetoInternal__ensure_imported_shared_library_paths_registered iImportedTarget)
    get_property(_isSet GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}" SET)
    if(_isSet)
        return()
    endif()

    CMagnetoInternal__register_imported_shared_library_paths(${iImportedTarget})
endfunction()


#[[
    CMagnetoInternal__get_registered_imported_shared_library_paths_for_build_type

    Returns the build-type-specific runtime paths recorded for an imported target.
    These values are written during registration so the same fallback rules are reused by
    manifest generation and diagnostics.
]]
function(CMagnetoInternal__get_registered_imported_shared_library_paths_for_build_type iImportedTarget iBuildType oPaths)
    string(TOUPPER "${iBuildType}" _buildTypeUpper)
    if(_buildTypeUpper STREQUAL "")
        set(_buildTypeUpper "NONSPECIFIC")
    endif()

    get_property(_isSet GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}__${_buildTypeUpper}" SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY "CMagnetoInternal__ImportedSharedLibraryPaths__${iImportedTarget}__${_buildTypeUpper}")
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__ensure_external_shared_library_policy_registered iImportedTarget)
    CMagnetoInternal__ensure_imported_shared_library_paths_registered(${iImportedTarget})

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
    CMagnetoInternal__register_linked_imported_shared_library_targets

    Registers imported shared-library targets linked by iTargetName and ensures their
    runtime artifact paths are recorded centrally by imported target, not by project target.

    The method was written to overcome the following limitation:
        "get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)" does not return all linked libraries, if called from not the same folder where iTargetName is declared.

    Parameters:
    iTargetName - name of a target created in the project.
]]
function(CMagnetoInternal__register_linked_imported_shared_library_targets iTargetName)
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

        # Policy and runtime artifact paths are registered by imported target.
        # Only the target-to-imported-target linkage is stored here for later manifest queries.
        CMagnetoInternal__ensure_external_shared_library_policy_registered(${_lib})
        CMagnetoInternal__add_linked_imported_shared_library_target(${iTargetName} ${_lib})
    endforeach()
endfunction()
