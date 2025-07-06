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
        0) Include ./ParseMeta.cmake before "project()" command. Add the "project()" command:
            ```cmake
            include("${CMAKE_SOURCE_DIR}/cmake/modules/CMagneto/ParseMeta.cmake")
            project("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}"
                DESCRIPTION "${CMagneto__PROJECT_JSON__PROJECT_DESCRIPTION}"
                HOMEPAGE_URL "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}"
                VERSION "${CMagneto__PROJECT_JSON__PROJECT_VERSION}"
                LANGUAGES CXX
            )
            ```

        1) Include this file in root CMakeLists.txt, e.g.:
           `include(${CMAKE_CURRENT_LIST_DIR}/CMagneto.cmake)`

        2) Call `CMagneto__set_up__library()` or `CMagneto__set_up__executable()` to set up project targets.

        3) Call `CMagneto__set_up__project()` to generate build stage reports, helper scripts, etc.
           The function should be called after all targets are set up.

        4) Call `CMagneto__add__build_tests__target()` to set up the tests target.
           The function should be called after all targets with tests are added.
]]


# Add CMagneto CMake module private vars and functions.
include("${CMAKE_CURRENT_LIST_DIR}/CMagneto/Internals.cmake")


CMagnetoInternal__set__IS_MULTTCONFIG__property()


function(CMagneto__print_platform_and_compiler)
    CMagnetoInternal__message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
    CMagnetoInternal__message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    CMagnetoInternal__message(STATUS "Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
    CMagnetoInternal__message(STATUS "Compiler Path: ${CMAKE_CXX_COMPILER}")
endfunction()


function(CMagneto__set_up__project)
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
    CMagneto__get_library_type

    Defines cache variable LIB_<iLibName>_SHARED.
    Returns the type of a library (STATIC or SHARED) according to value of LIB_<iLibName>_SHARED or BUILD_SHARED_LIBS is the LIB_<iLibName>_SHARED is DEFAULT.
    If iLibName is shared, -DLIB_<iLibName>_SHARED define flag is added to compilation.
]]
function(CMagneto__get_library_type iLibName oLibType)
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
    CMagnetoInternal__message(STATUS "\"${iLibName}\" library will be built as ${_libType}.")
endfunction()


#[[
    CMagneto__set_up__library

    Sets up the build and installation process for the library target `${iLibName}`.
    This function also registers `${iLibName}` in the global property `CMagnetoInternal__REGISTERED_TARGETS`.

    It must be called:
    - Once for the library target.
    - After `${iLibName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iLibName}`. The root `CMakeLists.txt` must be in the source root of the lib.

    Parameters:
    iLibName           - The name of the library target to configure.

    Named arguments (all optional):
    PUBLIC_HEADERS     - List of public headers used for compiling the library and to be installed and made available to consumers.
    INTERFACE_HEADERS  - List of interface-only headers (used by consumers, but not compiled into the library).
    PRIVATE_HEADERS    - List of private headers used only for compiling the library, not exposed to consumers.
    SOURCES            - List of implementation source files for the library, including:
                            - Regular source files (e.g. .cpp, .cxx)
                            - MOC-generated sources from Qt (e.g. via `qt_wrap_cpp`)
    QT_TS_RESOURCES    - List of Qt translation source files (`.ts`) to be processed.
    OTHER_RESOURCES    - Other non-code resources (e.g. icons, JSON files) used in the library.

    Notes:
    - All paths: of headers, sources and resources - must be relative to the source root directory of the target (parent dir of the target's CMakeLists.txt).
      The paths must reside under the source root directory of the target.
      The paths must not contain backslashes.
      It is made to keep both source and install directories layout clean and relocatable.

      Source file paths are also allowed to reside under the build root directory of the target,
      and if they are under the dir, are allowed to be absolute and contain backslashes.
]]
function(CMagneto__set_up__library iLibName)
    CMagnetoInternal__check_target_name_validity(${iLibName})
    add_library(${PROJECT_NAME}::${iLibName} ALIAS ${iLibName})

    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "" # Single-value keywords (strings).
        "PUBLIC_HEADERS;INTERFACE_HEADERS;PRIVATE_HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" # Multi-value keywords (lists).
        ${ARGN}
    )

    set(_baseDirDescription "library target \"${iLibName}\"")
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_PUBLIC_HEADERS}" OUTPUT_REL_PATHS _relPublicHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_PRIVATE_HEADERS}" OUTPUT_REL_PATHS _relPrivateHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_INTERFACE_HEADERS}" OUTPUT_REL_PATHS _relInterfaceHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_SOURCES}" OUTPUT_REL_PATHS _relSources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
    #CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${OTHER_RESOURCES}" OUTPUT_REL_PATHS _relOtherResources)

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
    target_sources(${iLibName} PRIVATE $<BUILD_INTERFACE:${_relSources}>)
    #target_sources(${iLibName} PRIVATE ${_relSources})
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
    ## _libSourceRootRelativeToProjectSourceRoot helps to keep install dir structure the same as source dir structure.
    CMagnetoInternal__get_dir_relative_to_project_source_root("${CMAKE_CURRENT_SOURCE_DIR}" _libSourceRootRelativeToProjectSourceRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__library(${iLibName}): lib's root CMakeLists.txt directory relative to project source dir: \"${_libSourceRootRelativeToProjectSourceRoot}\"")

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
            DESTINATION "${SUBDIR_INCLUDE}/${_libSourceRootRelativeToProjectSourceRoot}"
            COMPONENT ${COMPONENT__DEVELOPMENT}
        FILE_SET interface_headers
            DESTINATION "${SUBDIR_INCLUDE}/${_libSourceRootRelativeToProjectSourceRoot}"
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
    ####################################################################

    # Set up Qt TS resources.
    CMagnetoInternal__set_up_QtTS_files(${iLibName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")

    # Set up other resources (not Qt RCC embedded, not Qt TS).
    # TODO
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iLibName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS "${_registeredTargets}")

    CMagnetoInternal__collect_paths_to_shared_libs(${iLibName})
endfunction()


#[[
    CMagneto__set_up__executable

    Sets up the build and installation process for the executable target `${iExeName}`.
    This function also registers `${iExeName}` in the global property `CMagnetoInternal__REGISTERED_TARGETS`.

    It must be called:
    - Once for the executable target.
    - After `${iExeName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iExeName}`. The root `CMakeLists.txt` must be in the source root of the executable.

    Parameters:
    iExeName           - The name of the executable target to configure.

    Named arguments (all optional):
    HEADERS         - List of public headers used for compiling the executable.
    SOURCES         - List of implementation source files for the executable, including:
                            - Regular source files (e.g. .cpp, .cxx)
                            - MOC-generated sources from Qt (e.g. via `qt_wrap_cpp`)
    QT_TS_RESOURCES - List of Qt translation source files (`.ts`) to be processed.
    OTHER_RESOURCES - Other non-code resources (e.g. icons, JSON files) used in the executable.

    Notes:
    - All paths: of headers, sources and resources - must be relative to the source root directory of the target (parent dir of the target's CMakeLists.txt).
      The paths must reside under the source root directory of the target.
      The paths must not contain backslashes.
      It is made to keep both source and install directories layout clean and relocatable.

      Source file paths are also allowed to reside under the build root directory of the target,
      and if they are under the dir, are allowed to be absolute and contain backslashes.
]]
function(CMagneto__set_up__executable iExeName)
    CMagnetoInternal__check_target_name_validity(${iExeName})
    add_executable(${PROJECT_NAME}::${iExeName} ALIAS ${iExeName})

    cmake_parse_arguments(ARG "" "" "HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" ${ARGN})

    set(_baseDirDescription "executable target \"${iExeName}\"")
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_HEADERS}" OUTPUT_REL_PATHS _relHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_SOURCES}" OUTPUT_REL_PATHS _relSources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
    #CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${OTHER_RESOURCES}" OUTPUT_REL_PATHS _relOtherResources)

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
    ## _exeSourceRootRelativeToProjectSourceRoot helps to keep install dir structure the same as source dir structure.
    CMagnetoInternal__get_dir_relative_to_project_source_root("${CMAKE_CURRENT_SOURCE_DIR}" _exeSourceRootRelativeToProjectSourceRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__executable(${iExeName}): exe's root CMakeLists.txt directory relative to project source dir: \"${_exeSourceRootRelativeToProjectSourceRoot}\"")

    install(TARGETS ${iExeName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${SUBDIR_EXECUTABLE}
        COMPONENT ${COMPONENT__RUNTIME}
    )
    ####################################################################

    # Set up Qt TS resources.
    CMagnetoInternal__set_up_QtTS_files(${iExeName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")

    # Set up other resources (not Qt RCC embedded, not Qt TS).
    # TODO
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iExeName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS "${_registeredTargets}")

    CMagnetoInternal__collect_paths_to_shared_libs(${iExeName})
endfunction()


#[[
    CMagneto__set_project_entrypoint

    Sets the project entry point executable.

    The entry point is run by "run" script, which is set up by CMagneto__set_up__run__script().
    The entry point executable is run when the project is started in Visual Studio.

    Parameters:
    iExeName - the name of the executable that is the project entry point.
]]
function(CMagneto__set_project_entrypoint iExeName)
    get_property(_isSet GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(_isSet)
        get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
        if(NOT (_exeName STREQUAL iExeName))
            CMagnetoInternal__message(FATAL_ERROR "CMagneto__set_project_entrypoint: The project entry point executable is already set to \"${_exeName}\".")
        endif()
    endif()

    get_target_property(_targetType ${iExeName} TYPE)
    if(NOT (${_targetType} STREQUAL "EXECUTABLE"))
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__set_project_entrypoint: The target type must be EXECUTABLE.")
    endif()

    set_property(GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE ${iExeName})
    CMagnetoInternal__message(STATUS "\"${iExeName}\" executable target is set as the \"${PROJECT_NAME}\" project entrypoint.")

    # Make ${iExeName} the startup project in Visual Studio.
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${iExeName})
endfunction()


#[[
    CMagneto__embed_QtRC_resources

    The function does the same as qt_add_resources, but the CMagneto__embed_QtRC_resources also
    - checks if all paths from the named arguments BIG_RESOURCES and FILES are under target QtRC directory;
    - composes resource name as `${iTargetName}__${iResourceNamePostfix}`;
    - if Qt creates auxilliary resource targets, the targets are exported (added to *Config.cmake).

    Notes:
    - All paths from the named arguments BIG_RESOURCES and FILES
      must be relative to the source root directory of the target (parent dir of the target's CMakeLists.txt).
      The paths must reside under the QtRC directory of the target.
      The paths must not contain backslashes.
      It is made to keep source directories layout clean and relocatable.

    - If iTargetName is a static library, don't forget to call `Q_INIT_RESOURCE(${iTargetName}__${iResourceNamePostfix});`
      from outside of any namespace before usage of the embedded resources.

    - Do not use the following scheme/pattern of embedding resources with Qt RCC:
      ```cmake
      qt_add_resources(_qrcSources "*.qrc")
      CMagneto__set_up__executable(${iTargetName}
          SOURCES
              ${_qrcSources}
      )
      ```
      Because Qt behaves strangely:
      this leads to creation of source files in the root build dir of iTargetName (which is fine),
      and then those files are added as source files at least to all dependency-lib-targets of the iTargetName.
]]
function(CMagneto__embed_QtRC_resources iTargetName iResourceNamePostfix)
    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "PREFIX;LANG;BASE;OUTPUT_TARGETS" # Single-value keywords (strings).
        "BIG_RESOURCES;FILES;OPTIONS" # Multi-value keywords (lists).
        ${ARGN}
    )

    if(iResourceNamePostfix STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__embed_QtRC_resources(\"${iTargetName}\" \"${iResourceNamePostfix}\"): iResourceNamePostfix is empty.")
    endif()

    # Fail, if resource files to embed are not under target QtRC-dedicated subdirectory.
    set(_QtRCSourceBaseDir "${CMAKE_CURRENT_SOURCE_DIR}/${SUBDIR_RESOURCES}/${SUBDIR_QTRC}/")
    set(_baseDirDescription "target \"${iTargetName}\" QtRC")
    CMagnetoInternal__handle_source_paths("${_QtRCSourceBaseDir}" "${_baseDirDescription}" "${ARG_BIG_RESOURCES}" IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${_QtRCSourceBaseDir}" "${_baseDirDescription}" "${ARG_FILES}" IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)

    qt_add_resources(${iTargetName} "${iTargetName}__${iResourceNamePostfix}"
        PREFIX "${ARG_PREFIX}"
        LANG "${ARG_LANG}"
        BASE "${ARG_BASE}"
        BIG_RESOURCES ${ARG_BIG_RESOURCES}
        OUTPUT_TARGETS _outputTargets
        FILES ${ARG_FILES}
        OPTIONS ${ARG_OPTIONS}
    )

    set(_resourceTargetNames "${_outputTargets}")
    if (NOT _resourceTargetNames STREQUAL "")
        CMagnetoInternal__message(STATUS "CMagneto__embed_QtRC_resources(\"${iTargetName}\" \"${iResourceNamePostfix}\"): Qt created resource targets: ${_resourceTargetNames}.")
        foreach(_resourceTargetName IN LISTS _resourceTargetNames)
            install(TARGETS ${_resourceTargetName}
                EXPORT ${PROJECT_NAME}Targets
                ARCHIVE
                    DESTINATION ${SUBDIR_STATIC}
                    COMPONENT ${COMPONENT__DEVELOPMENT}
                LIBRARY
                    DESTINATION ${SUBDIR_SHARED}
                    COMPONENT ${COMPONENT__RUNTIME}
            )
        endforeach()
    endif()
    set(${ARG_OUTPUT_TARGETS} "${_resourceTargetNames}" PARENT_SCOPE)
endfunction()


#[[
    CMagneto__set_up__3rd_party_shared_libs__list

    Generates, places to build directory and installs "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file may be used to make distributable packages.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagneto__set_up__3rd_party_shared_libs__list)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__3rd_party_shared_libs__file_name" "CMagnetoInternal__generate__3rd_party_shared_libs__content" FALSE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagneto__set_up__set_env__script

    Generates, places to build directory and installs "set_env" script.
    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagneto__set_up__set_env__script)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__set_env__script_file_name" "CMagnetoInternal__generate__set_env__script_content" TRUE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagneto__set_up__env_vscode__file

    Generates and places to build directory ".env.vscode" file.
    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
]]
function(CMagneto__set_up__env_vscode__file)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__env_vscode__file_name" "CMagnetoInternal__generate__env_vscode__file_content" FALSE FALSE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagneto__set_up__run__script

    Generates, places to build directory and installs "run" script.
    If a project entrypoint executable is set (look at CMagneto__set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after CMagneto__set_up__set_env__script() is called.
]]
function(CMagneto__set_up__run__script)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__run__script_file_name" "CMagnetoInternal__generate__run__script_content" TRUE TRUE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagneto__set_up__run_tests__script

    Generates, places to build directory and installs "run_tests" script.
    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after CMagneto__set_up__set_env__script() is called.
    If the function is not called, "build.py" will not be able to run tests: "build.py" calls "run_tests" scripts.
]]
function(CMagneto__set_up__run_tests__script)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__run_tests__script_file_name" "CMagnetoInternal__generate__run_tests__script_content" TRUE FALSE ${COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()


#[[
    CMagneto__set_up__build_summary__file

    After all registered targets are built, the function composes, places to build directory and installs "build_summary.txt".

    The function must be called after all CMagneto__set_up__library(iLibName) and CMagneto__set_up__executable(iExeName) are called.
    If the function is not called, "build.py" will not work correctly:
    "build.py" checks for the presence of "build_summary.txt" to determine whether the project is compiled.
]]
function(CMagneto__set_up__build_summary__file)
    set(_summaryOutputDir "${CMAKE_BINARY_DIR}/${SUBDIR_SUMMARY}")

    CMagnetoInternal__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_summaryOutputPath "${_summaryOutputDir}/$<CONFIG>/${CMagnetoInternal__BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_summaryOutputPath "${_summaryOutputDir}/${CMagnetoInternal__BUILD_SUMMARY__FILE_NAME}")
        set(_buildType "${CMAKE_BUILD_TYPE}")
    endif()

    add_custom_target(build_summary ALL)
    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TARGETS)
    if(_registeredTargets)
        add_dependencies(build_summary ${_registeredTargets})
    endif()

    # The file is used by "build.py" to determine whether the project is compiled.
    add_custom_command(
        TARGET build_summary POST_BUILD
        COMMENT "Composing ${CMagnetoInternal__BUILD_SUMMARY__FILE_NAME}"
        COMMAND ${CMAKE_COMMAND}
            -DOUT="${_summaryOutputPath}"
            -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
            -DCMAKE_SYSTEM_VERSION="${CMAKE_SYSTEM_VERSION}"
            -DCMAKE_GENERATOR="${CMAKE_GENERATOR}"
            -DCMAKE_CXX_COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
            -DCMAKE_CXX_COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
            -DCMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER}"
            -DCMAKE_BUILD_TYPE="${_buildType}"
            -P "${CMagnetoInternal__GENERATE_BUILD_SUMMARY__SCRIPT_PATH}"
    )

    # Install the file.
    install(FILES "${_summaryOutputPath}"
        DESTINATION "${SUBDIR_SUMMARY}"
        COMPONENT ${COMPONENT__BUILD_MACHINE_SPECIFIC}
    )
endfunction()


function(CMagneto__register_test_target iTestTargetName)
    get_property(_registeredTestTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS)
    list(APPEND _registeredTestTargets ${iTestTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS "${_registeredTestTargets}")

    # Set test discovery for the test target.
    CMagnetoInternal__set_test_discovery(${iTestTargetName})
endfunction()


#[[
    CMagneto__add__build_tests__target

    Creates "build_tests" target that depends on all registered test targets.
    Allows to build all tests with a single command, e.g.: "cmake --build . --target build_tests".
]]
function(CMagneto__add__build_tests__target)
    get_property(_registeredTestTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS)
    if(NOT DEFINED _registeredTestTargets OR _registeredTestTargets STREQUAL "")
        CMagnetoInternal__message(STATUS "CMagneto__add__build_tests__target: No registered test targets.")
    endif()

    set(_fileDir "${CMAKE_BINARY_DIR}/${SUBDIR_SUMMARY}")

    CMagnetoInternal__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_filePath "${_fileDir}/$<CONFIG>/${CMagnetoInternal__TEST_BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_filePath "${_fileDir}/${CMagnetoInternal__TEST_BUILD_SUMMARY__FILE_NAME}")
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
            -P "${CMagnetoInternal__GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH}"
        COMMENT "Composing ${CMagnetoInternal__TEST_BUILD_SUMMARY__FILE_NAME}"
    )
endfunction()
