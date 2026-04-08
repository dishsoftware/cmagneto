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
    This submodule of the CMagneto module defines functions and variables for setting up static/shared library targets.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpLibTarget_Internals.cmake")


#[[
    CMagneto__get_library_type

    Defines cache variable LIB_<iLibTargetName>_SHARED.
    Returns the type of a library (STATIC or SHARED) according to value of LIB_<iLibTargetName>_SHARED or BUILD_SHARED_LIBS is the LIB_<iLibTargetName>_SHARED is DEFAULT.
    If iLibTargetName is shared, -DLIB_<iLibTargetName>_SHARED define flag is added to compilation.
]]
function(CMagneto__get_library_type iLibTargetName oLibType)
    string(TOUPPER "${iLibTargetName}" _libTargetNameUC)
    set(_cacheVarName "LIB_${_libTargetNameUC}_SHARED")
    get_property(_cachedVarVal CACHE "${_cacheVarName}" PROPERTY VALUE)

    # Create a cache variable with string input.
    set("${_cacheVarName}" "DEFAULT" CACHE STRING "Build \"${iLibTargetName}\" as a shared library. Can be ON, OFF, or DEFAULT.")

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
        add_definitions(-D${_cacheVarName}) # Define preproceccor macro LIB_LIBTARGETNAME_SHARED.
    endif()
    CMagnetoInternal__message(STATUS "\"${iLibTargetName}\" library will be built as ${_libType}.")
endfunction()


#[[
    CMagneto__set_up__interface_library

    Sets up the build and installation process for the interface library target `${iLibTargetName}`.
    This function also registers `${iLibTargetName}` in the global property `CMagnetoInternal__RegisteredTargets`.

    It must be called:
    - Once for the interface library target.
    - After `${iLibTargetName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iLibTargetName}`. The root `CMakeLists.txt` must be in the source root of the lib.

    Parameters:
    iLibTargetName           - The name of the interface library target to configure.

    Named arguments (all optional):
    INTERFACE_HEADERS  - List of interface headers made available to consumers.
    QT_TS_RESOURCES    - List of Qt translation source files (`.ts`) to be processed.
    OTHER_RESOURCES    - Other non-code resources (e.g. icons, JSON files) associated with the interface library.

    Notes:
    - INTERFACE_HEADERS paths must be relative to the mirrored public include root of the target,
      obtained from the target source root by replacing `${CMagneto__SUBDIR_SOURCES_SRC}` with `${CMagneto__SUBDIR_SOURCES_INCLUDE}`.
    - OTHER_RESOURCES paths must be relative to the mirrored resource root of the target,
      obtained from the target source root by replacing `${CMagneto__SUBDIR_SOURCES_SRC}` with `${CMagneto__SUBDIR_SOURCES_RESOURCES}`.
    - All paths must not contain backslashes.
]]
function(CMagneto__set_up__interface_library iLibTargetName)
    CMagnetoInternal__check_target_name_validity(${iLibTargetName})
    get_target_property(_targetType ${iLibTargetName} TYPE)
    if(NOT _targetType STREQUAL "INTERFACE_LIBRARY")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__set_up__interface_library(${iLibTargetName}): target type must be INTERFACE_LIBRARY, got \"${_targetType}\".")
    endif()

    CMagnetoInternal__compose_namespaced_target_name("${iLibTargetName}" _namespacedTargetName)
    add_library(${_namespacedTargetName} ALIAS ${iLibTargetName})

    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "" # Single-value keywords (strings).
        "INTERFACE_HEADERS;QT_TS_RESOURCES;OTHER_RESOURCES" # Multi-value keywords (lists).
        ${ARGN}
    )

    CMagnetoInternal__get_target_include_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetIncludeRoot)
    CMagnetoInternal__get_target_resource_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetResourceRoot)

    set(_baseDirDescription "interface library target \"${iLibTargetName}\"")
    CMagnetoInternal__handle_source_paths("${_targetIncludeRoot}/" "${_baseDirDescription}" "${ARG_INTERFACE_HEADERS}" OUTPUT_ABS_PATHS _absInterfaceHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_OTHER_RESOURCES}" OUTPUT_ABS_PATHS _absOtherResources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)

    target_sources(${iLibTargetName}
        INTERFACE
            FILE_SET interface_headers TYPE HEADERS
            BASE_DIRS "${_targetIncludeRoot}"
            FILES ${_absInterfaceHeaders}
    )

    set_target_properties(${iLibTargetName} PROPERTIES
        INTERFACE_HEADER_SET interface_headers
        EXPORT_NAME ${_namespacedTargetName}
    )

    target_sources(${iLibTargetName} INTERFACE ${_absOtherResources}) # Added to surface the files in IDEs and exports.

    target_include_directories(${iLibTargetName}
        INTERFACE
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_INCLUDE}>
            $<INSTALL_INTERFACE:${CMagneto__SUBDIR_INCLUDE}>
    )
    CMagnetoInternal__set_up_project_build_info_for_target(${iLibTargetName} INTERFACE)

    CMagneto__get_dir_relative_to_project_sources_src_root("${CMAKE_CURRENT_SOURCE_DIR}" _libSourceRootRelativeToProjectSourcesSrcRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__interface_library(${iLibTargetName}): lib's root CMakeLists.txt directory relative to project source dir: \"${_libSourceRootRelativeToProjectSourcesSrcRoot}\"")

    install(TARGETS ${iLibTargetName}
        EXPORT ${PROJECT_NAME}Targets
        FILE_SET interface_headers
            DESTINATION "${CMagneto__SUBDIR_INCLUDE}/${_libSourceRootRelativeToProjectSourcesSrcRoot}"
            COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
    )

    CMagnetoInternal__set_up_QtTS_files(${iLibTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")
    CMagnetoInternal__set_up_other_resource_files(${iLibTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_OTHER_RESOURCES}")

    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    list(APPEND _registeredTargets ${iLibTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets "${_registeredTargets}")

    CMagnetoInternal__register_linked_imported_shared_library_targets(${iLibTargetName})
endfunction()


#[[
    CMagneto__set_up__library

    Sets up the build and installation process for the STATIC/SHARED library target `${iLibTargetName}`.
    This function also registers `${iLibTargetName}` in the global property `CMagnetoInternal__RegisteredTargets`.

    It must be called:
    - Once for the library target.
    - After `${iLibTargetName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iLibTargetName}`. The root `CMakeLists.txt` must be in the source root of the lib.

    Parameters:
    iLibTargetName           - The name of the library target to configure.

    Named arguments (all optional):
    GENERATED_HEADERS_VISIBILITY - `PUBLIC` to place generated `<TargetLeafName>_EXPORT.hpp` and `<TargetLeafName>_DEFS.hpp`
                                   under the mirrored include root and expose them as public headers;
                                   `PRIVATE` to place them under the target source root and treat them as private headers.
    PUBLIC_HEADERS     - List of public headers used for compiling the library and to be installed and made available to consumers.
    INTERFACE_HEADERS  - List of interface-only headers (used by consumers, but not compiled into the library).
    PRIVATE_HEADERS    - List of private headers used only for compiling the library, not exposed to consumers.
    SOURCES            - List of implementation source files for the library, including:
                            - Regular source files (e.g. .cpp, .cxx)
                            - MOC-generated sources from Qt (e.g. via `qt_wrap_cpp`)
    QT_TS_RESOURCES    - List of Qt translation source files (`.ts`) to be processed.
    OTHER_RESOURCES    - Other non-code resources (e.g. icons, JSON files) used in the library.

    Notes:
    - PRIVATE_HEADERS and SOURCES paths must be relative to the source root directory of the target
      (parent dir of the target's CMakeLists.txt) and must reside under that source root directory.
    - PUBLIC_HEADERS and INTERFACE_HEADERS paths must be relative to the mirrored public include root of the target,
      obtained from the target source root by replacing `${CMagneto__SUBDIR_SOURCES_SRC}` with `${CMagneto__SUBDIR_SOURCES_INCLUDE}`.
    - OTHER_RESOURCES paths must be relative to the mirrored resource root of the target,
      obtained from the target source root by replacing `${CMagneto__SUBDIR_SOURCES_SRC}` with `${CMagneto__SUBDIR_SOURCES_RESOURCES}`.
    - All paths must not contain backslashes.
    - Source file paths are also allowed to reside under the build root directory of the target,
      and if they are under the dir, are allowed to be absolute and contain backslashes.
]]
function(CMagneto__set_up__library iLibTargetName)
    CMagnetoInternal__check_target_name_validity(${iLibTargetName})
    CMagnetoInternal__compose_namespaced_target_name("${iLibTargetName}" _namespacedTargetName)
    add_library(${_namespacedTargetName} ALIAS ${iLibTargetName})

    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "GENERATED_HEADERS_VISIBILITY" # Single-value keywords (strings).
        "PUBLIC_HEADERS;INTERFACE_HEADERS;PRIVATE_HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" # Multi-value keywords (lists).
        ${ARGN}
    )

    CMagnetoInternal__normalize_generated_headers_visibility("${ARG_GENERATED_HEADERS_VISIBILITY}" _generatedHeadersVisibility)

    CMagnetoInternal__set_up_export_header("${iLibTargetName}" "${_generatedHeadersVisibility}" _exportHeaderRelPath)
    CMagnetoInternal__set_up_defs_header("${iLibTargetName}" "${_generatedHeadersVisibility}" TRUE _defsHeaderRelPath)
    if("${_generatedHeadersVisibility}" STREQUAL "PUBLIC")
        list(FIND ARG_PUBLIC_HEADERS "${_exportHeaderRelPath}" _exportHeaderIndex)
        if(_exportHeaderIndex EQUAL -1)
            list(APPEND ARG_PUBLIC_HEADERS "${_exportHeaderRelPath}")
        endif()

        list(FIND ARG_PUBLIC_HEADERS "${_defsHeaderRelPath}" _defsHeaderIndex)
        if(_defsHeaderIndex EQUAL -1)
            list(APPEND ARG_PUBLIC_HEADERS "${_defsHeaderRelPath}")
        endif()
    else()
        list(FIND ARG_PRIVATE_HEADERS "${_exportHeaderRelPath}" _exportHeaderIndex)
        if(_exportHeaderIndex EQUAL -1)
            list(APPEND ARG_PRIVATE_HEADERS "${_exportHeaderRelPath}")
        endif()

        list(FIND ARG_PRIVATE_HEADERS "${_defsHeaderRelPath}" _defsHeaderIndex)
        if(_defsHeaderIndex EQUAL -1)
            list(APPEND ARG_PRIVATE_HEADERS "${_defsHeaderRelPath}")
        endif()
    endif()

    CMagnetoInternal__get_target_include_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetIncludeRoot)
    CMagnetoInternal__get_target_resource_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetResourceRoot)

    set(_baseDirDescription "library target \"${iLibTargetName}\"")
    CMagnetoInternal__handle_source_paths("${_targetIncludeRoot}/" "${_baseDirDescription}" "${ARG_PUBLIC_HEADERS}" OUTPUT_ABS_PATHS _absPublicHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_PRIVATE_HEADERS}" OUTPUT_REL_PATHS _relPrivateHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${_targetIncludeRoot}/" "${_baseDirDescription}" "${ARG_INTERFACE_HEADERS}" OUTPUT_ABS_PATHS _absInterfaceHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_SOURCES}" OUTPUT_REL_PATHS _relSources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
    CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_OTHER_RESOURCES}" OUTPUT_ABS_PATHS _absOtherResources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)

    # Add target sources.
    ## Add header sets.
    target_sources(${iLibTargetName}
        PUBLIC
            FILE_SET public_headers TYPE HEADERS
            BASE_DIRS "${_targetIncludeRoot}"
            FILES ${_absPublicHeaders}
    )

    target_sources(${iLibTargetName}
        PRIVATE
            FILE_SET private_headers TYPE HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES ${_relPrivateHeaders}
    )

    target_sources(${iLibTargetName}
        INTERFACE
            FILE_SET interface_headers TYPE HEADERS
            BASE_DIRS "${_targetIncludeRoot}"
            FILES ${_absInterfaceHeaders}
    )

    ## Assign header set visibility.
    set_target_properties(${iLibTargetName} PROPERTIES
        PUBLIC_HEADER_SET public_headers
        PRIVATE_HEADER_SET private_headers
        INTERFACE_HEADER_SET interface_headers
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
    )

    ## Add sources.
    target_sources(${iLibTargetName} PRIVATE $<BUILD_INTERFACE:${_relSources}> ${_absOtherResources})
    #target_sources(${iLibTargetName} PRIVATE ${_relSources})
    ####################################################################

    target_include_directories(${iLibTargetName}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_INCLUDE}> # Set up compiler.
            $<INSTALL_INTERFACE:${CMagneto__SUBDIR_INCLUDE}> # Set up *Config.cmake.
        PRIVATE
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_SRC}>
    )
    CMagnetoInternal__set_up_project_build_info_for_target(${iLibTargetName} PUBLIC)

    # Set up binary.
    CMagneto__compose_binary_OUTPUT_NAME(${iLibTargetName} _binaryOutputName)
    set_target_properties(${iLibTargetName}
        PROPERTIES
            EXPORT_NAME ${_namespacedTargetName}
            OUTPUT_NAME ${_binaryOutputName}
            # CMAKE_VISIBILITY_INLINES_HIDDEN ON  # TODO Parameterize it.
            # POSITION_INDEPENDENT_CODE ON  # TODO Parameterize it.
    )

    # Install.
    ## _libSourceRootRelativeToProjectSourcesSrcRoot helps to keep install dir structure the same as source dir structure.
    CMagneto__get_dir_relative_to_project_sources_src_root("${CMAKE_CURRENT_SOURCE_DIR}" _libSourceRootRelativeToProjectSourcesSrcRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__library(${iLibTargetName}): lib's root CMakeLists.txt directory relative to project source dir: \"${_libSourceRootRelativeToProjectSourcesSrcRoot}\"")

    install(TARGETS ${iLibTargetName}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE
            DESTINATION ${CMagneto__SUBDIR_STATIC}
            COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
        LIBRARY
            DESTINATION ${CMagneto__SUBDIR_SHARED}
            COMPONENT ${CMagneto__COMPONENT__RUNTIME}
        RUNTIME
            DESTINATION ${CMagneto__SUBDIR_EXECUTABLE}
            COMPONENT ${CMagneto__COMPONENT__RUNTIME}
        FILE_SET public_headers
            DESTINATION "${CMagneto__SUBDIR_INCLUDE}/${_libSourceRootRelativeToProjectSourcesSrcRoot}"
            COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
        FILE_SET interface_headers
            DESTINATION "${CMagneto__SUBDIR_INCLUDE}/${_libSourceRootRelativeToProjectSourcesSrcRoot}"
            COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
        # INCLUDES
        #     DESTINATION ...
        #     ...
        # is redundant, because it is effectively set by:
        # target_include_directories(${iLibTargetName}
        #     PUBLIC
        #         $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_SRC}>
        #         $<INSTALL_INTERFACE:${CMagneto__SUBDIR_INCLUDE}>
        # )
        # above.
    )
    ####################################################################

    # Set up Qt TS resources.
    CMagnetoInternal__set_up_QtTS_files(${iLibTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")

    # Set up other resources (not Qt RCC embedded, not Qt TS).
    CMagnetoInternal__set_up_other_resource_files(${iLibTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_OTHER_RESOURCES}")
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    list(APPEND _registeredTargets ${iLibTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets "${_registeredTargets}")

    # Linked imported shared-library targets are registered here so runtime artifact paths
    # can later be queried centrally by imported target through the manifest layer.
    CMagnetoInternal__register_linked_imported_shared_library_targets(${iLibTargetName})

    # Strategies based on target-local runtime files must be attached from the
    # same directory in which the target was created.
    CMagnetoInternal__get_runtime_resolution_strategy(_runtimeResolutionStrategy)
    if(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__TARGET_LOCAL_RUNTIME_FILES}")
        CMagnetoInternal__set_up_target_runtime_resolution(${iLibTargetName})
    endif()
endfunction()
