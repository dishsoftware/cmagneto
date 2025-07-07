# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions and variables for setting up targets (common for static/shared libs and exes).
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpTarget_Internals.cmake")


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
    set(_QtRCSourceBaseDir "${CMAKE_CURRENT_SOURCE_DIR}/${CMagneto__SUBDIR_TARGET_RESOURCES}/${CMagneto__SUBDIR_QTRC}/")
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
                    DESTINATION ${CMagneto__SUBDIR_STATIC}
                    COMPONENT ${CMagneto__COMPONENT__DEVELOPMENT}
                LIBRARY
                    DESTINATION ${CMagneto__SUBDIR_SHARED}
                    COMPONENT ${CMagneto__COMPONENT__RUNTIME}
            )
        endforeach()
    endif()
    set(${ARG_OUTPUT_TARGETS} "${_resourceTargetNames}" PARENT_SCOPE)
endfunction()