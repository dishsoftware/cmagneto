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
    This submodule of the CMagneto module defines functions and variables for setting up targets (common for static/shared libs and exes).
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpTarget_Internals.cmake")


#[[
    CMagneto__compose_binary_OUTPUT_NAME

    Returns name of target's compiled binary without extension.
    E.g. `DishSW_ContactHolder_Contacts` -> `DishSW_ContactHolderX_Contacts`, where "X" is major version of a project.
]]
function(CMagneto__compose_binary_OUTPUT_NAME iTargetName oBinaryOutputName)
    set(_binaryTargetNamePostfix "${iTargetName}")
    set(_projectTargetNamePrefix "${PROJECT_NAME}_")
    string(FIND "${iTargetName}" "${_projectTargetNamePrefix}" _projectTargetNamePrefixPos)
    if(_projectTargetNamePrefixPos EQUAL 0)
        string(LENGTH "${_projectTargetNamePrefix}" _projectTargetNamePrefixLength)
        string(SUBSTRING "${iTargetName}" ${_projectTargetNamePrefixLength} -1 _binaryTargetNamePostfix)
    endif()

    set(${oBinaryOutputName} "${PROJECT_NAME}${CMAKE_PROJECT_VERSION_MAJOR}_${_binaryTargetNamePostfix}" PARENT_SCOPE)
endfunction()


#[[
    CMagneto__embed_QtRC_resources

    The function does the same as qt_add_resources, but the CMagneto__embed_QtRC_resources also
    - checks if all paths from the named arguments BIG_RESOURCES and FILES are under target QtRC directory;
    - derives resource prefix automatically from the target source root mirrored under `${CMagneto__SUBDIR_SOURCES_SRC}`;
    - composes resource name as `${iTargetName}__${iResourceNamePostfix}`;
    - if Qt creates auxilliary resource targets, the targets are exported (added to *Config.cmake).

    Notes:
    - All paths from the named arguments BIG_RESOURCES and FILES
      must be relative to the mirrored resource root of the target.
      The paths must reside under the QtRC directory of the target resource root.
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
        "LANG;OUTPUT_TARGETS" # Single-value keywords (strings).
        "BIG_RESOURCES;FILES;OPTIONS" # Multi-value keywords (lists).
        ${ARGN}
    )

    if(iResourceNamePostfix STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__embed_QtRC_resources(\"${iTargetName}\" \"${iResourceNamePostfix}\"): iResourceNamePostfix is empty.")
    endif()

    CMagnetoInternal__get_target_resource_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetResourceRoot)
    cmake_path(SET _QtRCSourceBaseDir NORMALIZE "${_targetResourceRoot}/${CMagneto__SUBDIR_QTRC}")
    set(_baseDirDescription "target \"${iTargetName}\" QtRC")
    CMagnetoInternal__handle_source_paths("${_targetResourceRoot}" "${_baseDirDescription}" "${ARG_BIG_RESOURCES}" OUTPUT_ABS_PATHS _absBigResources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${_targetResourceRoot}" "${_baseDirDescription}" "${ARG_FILES}" OUTPUT_ABS_PATHS _absFiles IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    if("${_absBigResources};${_absFiles}" STREQUAL ";")
        if(NOT ARG_OUTPUT_TARGETS STREQUAL "")
            set(${ARG_OUTPUT_TARGETS} "" PARENT_SCOPE)
        endif()
        return()
    endif()

    foreach(_absResourcePath IN LISTS _absBigResources _absFiles)
        CMagneto__is_path_under_dir("${_absResourcePath}" "${_QtRCSourceBaseDir}" _isUnderQtRCSourceRoot)
        if(NOT _isUnderQtRCSourceRoot)
            CMagnetoInternal__message(FATAL_ERROR "CMagneto__embed_QtRC_resources(\"${iTargetName}\" \"${iResourceNamePostfix}\"): resource path \"${_absResourcePath}\" is outside of target QtRC source root \"${_QtRCSourceBaseDir}\".")
        endif()
    endforeach()

    CMagneto__get_dir_relative_to_project_sources_src_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetSourceRootRelativeToProjectSourcesSrcRoot)
    if(_targetSourceRootRelativeToProjectSourcesSrcRoot STREQUAL "")
        set(_qtRCPrefix "/")
    else()
        set(_qtRCPrefix "/${_targetSourceRootRelativeToProjectSourcesSrcRoot}")
    endif()

    qt_add_resources(${iTargetName} "${iTargetName}__${iResourceNamePostfix}"
        PREFIX "${_qtRCPrefix}"
        LANG "${ARG_LANG}"
        BASE "${_QtRCSourceBaseDir}"
        BIG_RESOURCES ${_absBigResources}
        OUTPUT_TARGETS _outputTargets
        FILES ${_absFiles}
        OPTIONS ${ARG_OPTIONS}
    )

    set(_resourceTargetNames "${_outputTargets}")
    if (NOT _resourceTargetNames STREQUAL "")
        CMagnetoInternal__message(STATUS "CMagneto__embed_QtRC_resources(\"${iTargetName}\" \"${iResourceNamePostfix}\"): Qt created resource targets: ${_resourceTargetNames}.")
        foreach(_resourceTargetName IN LISTS _resourceTargetNames)
            install(TARGETS ${_resourceTargetName}
                EXPORT ${PROJECT_NAME}Targets
                ARCHIVE
                    DESTINATION ${CMagneto__SUBDIR_STATIC}
                    COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
                LIBRARY
                    DESTINATION ${CMagneto__SUBDIR_SHARED}
                    COMPONENT ${CMagneto__COMPONENT__RUNTIME}
            )
        endforeach()
    endif()
    if(NOT ARG_OUTPUT_TARGETS STREQUAL "")
        set(${ARG_OUTPUT_TARGETS} "${_resourceTargetNames}" PARENT_SCOPE)
    endif()
endfunction()
