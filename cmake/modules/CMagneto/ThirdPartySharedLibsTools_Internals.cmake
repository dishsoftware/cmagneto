# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

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

        get_target_property(_libType ${_lib} TYPE)
        if(NOT (_libType STREQUAL "SHARED_LIBRARY"))
            continue()
        endif()

        get_target_property(_nonBuildSpecificLibPath ${_lib} IMPORTED_LOCATION)
        if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
            CMagnetoInternal__add_path_to_shared_libs(${iTargetName} "NonSpecific" ${_nonBuildSpecificLibPath})
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

            CMagnetoInternal__add_path_to_shared_libs(${iTargetName} ${_config} ${_libPath})
        endforeach()
    endforeach()
endfunction()


set(CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")


function(CMagnetoInternal__get__3rd_party_shared_libs__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__3rd_party_shared_libs__content

    Returns content of the "3rd_party_shared_libs.json" file.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
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
    CMagnetoInternal__set_up__3rd_party_shared_libs__list

    Generates, places to build directory and installs "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file may be used to make distributable packages.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__3rd_party_shared_libs__list)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__3rd_party_shared_libs__file_name" "CMagnetoInternal__generate__3rd_party_shared_libs__content" FALSE TRUE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE "set_env")
set(CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")


function(CMagnetoInternal__get__set_env__script_file_name oFileName)
    CMagneto__platform__add_script_extension("${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}" _fileName)
    set(${oFileName} "${_fileName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__set_env__script_content

    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
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

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
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

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
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

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__env_vscode__file)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__env_vscode__file_name" "CMagnetoInternal__generate__env_vscode__file_content" FALSE FALSE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(CMagnetoInternal__RUN__SCRIPT_NAME_WE "run")
set(CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagnetoInternal__RUN__SCRIPT_NAME_WE}__TEMPLATE")


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