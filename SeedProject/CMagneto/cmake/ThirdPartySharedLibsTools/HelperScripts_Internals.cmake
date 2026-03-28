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

set(CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE "set_env")
set(CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")


function(CMagnetoInternal__get__set_env__script_file_name oFileName)
    CMagneto__platform__add_script_extension("${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}" _fileName)
    set(${oFileName} "${_fileName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__set_env__script_content

    The script sets paths only to directories of imported shared libraries expected to be present on the target machine.
    Build-machine-specific directories of bundled shared libraries must not be exported by this helper.
    The directory list is derived from the runtime dependency manifest query layer so helper
    scripts follow the same external-dependency classification as runtime setup.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__generate__set_env__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)

    set(_libraryDirs "")
    CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_dirs_for_targets_by_mode(
        "${_registeredTargets}"
        "${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE}"
        _libraryDirs
    )
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    CMagneto__platform__add_script_suffix_and_extension("${CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}" _templateScriptPath)

    file(READ "${_templateScriptPath}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up__set_env__script

    Generates and places to build directory "set_env" script.
    The script sets paths to directories with imported shared libraries expected to be present on the target machine.
    The script is a build-tree-only development helper and must not be installed or distributed.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__set_up__set_env__script)
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__set_env__script_file_name" "CMagnetoInternal__generate__set_env__script_content" TRUE FALSE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME ".env.vscode")


function(CMagnetoInternal__get__env_vscode__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__env_vscode__file_content

    The file sets Path/LD_LIBRARY_PATH equal only to dirs of imported shared libraries expected to be present on the target machine.
    Build-machine-specific directories of bundled shared libraries must not be exported by this helper.
    The directory list is derived from the runtime dependency manifest query layer so helper
    scripts follow the same external-dependency classification as runtime setup.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all CMagneto__set_up__library(iLibTargetName) and CMagneto__set_up__executable(iExeTargetName) are called.
]]
function(CMagnetoInternal__generate__env_vscode__file_content iBuildType oFileContent)# Strings to replace in the template script.
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    # Add paths only to dirs with imported shared libs expected on the target machine.
    set(_libraryDirs "")
    CMagnetoInternal__runtime_dependency_manifest__get_imported_shared_library_dirs_for_targets_by_mode(
        "${_registeredTargets}"
        "${CMagnetoInternal__EXTERNAL_SHARED_LIBRARY_INSTALL_MODE__EXPECT_ON_TARGET_MACHINE}"
        _libraryDirs
    )
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

    Generates and places to build directory "run" script.
    If a project entrypoint executable is set (look at CMagneto__set_project_entrypoint(iExeTargetName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.
    The script is a build-tree-only development helper and must not be installed or distributed.

    The function must be called after CMagnetoInternal__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__set_up__run__script)
    CMagneto__get_project_entrypoint(_exeTargetName)
    if(NOT DEFINED _exeTargetName)
        CMagnetoInternal__message(WARNING "CMagnetoInternal__generate__run__script_content: The project entrypoint executable target is not set. \"${CMagnetoInternal__RUN__SCRIPT_NAME_WE}\" script is not created.")
        return()
    endif()

    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE("CMagnetoInternal__get__run__script_file_name" "CMagnetoInternal__generate__run__script_content" TRUE FALSE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()
