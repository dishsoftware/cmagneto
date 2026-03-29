# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
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
    This submodule of the CMagneto module defines internal functions and variables for setting up targets (common for static/shared libs and exes).
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Define general-purpose functions for path handling.
include("${CMAKE_CURRENT_LIST_DIR}/PathTools.cmake")


# Appended every time CMagneto__set_up__library(iLibTargetName) or CMagneto__set_up__executable(iExeTargetName) is called.
set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets "")


#[[
    CMagnetoInternal__check_target_name_validity

    Checks if a target name is valid, matches the target root path under `${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}`,
    and is not already registered. Registered target names are compared case-insensitively.
    Valid target names:
        * must start with a letter or underscore;
        * must contain only letters, digits, and underscores;
        * must not be made only of underscores.
        * must equal the target root path under `${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}`, with "/" replaced by "_".
]]
function(CMagnetoInternal__check_target_name_validity iTargetName)
    # Reject names made only of underscores
    string(REGEX MATCH "^_+$" _only_underscores "${iTargetName}")
    if(_only_underscores)
        CMagnetoInternal__message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must not be composed only of underscores.")
    endif()

    string(REGEX MATCH "^[a-zA-Z_][a-zA-Z0-9_]*$" _isValid "${iTargetName}")
    if(NOT _isValid)
        CMagnetoInternal__message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must start with a letter or underscore and contain only letters, digits, and underscores.")
    endif()

    CMagnetoInternal__compose_target_name("${CMAKE_CURRENT_SOURCE_DIR}" _expectedTargetName)
    if(NOT iTargetName STREQUAL _expectedTargetName)
        CMagnetoInternal__message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid for target root \"${CMAKE_CURRENT_SOURCE_DIR}\". Expected target name: \"${_expectedTargetName}\".")
    endif()

    # Check if the target name is already registered.
    string(TOUPPER "${iTargetName}" _targetNameUC)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    foreach(_registeredTarget IN LISTS _registeredTargets)
        string(TOUPPER "${_registeredTarget}" _registeredTargetUC)
        if(_targetNameUC STREQUAL _registeredTargetUC)
            if(iTargetName STREQUAL _registeredTarget)
                CMagnetoInternal__message(FATAL_ERROR "Target name \"${iTargetName}\" is already registered.")
            else()
                CMagnetoInternal__message(FATAL_ERROR "Target name \"${iTargetName}\" conflicts with previosly registered \"${_registeredTarget}\".")
            endif()
        endif()
    endforeach()
endfunction()


#[[
    CMagnetoInternal__compose_target_name

    Composes a target name from the path of the target root under `${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}`.
    Every "/" in the relative path is replaced with "_".

    Example:
        `${CMAKE_SOURCE_DIR}/src/Dish/ContactHolder/Contacts/` -> `Dish_ContactHolder_Contacts`
]]
function(CMagnetoInternal__compose_target_name iAbsoluteTargetSourceRoot oTargetName)
    cmake_path(SET _absoluteTargetSourceRoot NORMALIZE "${iAbsoluteTargetSourceRoot}/")
    cmake_path(SET _projectSourceRoot NORMALIZE "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}/")

    CMagneto__is_path_under_dir("${_absoluteTargetSourceRoot}" "${_projectSourceRoot}" _isTargetSourceRootUnderProjectSourceRoot)
    if(NOT _isTargetSourceRootUnderProjectSourceRoot)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__compose_target_name: target source root \"${_absoluteTargetSourceRoot}\" is not under the project source root \"${_projectSourceRoot}\".")
    endif()

    CMagneto__get_dir_relative_to_project_source_root("${_absoluteTargetSourceRoot}" _targetSourceRootRelativeToProjectSourceRoot)
    if("${_targetSourceRootRelativeToProjectSourceRoot}" STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__compose_target_name: target source root \"${_absoluteTargetSourceRoot}\" must not equal the project source root.")
    endif()

    string(REGEX REPLACE "/$" "" _targetSourceRootRelativeToProjectSourceRoot "${_targetSourceRootRelativeToProjectSourceRoot}")
    string(REPLACE "/" "_" _targetName "${_targetSourceRootRelativeToProjectSourceRoot}")
    set(${oTargetName} "${_targetName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__compose_namespaced_target_name

    Composes a target alias from the target name by replacing every "_" with "::".

    Example:
        `Dish_ContactHolder_Contacts` -> `Dish::ContactHolder::Contacts`
]]
function(CMagnetoInternal__compose_namespaced_target_name iTargetName oNamespacedTargetName)
    string(REPLACE "_" "::" _namespacedTargetName "${iTargetName}")
    set(${oNamespacedTargetName} "${_namespacedTargetName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up_export_header

    Ensures that `<TargetLeafName>_EXPORT.hpp` exists in the target source root.
    If the file does not exist, generates it and prints a message about the generation.

    Parameters:
        iTargetName          - Real CMake target name, e.g. `Dish_ContactHolder_Contacts`.
        oExportHeaderRelPath - Relative path to the ensured header, e.g. `Contacts_EXPORT.hpp`.
]]
function(CMagnetoInternal__set_up_export_header iTargetName oExportHeaderRelPath)
    cmake_path(GET CMAKE_CURRENT_SOURCE_DIR FILENAME _targetLeafName)
    set(_exportHeaderFileName "${_targetLeafName}_EXPORT.hpp")
    set(_exportHeaderAbsPath "${CMAKE_CURRENT_SOURCE_DIR}/${_exportHeaderFileName}")

    if(NOT EXISTS "${_exportHeaderAbsPath}")
        string(TOUPPER "${iTargetName}" _targetNameUC)
        set(_exportMacroName "${_targetNameUC}_EXPORT")

        set(_exportHeaderTemplate [=[
#pragma once

#ifndef COMPILE_TIME_MESSAGE
    #if defined(_MSC_VER)
        #define COMPILE_TIME_MESSAGE(msg) __pragma(message("[COMPILE MESSAGE] " msg))
    #else
        #define COMPILE_TIME_MESSAGE(msg) /* Unsupported compiler */
    #endif
#endif


#if defined(LIB_@TARGET_NAME_UC@_SHARED)
    #if defined(@TARGET_NAME_UC@_EXPORTS) || defined(@TARGET_NAME@_EXPORTS)
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define @EXPORT_MACRO_NAME@ __attribute__((visibility("default")))
                #pragma message ("MinGW Export")
            #elif defined(_MSC_VER)
                #define @EXPORT_MACRO_NAME@ __declspec(dllexport)
                COMPILE_TIME_MESSAGE("MSVC Export")
            #else
                #define @EXPORT_MACRO_NAME@
                #pragma message ("Windows Compiler (unknown) Export")
            #endif
        #else
            #if defined(__GNUC__)
                #define @EXPORT_MACRO_NAME@ __attribute__((visibility("default")))
                #pragma message ("GCC Export")
            #else
                #define @EXPORT_MACRO_NAME@
                #pragma message ("Other OS Non-GCC Export")
            #endif
        #endif
    #else
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define @EXPORT_MACRO_NAME@
                #pragma message ("MinGW Import")
            #elif defined(_MSC_VER)
                #define @EXPORT_MACRO_NAME@ __declspec(dllimport)
                COMPILE_TIME_MESSAGE("MSVC Import")
            #else
                #define @EXPORT_MACRO_NAME@
                #pragma message ("Windows Compiler (unknown) Import")
            #endif
        #else
            COMPILE_TIME_MESSAGE("NOT WIN")
            #if defined(__GNUC__)
                #define @EXPORT_MACRO_NAME@
                #pragma message ("GCC Import")
            #else
                #define @EXPORT_MACRO_NAME@
                #pragma message ("Other OS Non-GCC Import")
            #endif
        #endif
    #endif
#else
    #define @EXPORT_MACRO_NAME@
#endif


#if defined(_MSC_VER)
    #pragma warning (disable: 4251)
#endif
]=])

        set(TARGET_NAME "${iTargetName}")
        set(TARGET_NAME_UC "${_targetNameUC}")
        set(EXPORT_MACRO_NAME "${_exportMacroName}")
        string(CONFIGURE "${_exportHeaderTemplate}" _exportHeaderContent @ONLY)

        file(WRITE "${_exportHeaderAbsPath}" "${_exportHeaderContent}")
        CMagnetoInternal__message(STATUS "Generated missing export header \"${_exportHeaderAbsPath}\".")
    endif()

    set(${oExportHeaderRelPath} "${_exportHeaderFileName}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__set_up_defs_header

    Ensures that `<TargetLeafName>_DEFS.hpp` exists in the target source root.
    If the file does not exist, generates it and prints a message about the generation.

    Parameters:
        iTargetName         - Real CMake target name, e.g. `Dish_ContactHolder_Contacts`.
        iIncludeExportHeader - If TRUE, generated defs header includes `<TargetLeafName>_EXPORT.hpp`.
        oDefsHeaderRelPath  - Relative path to the ensured header, e.g. `Contacts_DEFS.hpp`.
]]
function(CMagnetoInternal__set_up_defs_header iTargetName iIncludeExportHeader oDefsHeaderRelPath)
    cmake_path(GET CMAKE_CURRENT_SOURCE_DIR FILENAME _targetLeafName)
    set(_defsHeaderFileName "${_targetLeafName}_DEFS.hpp")
    set(_defsHeaderAbsPath "${CMAKE_CURRENT_SOURCE_DIR}/${_defsHeaderFileName}")

    if(NOT EXISTS "${_defsHeaderAbsPath}")
        string(TOUPPER "${iTargetName}" _targetNameUC)
        set(_verifyMacroName "${_targetNameUC}_VERIFY")
        set(_assertMacroName "${_targetNameUC}_ASSERT")

        if(iIncludeExportHeader)
            set(_includeExportHeaderBlock "#include \"${_targetLeafName}_EXPORT.hpp\"\n\n")
        else()
            set(_includeExportHeaderBlock "")
        endif()

        set(_defsHeaderTemplate [=[
#pragma once

@INCLUDE_EXPORT_HEADER_BLOCK@#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define @VERIFY_MACRO_NAME@(x) assert(x);
    #define @ASSERT_MACRO_NAME@(x) assert(x);
#else
    #define @VERIFY_MACRO_NAME@(x) x
    #define @ASSERT_MACRO_NAME@(x)
#endif
]=])

        set(INCLUDE_EXPORT_HEADER_BLOCK "${_includeExportHeaderBlock}")
        set(VERIFY_MACRO_NAME "${_verifyMacroName}")
        set(ASSERT_MACRO_NAME "${_assertMacroName}")
        string(CONFIGURE "${_defsHeaderTemplate}" _defsHeaderContent @ONLY)

        file(WRITE "${_defsHeaderAbsPath}" "${_defsHeaderContent}")
        CMagnetoInternal__message(STATUS "Generated missing defs header \"${_defsHeaderAbsPath}\".")
    endif()

    set(${oDefsHeaderRelPath} "${_defsHeaderFileName}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__is_path_valid_for_CMakeLists iPath oErrorMessage)
    set(_errorMessage "")

    if(IS_ABSOLUTE "${_path}")
        set(_errorMessage "${_errorMessage}Path \"${iPath}\" is absolute.\nOnly relative paths are allowed in CMakeLists.txt.\n")
    endif()

    CMagneto__does_path_contain_backslash("${iPath}" _pathContainsBackslash)
    if(_pathContainsBackslash)
        set(_errorMessage "${_errorMessage}Path \"${iPath}\" contains \"\\\",\nwhich is not valid on Unix systems.\nOnly \"/\" is allowed as path leafs' separator in CMakeLists.txt.\n")
    endif()

    set(${oErrorMessage} "${_errorMessage}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__handle_source_paths

    Processes a list of input paths by resolving them relative to a specified source base directory.
    Produces two output lists:
        - OUTPUT_REL_PATHS: normalized paths relative to iAbsoluteSourceBaseDir;
        - OUTPUT_ABS_PATHS: normalized absolute paths.

    iPaths must reside under the project source root `${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}`, otherwise fails,
    unless a set of allowed locations is overridden by named parameters.

    Parameters:
        iAbsoluteSourceBaseDir             - Absolute path to a source base dir. Must be under the project source root.
        iAbsoluteSourceBaseDirDescription  - Description of the source base dir, e.g. `target "Contacts" TS files`. Used in logged messages.
        iPaths                             - Paths relative to iAbsoluteSourceBaseDir.
                                             Absolute paths and paths, containing backslashes, are prohibited under the project source root.

    Named input arguments:
        ALLOW_PATHS_UNDER_BUILD_BASE_DIR   - Flag (optional).
                                             If defined, paths under the build base dir `${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SOURCE}/${_sourceBaseDirRelativeToProjectSourceRoot}/`
                                             are also allowed. Paths under the dir can be absolute or contain backslashes.

        IF_PATH_OUTSIDE_SOURCE_BASE_DIR    - String (optional). Accepts one of: USE_ANYWAY (default), WARN, FAIL.
                                             If not USE_ANYWAY, restriction "iPaths must reside under the project source root"
                                             is narrowed down to "iPaths must reside under iAbsoluteSourceBaseDir".
                                             If WARN - just warns, doesn't fail. But still fails if an input path is not under the project source root.

    Named output arguments:
        OUTPUT_REL_PATHS                   - String (optional). Variable name in parent scope to assign normalized relative path.
        OUTPUT_ABS_PATHS                   - String (optional). Variable name in parent scope to assign normalized resolved absolute path.

    Notes:
    - If a path A equals path B, A is considered under B.
]]
function(CMagnetoInternal__handle_source_paths iAbsoluteSourceBaseDir iAbsoluteSourceBaseDirDescription iPaths)
    cmake_path(SET _absoluteSourceBaseDir NORMALIZE "${iAbsoluteSourceBaseDir}/")
    cmake_path(SET _projectSourceRoot NORMALIZE "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}/")
    CMagneto__is_path_under_dir("${_absoluteSourceBaseDir}" "${_projectSourceRoot}" _isSourceBaseDirUnderProjectSourceRoot)
    if(NOT _isSourceBaseDirUnderProjectSourceRoot)
        CMagnetoInternal__message(FATAL_ERROR "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): _absoluteSourceBaseDir is not under project \"${PROJECT_NAME}\" source root \"${_projectSourceRoot}\".")
    endif()

    cmake_parse_arguments(ARG
        "ALLOW_PATHS_UNDER_BUILD_BASE_DIR" # Options (boolean flags).
        "IF_PATH_OUTSIDE_SOURCE_BASE_DIR;OUTPUT_REL_PATHS;OUTPUT_ABS_PATHS" # Single-value keywords (strings).
        "" # Multi-value keywords (lists).
        ${ARGN}
    )
    set(_IF_PATH_OUTSIDE_SOURCE_BASE_DIR__ALLOWED_VALUES USE_ANYWAY WARN FAIL)
    set(_IF_PATH_OUTSIDE_SOURCE_BASE_DIR__DEFAULT_VALUE USE_ANYWAY)

    # Handle named arguments.
    ## Set default values to named parameters if not specified.
    if(NOT ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR)
        set(ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR ${_IF_PATH_OUTSIDE_SOURCE_BASE_DIR__DEFAULT_VALUE})
    endif()

    ## Validate named arguments.
    if(NOT ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR IN_LIST _IF_PATH_OUTSIDE_SOURCE_BASE_DIR__ALLOWED_VALUES)
        CMagneto__wrap_strings_in_quotes_and_join(_allowedValsStr ", " "${_IF_PATH_OUTSIDE_SOURCE_BASE_DIR__ALLOWED_VALUES}")
        set(_msgTemplate [=[
CMagnetoInternal__handle_source_paths: invalid value "${ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR}" of parameter IF_PATH_OUTSIDE_SOURCE_BASE_DIR.
                       Allowed values: ${_allowedValsStr}.
        ]=])
        string(CONFIGURE "${_msgTemplate}" _msg)
        CMagnetoInternal__message(FATAL_ERROR "${_msg}")
    endif()

    # Handle iPaths.
    set(_relPaths "")
    set(_absPaths "")
    set(_pathsOutsideProjectSourceRoot "")
    set(_pathsOutsideSourceBaseDir "")

    CMagneto__get_dir_relative_to_project_source_root("${_absoluteSourceBaseDir}" _sourceBaseDirRelativeToProjectSourceRoot)
    cmake_path(SET _absoluteBuildBaseDir NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SOURCE}/${_sourceBaseDirRelativeToProjectSourceRoot}/")
    CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): build base dir = \"${_absoluteBuildBaseDir}\".\n")

    foreach(_path IN LISTS iPaths)
        CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Handling of a path \"${_path}\" started.")

        if(IS_ABSOLUTE "${_path}")
            CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Input path is absolute.")
            cmake_path(SET _absPath NORMALIZE "${_path}")
            cmake_path(RELATIVE_PATH _absPath BASE_DIRECTORY "${_absoluteSourceBaseDir}" OUTPUT_VARIABLE _relPath)
        else()
            CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Input path is relative.")
            cmake_path(SET _absPath NORMALIZE "${_absoluteSourceBaseDir}/${_path}")
            cmake_path(SET _relPath NORMALIZE "${_path}")
        endif()

        CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Absolute path: \"${_absPath}\"")
        CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Relative path: \"${_relPath}\"")

        if(ARG_ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
            # Check if the path is under the build base dir.
            # Don't check whether the _path contains a backslash or is absolute: most probably the file is generated and added to iPaths automatically.
            CMagneto__is_path_under_dir("${_absPath}" "${_absoluteBuildBaseDir}" _pathIsUnderBuildBaseDir)
            if(_pathIsUnderBuildBaseDir)
                list(APPEND _relPaths "${_relPath}")
                list(APPEND _absPaths "${_absPath}")
                CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Handling of a path \"${_path}\" finished.\n")
                continue()
            endif()
        endif()

        CMagnetoInternal__is_path_valid_for_CMakeLists("${_path}" _errorMessage)
        if(NOT _errorMessage STREQUAL "")
            set(_msgTemplate [=[
${iAbsoluteSourceBaseDirDescription}.
${_errorMessage}
For ${iAbsoluteSourceBaseDirDescription} absolute paths or paths, containig "\",
are only allowed under the build base dir
"${_absoluteBuildBaseDir}".
            ]=])
            string(CONFIGURE "${_msgTemplate}" _msg)
            CMagnetoInternal__message(FATAL_ERROR "${_msg}")
        endif()

        if(NOT ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR STREQUAL "USE_ANYWAY")
            # Check if the path is not under the source base dir.
            CMagneto__is_path_under_dir("${_absPath}" "${_absoluteSourceBaseDir}" _pathIsUnderSourceBaseDir)
            if(NOT _pathIsUnderSourceBaseDir)
                set(_msg "Path \"${_path}\" is\n\toutside of the ${iAbsoluteSourceBaseDirDescription} source base dir\n\t\"${_absoluteSourceBaseDir}\"")
                if(ARG_ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
                    set(_msg "${_msg}\n\tand outside of the {iAbsoluteSourceBaseDirDescription} build base dir\n\t\"${_absoluteBuildBaseDir}\"")
                endif()
                set(_msg "${_msg}.")

                if(ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR STREQUAL "WARN")
                    CMagnetoInternal__message(WARNING "${_msg}")
                elseif(ARG_IF_PATH_OUTSIDE_SOURCE_BASE_DIR STREQUAL "FAIL")
                    CMagnetoInternal__message(FATAL_ERROR "${_msg}")
                endif()
            endif()
        endif()

        # Check if the path is not under the project source root.
        CMagneto__is_path_under_dir("${_absPath}" "${_projectSourceRoot}" _pathIsUnderProjectSourceRoot)
        if(NOT _pathIsUnderProjectSourceRoot)
            set(_msg "Path \"${_path}\" is\n\toutside of the project \"${PROJECT_NAME}\" source root\n\t\"${_projectSourceRoot}\"")
            if(ARG_ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
                set(_msg "${_msg}\n\tand outside of the {iAbsoluteSourceBaseDirDescription} build base dir\n\t\"${_absoluteBuildBaseDir}\"")
            endif()
            set(_msg "${_msg}.")
            CMagnetoInternal__message(FATAL_ERROR "${_msg}")
        endif()

        list(APPEND _relPaths "${_relPath}")
        list(APPEND _absPaths "${_absPath}")
        CMagnetoInternal__message(TRACE "CMagnetoInternal__handle_source_paths(${iAbsoluteSourceBaseDirDescription}): Handling of a path \"${_path}\" finished.\n")
    endforeach()

    # Return output.
    if(NOT ARG_OUTPUT_REL_PATHS STREQUAL "")
        set(${ARG_OUTPUT_REL_PATHS} "${_relPaths}" PARENT_SCOPE)
    endif()

    if(NOT ARG_OUTPUT_ABS_PATHS STREQUAL "")
        set(${ARG_OUTPUT_ABS_PATHS} "${_absPaths}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagnetoInternal__set_up_QtTS_files

    It must be called:
    - Once for the target.

    Parameters:
    iTargetName                - The name of the target to configure.
    iAbsoluteTargetSourceRoot  - Dir path, where root CMakeLists.txt of the target is defined.
    iQtTSFilePaths             - Paths of target *.ts files.
                                 Paths must be relative to iAbsoluteTargetSourceRoot.
                                 Paths must be under `${iAbsoluteTargetSourceRoot}/${CMagneto__SUBDIR_TARGET_RESOURCES}/${CMagneto__SUBDIR_QTTS}`.
                                 Paths must not contain backslashes.
]]
function(CMagnetoInternal__set_up_QtTS_files iTargetName iAbsoluteTargetSourceRoot iQtTSFilePaths)
    if(iQtTSFilePaths STREQUAL "")
        return()
    endif()

    cmake_path(SET _targetAbsoluteQtTSSourceRoot NORMALIZE "${iAbsoluteTargetSourceRoot}/${CMagneto__SUBDIR_TARGET_RESOURCES}/${CMagneto__SUBDIR_QTTS}/")

    # Check, that all files are under _targetAbsoluteQtTSSourceRoot.
    CMagnetoInternal__handle_source_paths(
        "${_targetAbsoluteQtTSSourceRoot}"
        "target \"${iTargetName}\" QtTS"
        "${iQtTSFilePaths}"
        IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
    )

    # Convert iQtTSFilePaths to absolute paths.
    CMagnetoInternal__handle_source_paths(
        "${iAbsoluteTargetSourceRoot}"
        "target \"${iTargetName}\" QtTS"
        "${iQtTSFilePaths}"
        OUTPUT_ABS_PATHS _absQtTSFilePaths
    )

    CMagneto__find__Qt_lrelease_executable(QT_LRELEASE_EXECUTABLE)
    CMagneto__get_dir_relative_to_project_source_root("${iAbsoluteTargetSourceRoot}" _targetSourceRootRelativeToProjectSourceRoot)
    foreach(_absQtTSFilePath IN LISTS _absQtTSFilePaths)
        cmake_path(GET _absQtTSFilePath PARENT_PATH _absQtTSFileDir)
        cmake_path(RELATIVE_PATH _absQtTSFileDir BASE_DIRECTORY "${_targetAbsoluteQtTSSourceRoot}" OUTPUT_VARIABLE _tsFileSubDir)
        cmake_path(GET _absQtTSFilePath STEM LAST_ONLY _QtTSFileNameWE)
        cmake_path(SET _absQMFileDir NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_TARGET_RESOURCES}/${CMagneto__SUBDIR_QTTS}/${_targetSourceRootRelativeToProjectSourceRoot}/${_tsFileSubDir}/")
        cmake_path(SET _absQMFilePath NORMALIZE "${_absQMFileDir}/${_QtTSFileNameWE}.qm")
        CMagnetoInternal__message(TRACE "CMagnetoInternal__set_up_QtTS_files(${iTargetName}): path to compile *.qm file \"${_absQMFilePath}\".")

        file(MAKE_DIRECTORY "${_absQMFileDir}") # Without creation of the dir before calling the lrelease, compilation fails on Linux.
        add_custom_command(
            OUTPUT "${_absQMFilePath}"
            COMMAND ${QT_LRELEASE_EXECUTABLE} ${_absQtTSFilePath} -qm ${_absQMFilePath}
            DEPENDS "${_absQtTSFilePath}"
            COMMENT "Compiling \"${_absQtTSFilePath}\"."
        )
        list(APPEND _absQMFilePaths "${_absQMFilePath}")

        # Install the *.qm file.
        cmake_path(SET _destination NORMALIZE "${CMagneto__SUBDIR_TARGET_RESOURCES}/${CMagneto__SUBDIR_QTTS}/${_targetSourceRootRelativeToProjectSourceRoot}/${_tsFileSubDir}/")
        install(FILES "${_absQMFilePath}"
            DESTINATION "${_destination}"
            COMPONENT ${CMagneto__COMPONENT__RUNTIME} # TODO
        )
    endforeach()

    add_custom_target("${iTargetName}__QtTS" ALL DEPENDS ${_absQMFilePaths})
endfunction()
