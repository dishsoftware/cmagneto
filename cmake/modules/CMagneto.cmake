# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This file contains functions and variables to set up targets, install them and generate scripts and auxilliary files.
    Glossary:
        - configure time:
            CMake processes the top-level CMakeLists.txt and all subdirectories to understand your project structure, options, and dependencies.
        - generation time:
            CMake generates the build system files (e.g., Makefiles, Visual Studio project files) based on the configuration.
            Dependencies and build rules are created.
        - build time:
            CMake builds the project using the generated build system files.
            This is when the actual compilation and linking of the code happens.
        - install time:
            CMake installs the built targets to the specified locations.
            This is when the final binaries, libraries, and resources are copied to their installation directories.

        Whenever a "target" is mentioned without additinal context, it means a target created in the project using add_library() or add_executable().

    How to use this file:
        0) Include ./parse_meta.cmake before "project()" command. Add the "project()" command:
            include("${CMAKE_SOURCE_DIR}/cmake/modules/CMagneto/parse_meta.cmake")
            project("${PROJECT_JSON__COMPANY_NAME_SHORT}_${PROJECT_JSON__PROJECT_NAME_BASE}"
                DESCRIPTION "${PROJECT_JSON__PROJECT_DESCRIPTION}"
                HOMEPAGE_URL "${PROJECT_JSON__PROJECT_HOMEPAGE}"
                VERSION "${PROJECT_JSON__PROJECT_VERSION}"
                LANGUAGES CXX
            )

        1) Include this file in root CMakeLists.txt, e.g.:
            include(${CMAKE_CURRENT_LIST_DIR}/CMagneto.cmake)

        2) Call set_up_library() or set_up_executable() to set up project targets.

        3) Call set_up_project() to generate build stage reports, helper scripts, etc.
            This function should be called after all targets are set up.

        4) Call add__build_tests__target() to set up the tests target.
            This function should be called after all targets with tests are added.
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/log.cmake")


# CMakePackageConfigHelpers contains functions to create config files (*Config.cmake, *ConfigVersion.cmake, etc.),
# which are read by find_package() in consumer projects.
include(CMakePackageConfigHelpers)


# Build/install subdirectory names.
set(SUBDIR_SOURCE "src")
set(SUBDIR_STATIC "lib")
set(SUBDIR_SHARED "lib") # On Windows, .dll files are the shared libraries, but CMake treats them as runtime artifacts, not library artifacts.
set(SUBDIR_EXECUTABLE "bin")
set(SUBDIR_INCLUDE "include")
set(SUBDIR_CMAKE "lib/cmake")
set(SUBDIR_RESOURCES "resources")
set(SUBDIR_TMP "TMP")
set(SUBDIR_SUMMARY "summary")
set(SUBDIR_CTESTTESTFILE "tests")
set(SUBDIR_PACKAGES "packages")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_STATIC}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_SHARED}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}")

set(COMPONENT__RUNTIME "Runtime")
set(COMPONENT__DEVELOPMENT "Development")
set(COMPONENT__BUILD_MACHINE_SPECIFIC "BuildMachineSpecific")

# These postfixes do not affect executable target output names.
set(CMAKE_DEBUG_POSTFIX "_D")
set(CMAKE_RELWITHDEBINFO_POSTFIX "_RDI")
set(CMAKE_MINSIZEREL_POSTFIX "_MSR")

function(compose_binary_OUTPUT_NAME iTargetName oBinaryOutputName)
    set(${oBinaryOutputName} "${PROJECT_NAME}${CMAKE_PROJECT_VERSION_MAJOR}_${iTargetName}" PARENT_SCOPE)
endfunction()



function(print_platform_and_compiler)
    CMagneto__message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
    CMagneto__message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    CMagneto__message(STATUS "Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
    CMagneto__message(STATUS "Compiler Path: ${CMAKE_CXX_COMPILER}")
endfunction()


#[[
    are_paths_equal

    Resolves variables, "..", ".", etc. and compares paths.
]]
function(are_paths_equal iPathA iPathB oAreEqual)
    get_filename_component(_pathA "${iPathA}" REALPATH)
    get_filename_component(_pathB "${iPathB}" REALPATH)

    if("${_pathA}" STREQUAL "${_pathB}")
        set(${oAreEqual} TRUE PARENT_SCOPE)
    else()
        set(${oAreEqual} FALSE PARENT_SCOPE)
    endif()
endfunction()


#[[
    set__IS_MULTTCONFIG__property

    Defines IS_MULTTCONFIG global boolean property as TRUE, if generator supports multi-config, and FALSE otherwise.
    Calling it directly is not necessary, if IS_MULTTCONFIG is only retrieved using is_multiconfig(oIsMulticonfig).
    However, it is better to call it as early as possible to avoid errors,
    if get_property(oIsMulticonfig GLOBAL PROPERTY IS_MULTTCONFIG) is used and called earlier, than is_multiconfig(oIsMulticonfig).
]]
function(set__IS_MULTTCONFIG__property)
    get_property(_isSet GLOBAL PROPERTY IS_MULTTCONFIG SET)
    if(_isSet)
        return()
    endif()

    if(CMAKE_VERSION VERSION_LESS "3.3.0")
        # Bug https://cmake.org/Bug/view.php?id=15577 .
        if(CMAKE_BUILD_TYPE)
            CMagneto__message(DEBUG "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        else()
            CMagneto__message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        endif()
    else()
        if(CMAKE_CONFIGURATION_TYPES)
            CMagneto__message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        else()
            CMagneto__message(DEBUG "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        endif()
    endif()
endfunction()


function(is_multiconfig oIsMulticonfig)
    get_property(_isSet GLOBAL PROPERTY IS_MULTTCONFIG SET)
    if(NOT _isSet)
        set__IS_MULTTCONFIG__property()
    endif()

    get_property(_isMulticonfig GLOBAL PROPERTY IS_MULTTCONFIG)
    set(${oIsMulticonfig} ${_isMulticonfig} PARENT_SCOPE)
endfunction()


include(${CMAKE_CURRENT_LIST_DIR}/QtWrappers.cmake)


# Appended every time set_up_library(iLibName) or set_up_executable(iExeName) is called.
set_property(GLOBAL PROPERTY REGISTERED_TARGETS "")


#[[
    check_target_name_validity

    Checks if a target name is valid and not already registered. Registered target names are compared case-insensitively.
    Valid target names:
        * must start with a letter or underscore;
        * must contain only letters, digits, and underscores;
        * must not be made only of underscores.
]]
function(check_target_name_validity iTargetName)
    # Reject names made only of underscores
    string(REGEX MATCH "^_+$" _only_underscores "${iTargetName}")
    if(_only_underscores)
        CMagneto__message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must not be composed only of underscores.")
    endif()

    string(REGEX MATCH "^[a-zA-Z_][a-zA-Z0-9_]*$" _isValid "${iTargetName}")
    if(NOT _isValid)
        CMagneto__message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must start with a letter or underscore and contain only letters, digits, and underscores.")
    endif()

    # Check if the target name is already registered.
    string(TOUPPER "${iTargetName}" _targetNameUC)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    foreach(_registeredTarget IN LISTS _registeredTargets)
        string(TOUPPER "${_registeredTarget}" _registeredTargetUC)
        if(_targetNameUC STREQUAL _registeredTargetUC)
            if(iTargetName STREQUAL _registeredTarget)
                CMagneto__message(FATAL_ERROR "Target name \"${iTargetName}\" is already registered.")
            else()
                CMagneto__message(FATAL_ERROR "Target name \"${iTargetName}\" conflicts with previosly registered \"${_registeredTarget}\".")
            endif()
        endif()
    endforeach()
endfunction()


#[[
    add_path_to_shared_libs

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    iPath - path to a binary of a shared lib, which iTargetName is linked to.
]]
function(add_path_to_shared_libs iTargetName iBuildType iPath)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
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
    get_paths_to_shared_libs

    Returns paths to binaries of shared libraries, which iTargetName is linked to.

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    Paths to shared libs for iTargetName are filled when set_up_library(iTargetName) or set_up_executable(iTargetName) are called.
]]
function(get_paths_to_shared_libs iTargetName iBuildType oPaths)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
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
    get_shared_library_dirs

    Returns directories, containing 3rd-party shared libraries, which iTargets are linked to.
    If a shared library is in iTargets or defined in the project, it's path is not returned.
]]
function(get_shared_library_dirs oLibraryDirs iTargets iBuildType)
    set(_libraryDirs "")

    foreach(_target ${iTargets})
        if(NOT TARGET ${_target})
            continue()
        endif()

        get_target_property(_targetLinkLibraries ${_target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        get_paths_to_shared_libs(${_target} ${iBuildType} _libPaths)
        foreach(_libPath ${_libPaths})
            get_filename_component(_libDir ${_libPath} DIRECTORY)
            list(APPEND _libraryDirs ${_libDir})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


#[[
    collect_paths_to_shared_libs

    The method collects paths to binaries of 3rd-party shared libraries, which iTargetName is linked to,
    and stores them in a global properties PATHS_TO_SHARED_LIBS__${iTargetName} and PATHS_TO_${BUILD_TYPE}_SHARED_LIBS__${iTargetName}.
    Should be called from the same folder where iTargetName is declared after libraries are linked to iTargetName.

    The method was written to overcome the following limitation:
        "get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)" does not return all linked libraries, if called from not the same folder where iTargetName is declared.

    Parameters:
    iTargetName - name of a target created in the project.
]]
function(collect_paths_to_shared_libs iTargetName)
    get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)
    if(_targetLinkLibraries STREQUAL "NOTFOUND")
        return()
    endif()

    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

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
            add_path_to_shared_libs(${iTargetName} "NonSpecific" ${_nonBuildSpecificLibPath})
        endif()

        is_multiconfig(IS_MULTICONFIG)
        if(IS_MULTICONFIG)
            set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
        else()
            set(_buildConfigs "${CMAKE_BUILD_TYPE}")
        endif()

        foreach(_config ${_buildConfigs})
            string(TOUPPER "${_config}" _config)

            get_target_property(_libPath ${_lib} IMPORTED_LOCATION_${_config})
            if(NOT (_libPath AND EXISTS ${_libPath}))
                CMagneto__message(STATUS "collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\". Trying to get a path to RELEASE or non-build-type-specific binary instead.")
                get_target_property(_libPath ${_lib} IMPORTED_LOCATION_RELEASE)
                if(NOT (_libPath AND EXISTS ${_libPath}))
                    if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
                        set(_libPath ${_nonBuildSpecificLibPath})
                    else()
                        CMagneto_warning("collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\".")
                        continue()
                    endif()
                endif()
            endif()

            add_path_to_shared_libs(${iTargetName} ${_config} ${_libPath})
        endforeach()
    endforeach()
endfunction()


function(set_up_project)
    # Export all targets to a single export set.
    install(EXPORT ${PROJECT_NAME}Targets
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
        COMPONENT ${COMPONENT__DEVELOPMENT}
    )

    # Create a template "${PROJECT_NAME}Config.cmake.in" file.
    set(_cmake_in__content [[
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@Targets.cmake")
    ]])
    set(_cmake_in__path "${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE "${_cmake_in__path}" "${_cmake_in__content}")

    # Generate the ${PROJECT_NAME}Config.cmake using the template file.
    configure_package_config_file(
        "${_cmake_in__path}"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
    )

    # Create the ${PROJECT_NAME}ConfigVersion.cmake file.
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # Install the package configuration files.
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
        COMPONENT ${COMPONENT__DEVELOPMENT}
    )
endfunction()


#[[
    get_library_type

    Defines cache variable LIB_<iLibName>_SHARED.
    Returns the type of a library (STATIC or SHARED) according to value of LIB_<iLibName>_SHARED or BUILD_SHARED_LIBS is the LIB_<iLibName>_SHARED is DEFAULT.
    If iLibName is shared, -DLIB_<iLibName>_SHARED define flag is added to compilation.
]]
function(get_library_type iLibName oLibType)
    string(TOUPPER "${iLibName}" _libNameUC)
    set(_cacheVarName "LIB_${_libNameUC}_SHARED")
    get_property(_cachedVarVal CACHE "${_cacheVarName}" PROPERTY VALUE)

    # Create a cache variable with string input.
    set("${_cacheVarName}" "DEFAULT" CACHE STRING "Build \"${iLibName}\" as a shared library. Can be ON, OFF, or DEFAULT.")

    # Restrict allowed values in GUIs like CMake GUI or ccmake.
    set_property(CACHE "${_cacheVarName}" PROPERTY STRINGS ON OFF DEFAULT)

    if("${_cachedVarVal}" STREQUAL "ON")
        set(_libType "SHARED")
    elseif("${_cachedVarVal}" STREQUAL "OFF")
        set(_libType "STATIC")
    else()
        if(BUILD_SHARED_LIBS)
            set(_libType "SHARED")
        else()
            set(_libType "STATIC")
        endif()
    endif()

    set(${oLibType} ${_libType} PARENT_SCOPE)
    if(${_libType} STREQUAL "SHARED")
        add_definitions(-D${_cacheVarName}) # Define preproceccor macro LIB_LIBNAME_SHARED.
    endif()
    CMagneto__message(STATUS "\"${iLibName}\" library will be built as ${_libType}.")
endfunction()


#[[
    __is_file_within_dir

    Checks, if iAbsoluteFilePath is in iAbsoluteDirPath or its subdirectory (recursively).
]]
function(__is_file_in_dir iAbsoluteFilePath iAbsoluteDirPath oFileIsInDir)
    get_filename_component(_normalizedFilePath "${iAbsoluteFilePath}" REALPATH)
    get_filename_component(_normalizedDirPath "${iAbsoluteDirPath}" REALPATH)

    # Ensure dir ends with a slash to avoid erroneous matches.
    if(NOT _normalizedDirPath MATCHES "/$")
        set(_normalizedDirPath "${_normalizedDirPath}/")
    endif()

    string(FIND "${_normalizedFilePath}" "${_normalizedDirPath}" _pos)

    # Check if the path starts with the dir (with trailing slash).
    if(_pos EQUAL 0)
        set(${oFileIsInDir} TRUE PARENT_SCOPE)
    else()
        set(${oFileIsInDir} FALSE PARENT_SCOPE)
    endif()
endfunction()


#[[
    __get_paths_relative_to_target_root

    Fails, if any path in iFilePaths is not under ${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}/ or ${CMAKE_BINARY_DIR}/.
    Parameters:
        - IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT: {IGNORE, WARN, FAIL}, default is IGNORE.
          If not IGNORE, and a path is not under ${CMAKE_BINARY_DIR}/, checks if the path is under iTargetAbsoluteRoot.
        - ALLOW_FILES_UNDER_BUILD_DIR: flag. If defined, files under ${CMAKE_BINARY_DIR}/ are also allowed.
]]
function(__get_paths_relative_to_target_root iTargetAbsoluteRoot iFilePaths oRelFilePaths)
    cmake_parse_arguments(ARG
        "ALLOW_FILES_UNDER_BUILD_DIR"  # Options (boolean flags).
        "IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT" # Single-value keywords (strings).
        "" # Multi-value keywords (lists).
        ${ARGN}
    )
    set(_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT__ALLOWED_VALUES IGNORE WARN FAIL)
    set(_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT__DEFAULT_VALUE IGNORE)

    # Handle named arguments.
    ## Set default values to named parameters if not specified.
    if(NOT ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT)
        set(ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT ${_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT__DEFAULT_VALUE})
    endif()

    ## Validate named arguments.
    if(NOT ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT IN_LIST _IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT__ALLOWED_VALUES)
        CMagneto__wrap_strings_in_quotes_and_join(_allowedValsStr ", " "${_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT__ALLOWED_VALUES}")
        set(_msgTemplate [=[
__get_paths_relative_to_target_root: invalid value "${ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT}" of parameter IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT.
                                     Allowed values: ${_allowedValsStr}.
        ]=])
        string(CONFIGURE "${_msgTemplate}" _msg)
        CMagneto__message(FATAL_ERROR "${_msg}")
    endif()


    # Handle iFilePaths.
    set(_relFilePaths "")
    set(_filePathsOutsideSourceDir "")
    set(_filePathsOutsideTargetRoot "")

    foreach(_filePath IN LISTS iFilePaths)
        CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Handling of a file \"${_filePath}\" started.")

        if(NOT IS_ABSOLUTE "${_filePath}")
            CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Passed file path is relative.")
            set(_absFilePath "${iTargetAbsoluteRoot}/${_filePath}")
            set(_relFilePath "${_filePath}")
        else()
            CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Passed file path is absolute.")
            set(_absFilePath "${_filePath}")
            file(RELATIVE_PATH _relFilePath "${iTargetAbsoluteRoot}" "${_absFilePath}")
        endif()

        CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Absolute file path: \"${_absFilePath}\"")
        CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Relative file path: \"${_relFilePath}\"")

        # Check if file is under build dir.
        if(ARG_ALLOW_FILES_UNDER_BUILD_DIR AND _absFilePath MATCHES "^${CMAKE_BINARY_DIR}/")
            list(APPEND _relFilePaths "${_relFilePath}")
            CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Handling of a file \"${_filePath}\" finished.\n")
            continue()
        endif()

        # Check if the file is within this project source directory.
        set(_sourceDir "${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}/")
        __is_file_in_dir("${_absFilePath}" "${_sourceDir}" _fileIsInSourceDir)
        if(NOT _fileIsInSourceDir)
            list(APPEND _filePathsOutsideSourceDir "${_filePath}")
        endif()

        # Check if the file is within target root.
        if(NOT ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT STREQUAL "IGNORE")
            __is_file_in_dir("${_absFilePath}" "${iTargetAbsoluteRoot}" _fileIsInTargetRootDir)
            if(NOT _fileIsInTargetRootDir)
                list(APPEND _filePathsOutsideTargetRoot "${_filePath}")
            endif()
        endif()

        list(APPEND _relFilePaths "${_relFilePath}")

        CMagneto__message(TRACE "get_paths_relative_to_target_root(${iTargetAbsoluteRoot}): Handling of a file \"${_filePath}\" finished.\n")
    endforeach()

    list(LENGTH _filePathsOutsideSourceDir _filePathsOutsideSourceDirLength)
    if(NOT _filePathsOutsideSourceDirLength EQUAL 0)
        CMagneto__wrap_strings_and_join(_invalidPathsString "\t\"" "\"" "\n" "${_filePathsOutsideSourceDir}")
        set(_msgTemplate [=[
These paths are outside of the project "${PROJECT_NAME}" source root "${_sourceDir}":
${_invalidPathsString}.
        ]=])
        string(CONFIGURE "${_msgTemplate}" _msg)
        CMagneto__message(FATAL_ERROR "${_msg}")
    endif()

    list(LENGTH _filePathsOutsideTargetRoot _filePathsOutsideTargetRootLength)
    if(NOT _filePathsOutsideTargetRootLength EQUAL 0)
        CMagneto__wrap_strings_and_join(_invalidPathsString "\t\"" "\"" "\n" "${_filePathsOutsideTargetRoot}")
        set(_msgTemplate [=[
These paths are outside of the target root "${iTargetAbsoluteRoot}":
${_invalidPathsString}.
        ]=])
        string(CONFIGURE "${_msgTemplate}" _msg)

        if(ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT STREQUAL "WARN")
            CMagneto__message(WARNING "${_msg}")
        elseif(ARG_IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT STREQUAL "FAIL")
            CMagneto__message(FATAL_ERROR "${_msg}")
        endif()
    endif()

    set(${oRelFilePaths} "${_relFilePaths}" PARENT_SCOPE)
endfunction()


#[[
    set_up_library

    Sets up the build and installation process for the library target `${iLibName}`.
    This function also registers `${iLibName}` in the global property `REGISTERED_TARGETS`.

    It must be called:
    - After `${iLibName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iLibName}`.

    Parameters:
    iLibName           - The name of the library target to configure.

    Named arguments (passed via ARGN, all optional):
    PUBLIC_HEADERS     - List of public headers to be installed and made available to consumers.
    INTERFACE_HEADERS  - List of interface-only headers (used by consumers, but not compiled into the library).
    PRIVATE_HEADERS    - List of private headers used only for building the library, not exposed to consumers.
    SOURCES            - List of implementation source files for the library, including:
                            - Regular source files (e.g. .cpp, .cxx)
                            - MOC-generated sources from Qt (e.g. via `qt_wrap_cpp`)
                            - RCC-generated sources from Qt resources (via `qt_add_resources`)
    QT_TS_RESOURCES    - List of Qt translation source files (`.ts`) to be processed.
    OTHER_RESOURCES    - Other non-code resources (e.g. icons, JSON files) used in the library.

    Notes:
    - All files: headers, sources and resources - must reside inside the source root directory of the target or build directory,
      otherwise the configuration will fail. It is made to keep both source and install directories layout clean and relocatable.
]]
function(set_up_library iLibName)
    check_target_name_validity(${iLibName})
    add_library(${PROJECT_NAME}::${iLibName} ALIAS ${iLibName})

    cmake_parse_arguments(ARG "" "" "PUBLIC_HEADERS;INTERFACE_HEADERS;PRIVATE_HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" ${ARGN})

    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_PUBLIC_HEADERS}" _relPublicHeaders IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_PRIVATE_HEADERS}" _relPrivateHeaders IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_INTERFACE_HEADERS}" _relInterfaceHeaders IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_SOURCES}" _relSources IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL ALLOW_FILES_UNDER_BUILD_DIR)
    #__get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_QT_TS_RESOURCES}" _relQtTSResources)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${OTHER_RESOURCES}" _relOtherResources)

    # Add target sources.
    ## Add header sets.
    target_sources(${iLibName}
        PUBLIC
            FILE_SET public_headers TYPE HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES ${_relPublicHeaders}
    )

    target_sources(${iLibName}
        PRIVATE
            FILE_SET private_headers TYPE HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES ${_relPrivateHeaders}
    )

    target_sources(${iLibName}
        INTERFACE
            FILE_SET interface_headers TYPE HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES ${_relInterfaceHeaders}
    )

    ## Assign header set visibility.
    set_target_properties(${iLibName} PROPERTIES
        PUBLIC_HEADER_SET public_headers
        PRIVATE_HEADER_SET private_headers
        INTERFACE_HEADER_SET interface_headers
    )

    ## Add sources.
    #target_sources(${iLibName} PRIVATE $<BUILD_INTERFACE:${_relSources}>)
    target_sources(${iLibName} PRIVATE ${_relSources})
    ####################################################################

    target_include_directories(${iLibName}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}> # Set up compiler.
            $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}> # Set up *Config.cmake.
    )

    # Set up binary.
    compose_binary_OUTPUT_NAME(${iLibName} _binaryOutputName)
    set_target_properties(${iLibName}
        PROPERTIES
            EXPORT_NAME ${iLibName}
            OUTPUT_NAME ${_binaryOutputName}
            # CMAKE_VISIBILITY_INLINES_HIDDEN ON  # TODO Parameterize it.
            # POSITION_INDEPENDENT_CODE ON  # TODO Parameterize it.
    )

    # Install.
    ## _libRootDirRelativeToSourceDir helps tp keep install dir structure the same as source dir structure.
    file(RELATIVE_PATH _libRootDirRelativeToSourceDir "${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}" "${CMAKE_CURRENT_SOURCE_DIR}")
    ## Avoid destinations like "include/Enow/Contacts/Contacts/./FieldType.hpp".
    if (_libRootDirRelativeToSourceDir STREQUAL ".")
        set(_libRootDirRelativeToSourceDir "")
    endif()
    CMagneto__message(TRACE "set_up_library(${iLibName}): lib's root CMakeLists.txt directory relative to project source dir: \"${_libRootDirRelativeToSourceDir}\"")

    install(TARGETS ${iLibName}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE
            DESTINATION ${SUBDIR_STATIC}
            COMPONENT ${COMPONENT__DEVELOPMENT}
        LIBRARY
            DESTINATION ${SUBDIR_SHARED}
            COMPONENT ${COMPONENT__RUNTIME}
        RUNTIME
            DESTINATION ${SUBDIR_EXECUTABLE}
            COMPONENT ${COMPONENT__RUNTIME}
        FILE_SET public_headers
            DESTINATION "${SUBDIR_INCLUDE}/${_libRootDirRelativeToSourceDir}"
            COMPONENT ${COMPONENT__DEVELOPMENT}
        FILE_SET interface_headers
            DESTINATION "${SUBDIR_INCLUDE}/${_libRootDirRelativeToSourceDir}"
            COMPONENT ${COMPONENT__DEVELOPMENT}
        # INCLUDES
        #     DESTINATION ...
        #     ...
        # is redundant, because it is effectively set by:
        # target_include_directories(${iLibName}
        #     PUBLIC
        #         $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}>
        #         $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}>
        # )
        # above.
    )

    ## Install Qt TS resources.
    qt_install_ts_resources("${ARG_QT_TS_RESOURCES}"
        DESTINATION "${SUBDIR_RESOURCES}/translations/${_libRootDirRelativeToSourceDir}"
        ${COMPONENT__RUNTIME}
    )

    ## Install other resources.
    install(FILES ${_relOtherResources}
        DESTINATION "${SUBDIR_RESOURCES}/other/${_libRootDirRelativeToSourceDir}"
        COMPONENT ${COMPONENT__RUNTIME}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iLibName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    collect_paths_to_shared_libs(${iLibName})
endfunction()


#[[
    set_up_executable

    Sets up building and installation of a executable-target iExeName.
    Also registers iExeName in the global property REGISTERED_TARGETS.
    Must be called after linking libraries to iExeName.

    Parameters:
    iExeHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iExeSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(set_up_executable iExeName)
    check_target_name_validity(${iExeName})
    add_executable(${PROJECT_NAME}::${iExeName} ALIAS ${iExeName})

    cmake_parse_arguments(ARG "" "" "HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" ${ARGN})

    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_HEADERS}" _relHeaders IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_SOURCES}" _relSources IF_FILE_OUTSIDE_TARGET_SOURCE_ROOT FAIL ALLOW_FILES_UNDER_BUILD_DIR)
    #__get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_QT_TS_RESOURCES}" _relQtTSResources)
    __get_paths_relative_to_target_root("${CMAKE_CURRENT_SOURCE_DIR}" "${OTHER_RESOURCES}" _relOtherResources)

    # Add target sources.
    target_sources(${iExeName} PRIVATE ${_relSources} ${_relHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.
    ####################################################################

    target_include_directories(${iExeName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}>  # Set up compiler.
    )

    # Set up binary.
    compose_binary_OUTPUT_NAME(${iExeName} _binaryOutputName)
    set_target_properties(${iExeName}
        PROPERTIES
            EXPORT_NAME ${iExeName}
            OUTPUT_NAME ${_binaryOutputName}
    )

    # Install.
    ## _exeRootDirRelativeToSourceDir helps tp keep install dir structure the same as source dir structure.
    file(RELATIVE_PATH _exeRootDirRelativeToSourceDir "${CMAKE_SOURCE_DIR}/${SUBDIR_SOURCE}" "${CMAKE_CURRENT_SOURCE_DIR}")
    ## Avoid destinations like "include/Enow/Contacts/Contacts/./FieldType.hpp".
    if (_exeRootDirRelativeToSourceDir STREQUAL ".")
        set(_exeRootDirRelativeToSourceDir "")
    endif()
    CMagneto__message(TRACE "set_up_executable(${iExeName}): exe's root CMakeLists.txt directory relative to project source dir: \"${_exeRootDirRelativeToSourceDir}\"")

    install(TARGETS ${iExeName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${SUBDIR_EXECUTABLE}
        COMPONENT ${COMPONENT__RUNTIME}
    )

    ## Install Qt TS resources.
    qt_install_ts_resources("${ARG_QT_TS_RESOURCES}"
        DESTINATION "${SUBDIR_RESOURCES}/translations/${_exeRootDirRelativeToSourceDir}"
        ${COMPONENT__RUNTIME}
    )

    ## Install other resources.
    install(FILES ${_relOtherResources}
        DESTINATION "${SUBDIR_RESOURCES}/other/${_exeRootDirRelativeToSourceDir}"
        COMPONENT ${COMPONENT__RUNTIME}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iExeName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    collect_paths_to_shared_libs(${iExeName})
endfunction()


#[[
    set_project_entrypoint

    Sets the project entry point executable.

    The entry point is run by "run" script, which is set up by set_up__run__script().
    The entry point executable is run when the project is started in Visual Studio.

    Parameters:
    iExeName - the name of the executable that is the project entry point.
]]
function(set_project_entrypoint iExeName)
    get_property(_isSet GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(_isSet)
        get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
        if(NOT (_exeName STREQUAL iExeName))
            CMagneto__message(FATAL_ERROR "set_project_entrypoint: The project entry point executable is already set to \"${_exeName}\".")
        endif()
    endif()

    get_target_property(_targetType ${iExeName} TYPE)
    if(NOT (${_targetType} STREQUAL "EXECUTABLE"))
        CMagneto__message(FATAL_ERROR "set_project_entrypoint: The target type must be EXECUTABLE.")
    endif()

    set_property(GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE ${iExeName})

    # Make ${iExeName} the startup project in Visual Studio.
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${iExeName})
endfunction()


#[[
    set_up_file

    Places to build directory and installs to ${SUBDIR_EXECUTABLE} a file with name and content,
    which are returned by fileNameGetter(oFileName) and contentGetter(iConfig oContent) functions.
    If a generator supports multi-config, temporary files are generated for every configuration (Debug, Release, etc.) during
    configure/generation time and copied to ${SUBDIR_EXECUTABLE} during build of corresponding $<CONFIG>.
    oFileName - is also a name of an utility target (created within the function) that depends on the output file, if multi-config generator is used.
    It must not contain characters that are not allowed in target names; dots are replaced with underscores.

    parameters:
        iAddExePermission - if TRUE, the file is given execute permission (Unix only).
        iInstall - if TRUE, the file is installed to ${SUBDIR_EXECUTABLE}.
        iComponentName - name of the component to which the file is installed.
            If iInstall is FALSE, this parameter is ignored.
]]
function(set_up_file iFileNameGetterName iContentGetterName iAddExePermission iInstall iComponentName)
    is_multiconfig(IS_MULTICONFIG)
    set(_TMP_FILE_DIR "${CMAKE_BINARY_DIR}/${SUBDIR_TMP}")
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
        set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${_fileName}")
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
        set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${_fileName}")

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
                    DESTINATION "${SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        else()
            if(UNIX AND iAddExePermission)
                install(
                    FILES "${_filePath}"
                    DESTINATION "${SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        endif()
    endif()
endfunction()


set(3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")
function(get__3rd_party_shared_libs__file_name oFileName)
    set(${oFileName} "${3RD_PARTY_SHARED_LIBS__LIST_NAME}" PARENT_SCOPE)
endfunction()


#[[
    generate_3rd_party_shared_libs__content

    Returns content of the "3rd_party_shared_libs.json" file.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__3rd_party_shared_libs__content iBuildType oContent)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(LENGTH _registeredTargets _registeredTargetsLength)

    set(_fileContent "{\n")
    set(_targetIdx 0)
    foreach(_target ${_registeredTargets})
        set(_fileContent "${_fileContent}\t\"${_target}\": [")

        get_paths_to_shared_libs(${_target} "${iBuildType}" _libPaths)
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
    set_up__3rd_party_shared_libs__list

    Generates, places to build directory and installs "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file may be used to make distributable packages.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__3rd_party_shared_libs__list)
    set_up_file("get__3rd_party_shared_libs__file_name" "generate__3rd_party_shared_libs__content" FALSE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(SCRIPT_EXTENSION_UNIX "sh")
set(SCRIPT_EXTENSION_WINDOWS "bat")

set(SCRIPT_NAME_SUFFIX_UNIX "_Unix")
# The differentiation is required, because Unix_standard scripts can't be run on Unix or don't do what they are intented for.
# E.g. Android is also Unix, but not Unix-standard: some variables and functions are not available or restricted.
set(SCRIPT_NAME_SUFFIX_UNIX_STANDARD "_Unix_standard")
set(SCRIPT_NAME_SUFFIX_WINDOWS "_Windows")

set(ENV_VSCODE__SCRIPT_NAME ".env.vscode")

set(SET_ENV__SCRIPT_NAME_WE "set_env")
set(SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/CMagneto/${SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")

set(RUN__SCRIPT_NAME_WE "run")
set(RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/CMagneto/${RUN__SCRIPT_NAME_WE}__TEMPLATE")


function(get__set_env__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    generate__set_env__script_content

    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__set_env__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    set(_libraryDirs "")
    get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX_STANDARD}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__set_env__script

    Generates, places to build directory and installs "set_env" script.
    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__set_env__script)
    set_up_file("get__set_env__script_file_name" "generate__set_env__script_content" TRUE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


function(get__env_vscode__file_name oFileName)
    set(${oFileName} "${ENV_VSCODE__SCRIPT_NAME}" PARENT_SCOPE)
endfunction()


#[[
    generate__env_vscode__file_content

    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__env_vscode__file_content iBuildType oFileContent)# Strings to replace in the template script.
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    set(_libraryDirs "")
    get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_fileContent "Path=\"${_libraryDirsNative}\"")
    else()
        set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
    endif()

    set(${oFileContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__env_vscode__file

    Generates and places to build directory ".env.vscode" file.
    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__env_vscode__file)
    set_up_file("get__env_vscode__file_name" "generate__env_vscode__file_content" FALSE FALSE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


function(get__run__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    generate__run__script_content

    If a project entrypoint executable is set (look at set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after set_up__set_env__script() is called.
]]
function(generate__run__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(EXECUTABLE_NAME_WE "param\\nEXECUTABLE_NAME_WE\\nparam")
    ####################################################################

    get_property(_is_PROJECT_ENTRYPOINT_EXE_set GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(NOT (_is_PROJECT_ENTRYPOINT_EXE_set))
        CMagneto_warning("generate__run__script_content: The project entrypoint executable is not set.")
        return()
    endif()
    get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
    compose_binary_OUTPUT_NAME(${_exeName} _exeName)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__run__script

    Generates, places to build directory and installs "run" script.
    If a project entrypoint executable is set (look at set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after set_up__set_env__script() is called.
]]
function(set_up__run__script)
    set_up_file("get__run__script_file_name" "generate__run__script_content" TRUE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


set(TEST_BUILD_SUMMARY__FILE_NAME "test_build_summary.txt")
set(RUN_TESTS__SCRIPT_NAME_WE "run_tests")
set(RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/CMagneto/${RUN_TESTS__SCRIPT_NAME_WE}__TEMPLATE")
set(TEST_REPORT__FILE_NAME "test_report.xml")


#[[
    generate__run_tests__script_content

    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after set_up__set_env__script() is called.
]]
function(generate__run_tests__script_content iBuildType oScriptContent)
# Strings to replace in the template script.
    set(DIR_WITH_CTESTTESTFILE "param\\nDIR_WITH_CTESTTESTFILE\\nparam")
    set(BUILD_CONFIG "param\\nBUILD_CONFIG\\nparam")
    set(REPORT_PATH "param\\nREPORT_PATH\\nparam")
    ####################################################################

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_dirWithCtestTestFile "../../${SUBDIR_CTESTTESTFILE}")
        set(_reportPath "../../${SUBDIR_SUMMARY}/${iBuildType}/${TEST_REPORT__FILE_NAME}")
    else()
        set(_dirWithCtestTestFile "../${SUBDIR_CTESTTESTFILE}")
        set(_reportPath "../${SUBDIR_SUMMARY}/${TEST_REPORT__FILE_NAME}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${DIR_WITH_CTESTTESTFILE}" "${_dirWithCtestTestFile}" _scriptContent "${_scriptContent}")
    string(REPLACE "${BUILD_CONFIG}" "${iBuildType}" _scriptContent "${_scriptContent}")
    string(REPLACE "${REPORT_PATH}" "${_reportPath}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


function(get__run_tests__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${RUN_TESTS__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${RUN_TESTS__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    set_up__run_tests__script

    Generates, places to build directory and installs "run_tests" script.
    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after set_up__set_env__script() is called.
    If the function is not called, "build.py" will not be able to run tests: "build.py" calls "run_tests" scripts.
]]
function(set_up__run_tests__script)
    set_up_file("get__run_tests__script_file_name" "generate__run_tests__script_content" TRUE FALSE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    set_test_discovery

    Sets test discovery after build time and just before execution of test bodies.

    The function must be called after include(GoogleTest).
    If the function is not called, test discovery may be started during build time,
    and if paths to 3rd-party shared libraries are not set, build will fail.
]]
function(set_test_discovery iTestTargetName)
    # Triggers test discovery: runs the test executable with the --gtest_list_tests argument after build time just before execution of test bodies.
    # Creates a list of all test suites and test names (without executing their bodies).
    # Parses the list of tests, and adds each one to ctest.
    gtest_discover_tests(${iTestTargetName}
        DISCOVERY_MODE PRE_TEST # Not using of DISCOVERY_MODE POST_BUILD allows to not add ENVIRONMENT argument which is $<CONFIG>-dependent.
    )
endfunction()


set(GENERATE_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/CMagneto/generate_build_summary.cmake")
set(BUILD_SUMMARY__FILE_NAME "build_summary.txt")


#[[
    set_up__build_summary__file

    After all registered targets are built, the function composes, places to build directory and installs "build_summary.txt".

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
    If the function is not called, "build.py" will not work correctly:
    "build.py" checks for the presence of "build_summary.txt" to determine whether the project is compiled.
]]
function(set_up__build_summary__file)
    set(_summaryOutputDir "${CMAKE_BINARY_DIR}/${SUBDIR_SUMMARY}")

    is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_summaryOutputPath "${_summaryOutputDir}/$<CONFIG>/${BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_summaryOutputPath "${_summaryOutputDir}/${BUILD_SUMMARY__FILE_NAME}")
        set(_buildType "${CMAKE_BUILD_TYPE}")
    endif()

    add_custom_target(build_summary ALL)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    if(_registeredTargets)
        add_dependencies(build_summary ${_registeredTargets})
    endif()

    # The file is used by "build.py" to determine whether the project is compiled.
    add_custom_command(
        TARGET build_summary POST_BUILD
        COMMENT "Composing ${BUILD_SUMMARY__FILE_NAME}"
        COMMAND ${CMAKE_COMMAND}
            -DOUT="${_summaryOutputPath}"
            -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
            -DCMAKE_SYSTEM_VERSION="${CMAKE_SYSTEM_VERSION}"
            -DCMAKE_GENERATOR="${CMAKE_GENERATOR}"
            -DCMAKE_CXX_COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
            -DCMAKE_CXX_COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
            -DCMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER}"
            -DCMAKE_BUILD_TYPE="${_buildType}"
            -P "${GENERATE_BUILD_SUMMARY__SCRIPT_PATH}"
    )

    # Install the file.
    install(FILES "${_summaryOutputPath}"
        DESTINATION "${SUBDIR_SUMMARY}"
        COMPONENT ${COMPONENT__BUILD_MACHINE_SPECIFIC}
    )
endfunction()


# Appended every time register_test_target(iTestTargetName) is called.
set_property(GLOBAL PROPERTY REGISTERED_TEST_TARGETS "")


function(register_test_target iTestTargetName)
    get_property(_registeredTestTargets GLOBAL PROPERTY REGISTERED_TEST_TARGETS)
    list(APPEND _registeredTestTargets ${iTestTargetName})
    set_property(GLOBAL PROPERTY REGISTERED_TEST_TARGETS "${_registeredTestTargets}")

    # Set test discovery for the test target.
    set_test_discovery(${iTestTargetName})
endfunction()


set(GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/CMagneto/generate_build_tests_summary.cmake")


#[[
    add__build_tests__target

    Creates "build_tests" target that depends on all registered test targets.
    Allows to build all tests with a single command, e.g.: "cmake --build . --target build_tests".
]]
function(add__build_tests__target)
    get_property(_registeredTestTargets GLOBAL PROPERTY REGISTERED_TEST_TARGETS)
    if(NOT DEFINED _registeredTestTargets OR _registeredTestTargets STREQUAL "")
        CMagneto__message(STATUS "add__build_tests__target: No registered test targets.")
    endif()

    set(_fileDir "${CMAKE_BINARY_DIR}/${SUBDIR_SUMMARY}")

    is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_filePath "${_fileDir}/$<CONFIG>/${TEST_BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_filePath "${_fileDir}/${TEST_BUILD_SUMMARY__FILE_NAME}")
    endif()

    # Add a target that depends on all registered test targets.
    add_custom_target(build_tests
        DEPENDS ${_registeredTestTargets}
        COMMENT "Compiling tests."
    )

    # The file is used by "build.py" to determine whether tests are compiled.
    add_custom_command(
        TARGET build_tests POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            -DFILE_PATH="${_filePath}"
            -DTEST_TARGETS="${_registeredTestTargets}"
            -P "${GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH}"
        COMMENT "Composing ${TEST_BUILD_SUMMARY__FILE_NAME}"
    )
endfunction()
