# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module loads other submodules and
    defines internal functions, variables, and constants that are not associated with any specific submodule.
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# CMakePackageConfigHelpers contains functions to create config files (*Config.cmake, *ConfigVersion.cmake, etc.),
# which are read by find_package() in consumer projects.
include(CMakePackageConfigHelpers)

# Set constants, which may be used by scripts and other modules.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Defines general-purpose functions to simplify integration with CMake generators of build system files.
include("${CMAKE_CURRENT_LIST_DIR}/GeneratorTools.cmake")

# Define general-purpose functions for path handling.
include("${CMAKE_CURRENT_LIST_DIR}/PathTools.cmake")

# Define general-purpose functions and variables to simplify Qt integration.
include("${CMAKE_CURRENT_LIST_DIR}/Qt.cmake")


function(CMagnetoInternal__compose_binary_OUTPUT_NAME iTargetName oBinaryOutputName)
    set(${oBinaryOutputName} "${PROJECT_NAME}${CMAKE_PROJECT_VERSION_MAJOR}_${iTargetName}" PARENT_SCOPE)
endfunction()


include("${CMAKE_CURRENT_LIST_DIR}/../QtWrappers.cmake")


# Appended every time CMagneto__set_up__library(iLibName) or CMagneto__set_up__executable(iExeName) is called.
set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS "")


#[[
    CMagnetoInternal__check_target_name_validity

    Checks if a target name is valid and not already registered. Registered target names are compared case-insensitively.
    Valid target names:
        * must start with a letter or underscore;
        * must contain only letters, digits, and underscores;
        * must not be made only of underscores.
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

    # Check if the target name is already registered.
    string(TOUPPER "${iTargetName}" _targetNameUC)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)
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
    CMagnetoInternal__add_path_to_shared_libs

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    iPath - path to a binary of a shared lib, which iTargetName is linked to.
]]
function(CMagnetoInternal__add_path_to_shared_libs iTargetName iBuildType iPath)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "CMagnetoInternal__PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
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
        set(_propName "CMagnetoInternal__PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "CMagnetoInternal__PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
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
    and stores them in a global properties CMagnetoInternal__PATHS_TO_SHARED_LIBS__${iTargetName} and CMagnetoInternal__PATHS_TO_${BUILD_TYPE}_SHARED_LIBS__${iTargetName}.
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

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)

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
                        CMagneto_warning("CMagnetoInternal__collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\".")
                        continue()
                    endif()
                endif()
            endif()

            CMagnetoInternal__add_path_to_shared_libs(${iTargetName} ${_config} ${_libPath})
        endforeach()
    endforeach()
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
                                 Paths must be under `${iAbsoluteTargetSourceRoot}/${CMagneto__SUBDIR_RESOURCES}/${CMagneto__SUBDIR_QTTS}`.
                                 Paths must not contain backslashes.
]]
function(CMagnetoInternal__set_up_QtTS_files iTargetName iAbsoluteTargetSourceRoot iQtTSFilePaths)
    if(iQtTSFilePaths STREQUAL "")
        return()
    endif()

    cmake_path(SET _targetAbsoluteQtTSSourceRoot NORMALIZE "${iAbsoluteTargetSourceRoot}/${CMagneto__SUBDIR_RESOURCES}/${CMagneto__SUBDIR_QTTS}/")

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
        cmake_path(SET _absQMFileDir NORMALIZE "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_RESOURCES}/${CMagneto__SUBDIR_QTTS}/${_targetSourceRootRelativeToProjectSourceRoot}/${_tsFileSubDir}/")
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
        cmake_path(SET _destination NORMALIZE "${CMagneto__SUBDIR_RESOURCES}/${CMagneto__SUBDIR_QTTS}/${_targetSourceRootRelativeToProjectSourceRoot}/${_tsFileSubDir}/")
        install(FILES "${_absQMFilePath}"
            DESTINATION "${_destination}"
            COMPONENT ${CMagneto__COMPONENT__RUNTIME} # TODO
        )
    endforeach()

    add_custom_target("${iTargetName}__QtTS" ALL DEPENDS ${_absQMFilePaths})
endfunction()


#[[
    CMagnetoInternal__set_up_file

    Places to build directory and installs to ${CMagneto__SUBDIR_EXECUTABLE} a file with name and content,
    which are returned by fileNameGetter(oFileName) and contentGetter(iConfig oContent) functions.
    If a generator supports multi-config, temporary files are generated for every configuration (Debug, Release, etc.) during
    configure/generation time and copied to ${CMagneto__SUBDIR_EXECUTABLE} during build of corresponding $<CONFIG>.
    oFileName - is also a name of an utility target (created within the function) that depends on the output file, if multi-config generator is used.
    It must not contain characters that are not allowed in target names; dots are replaced with underscores.

    parameters:
        iAddExePermission - if TRUE, the file is given execute permission (Unix only).
        iInstall - if TRUE, the file is installed to ${CMagneto__SUBDIR_EXECUTABLE}.
        iComponentName - name of the component to which the file is installed.
            If iInstall is FALSE, this parameter is ignored.
]]
function(CMagnetoInternal__set_up_file iFileNameGetterName iContentGetterName iAddExePermission iInstall iComponentName)
    CMagneto__is_multiconfig(IS_MULTICONFIG)
    set(_TMP_FILE_DIR "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_TMP}")
    cmake_language(CALL ${iFileNameGetterName} _fileName)

    if(IS_MULTICONFIG)
        foreach(_config ${CMAKE_CONFIGURATION_TYPES})
            cmake_language(CALL ${iContentGetterName} "${_config}" _fileContent)

            # Write contents to temporary files at configure time to copy them lately at build time.
            # Reason: there is no way to write $<CONFIG>-dependent generic contents to files at build time,
            # because CMake treats, for example, commas in JSONs as delimiters between arguments of generator expressions.
            # UPDATE: It is probably possible to escape commas with $<COMMA> (and other generator expression special characters) in contents.
            file(WRITE "${_TMP_FILE_DIR}/${_config}/${_fileName}" "${_fileContent}")
        endforeach()

        # Add a command to copy the file at build time.
        set(_filePath "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/$<CONFIG>/${_fileName}")
        set(_tmpFilePath "${_TMP_FILE_DIR}/$<CONFIG>/${_fileName}")

        set(_commands COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_tmpFilePath}" "${_filePath}")

        if(UNIX AND iAddExePermission)
            list(APPEND _commands COMMAND ${CMAKE_COMMAND} -E chmod +x "${_filePath}")
        endif()

        add_custom_command(
            OUTPUT "${_filePath}"
            ${_commands}
            DEPENDS "${_tmpFilePath}"
            COMMENT "Generating \"${_fileName}\" for config $<CONFIG>."
        )

        # Add an utility (phony) target that depends on the output file.
        string(REPLACE "." "_" _targetName "${_fileName}")
        add_custom_target(${_targetName} ALL
            DEPENDS "${_filePath}"
        )
    else()
        cmake_language(CALL ${iFileNameGetterName} _fileName)
        cmake_language(CALL ${iContentGetterName} "${CMAKE_BUILD_TYPE}" _fileContent)
        set(_filePath "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/${_fileName}")

        # Add the file to build dir(s) at configire time.
        file(WRITE "${_filePath}" "${_fileContent}")
        if (UNIX AND iAddExePermission)
            execute_process(COMMAND chmod u+x "${_filePath}")
        endif()
    endif()

    # Install the file.
    if(iInstall)
        if(iComponentName)
            if(UNIX AND iAddExePermission)
            # Maybe, it is better to use USE_SOURCE_PERMISSIONS.
            # Explicit setting of permissions only provide a bit of additional security.
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        else()
            if(UNIX AND iAddExePermission)
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        endif()
    endif()
endfunction()


set(CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")
function(CMagnetoInternal__get__3rd_party_shared_libs__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__3RD_PARTY_SHARED_LIBS__LIST_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__3rd_party_shared_libs__content

    Returns content of the "3rd_party_shared_libs.json" file.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagnetoInternal__generate__3rd_party_shared_libs__content iBuildType oContent)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)
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


set(CMagnetoInternal__SCRIPT_EXTENSION_UNIX "sh")
set(CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS "bat")

set(CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX "_Unix")
# The differentiation is required, because Unix_standard scripts can't be run on Unix or don't do what they are intented for.
# E.g. Android is also Unix, but not Unix-standard: some variables and functions are not available or restricted.
set(CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX_STANDARD "_Unix_standard")
set(CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS "_Windows")

set(CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME ".env.vscode")

set(CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE "set_env")
set(CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")

set(CMagnetoInternal__RUN__SCRIPT_NAME_WE "run")
set(CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagnetoInternal__RUN__SCRIPT_NAME_WE}__TEMPLATE")


function(CMagnetoInternal__get__set_env__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${CMagnetoInternal__SET_ENV__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagnetoInternal__generate__set_env__script_content

    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagnetoInternal__generate__set_env__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)

    set(_libraryDirs "")
    CMagnetoInternal__get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${CMagnetoInternal__SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX_STANDARD}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__env_vscode__file_name oFileName)
    set(${oFileName} "${CMagnetoInternal__ENV_VSCODE__SCRIPT_NAME}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__generate__env_vscode__file_content

    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagnetoInternal__generate__env_vscode__file_content iBuildType oFileContent)# Strings to replace in the template script.
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)

    set(_libraryDirs "")
    CMagnetoInternal__get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_fileContent "Path=\"${_libraryDirsNative}\"")
    else()
        set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
    endif()

    set(${oFileContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__run__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${CMagnetoInternal__RUN__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${CMagnetoInternal__RUN__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagnetoInternal__generate__run__script_content

    If a project entrypoint executable is set (look at CMagneto__set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after CMagneto__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__generate__run__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(EXECUTABLE_NAME_WE "param\\nEXECUTABLE_NAME_WE\\nparam")
    ####################################################################

    get_property(_is_PROJECT_ENTRYPOINT_EXE_set GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(NOT (_is_PROJECT_ENTRYPOINT_EXE_set))
        CMagneto_warning("CMagnetoInternal__generate__run__script_content: The project entrypoint executable is not set.")
        return()
    endif()
    get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
    CMagnetoInternal__compose_binary_OUTPUT_NAME(${_exeName} _exeName)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${CMagnetoInternal__RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


set(CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}__TEMPLATE")


#[[
    CMagnetoInternal__generate__run_tests__script_content

    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after CMagneto__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__generate__run_tests__script_content iBuildType oScriptContent)
# Strings to replace in the template script.
    set(DIR_WITH_CTESTTESTFILE "param\\nDIR_WITH_CTESTTESTFILE\\nparam")
    set(BUILD_CONFIG "param\\nBUILD_CONFIG\\nparam")
    set(REPORT_PATH "param\\nREPORT_PATH\\nparam")
    ####################################################################

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_dirWithCtestTestFile "../../${CMagneto__SUBDIR_CTESTTESTFILE}")
        set(_reportPath "../../${CMagneto__SUBDIR_SUMMARY}/${iBuildType}/${CMagneto__TEST_REPORT__FILE_NAME}")
    else()
        set(_dirWithCtestTestFile "../${CMagneto__SUBDIR_CTESTTESTFILE}")
        set(_reportPath "../${CMagneto__SUBDIR_SUMMARY}/${CMagneto__TEST_REPORT__FILE_NAME}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${DIR_WITH_CTESTTESTFILE}" "${_dirWithCtestTestFile}" _scriptContent "${_scriptContent}")
    string(REPLACE "${BUILD_CONFIG}" "${iBuildType}" _scriptContent "${_scriptContent}")
    string(REPLACE "${REPORT_PATH}" "${_reportPath}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__run_tests__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagnetoInternal__set_test_discovery

    Sets test discovery after build time and just before execution of test bodies.

    The function must be called after include(GoogleTest).
    If the function is not called, test discovery may be started during build time,
    and if paths to 3rd-party shared libraries are not set, build will fail.
]]
function(CMagnetoInternal__set_test_discovery iTestTargetName)
    # Triggers test discovery: runs the test executable with the --gtest_list_tests argument after build time just before execution of test bodies.
    # Creates a list of all test suites and test names (without executing their bodies).
    # Parses the list of tests, and adds each one to ctest.
    gtest_discover_tests(${iTestTargetName}
        DISCOVERY_MODE PRE_TEST # Not using of DISCOVERY_MODE POST_BUILD allows to not add ENVIRONMENT argument which is $<CONFIG>-dependent.
    )
endfunction()


set(CMagnetoInternal__GENERATE_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/generate_build_summary.cmake")


# Appended every time CMagneto__register_test_target(iTestTargetName) is called.
set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS "")


set(CMagnetoInternal__GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/generate_build_tests_summary.cmake")