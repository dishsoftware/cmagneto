# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
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
    This submodule of the CMagneto module defines functions and variables for handling 3rd-party shared libraries.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools_Internals.cmake")


#[[
    CMagneto__expect_external_shared_libraries_on_target_machine

    Marks imported shared-library targets as expected to be installed on the target
    machine at the same absolute locations as on the build machine.

    On platforms whose runtime-resolution strategy is EMBEDDED_RUNTIME_PATHS,
    CMagneto adds directories of these libraries to INSTALL_RPATH of project
    binaries, so packaged binaries can load them without `set_env`.
    Build-variant-defined policies are preferred. This function is an optional manual override.

    The function must be called after the imported targets exist. It may be called from
    any project `CMakeLists.txt` that runs before `CMagneto__set_up__project()`
    finishes configuring the project.

    Named arguments:
    IMPORTED_TARGETS - imported shared-library targets to treat as preinstalled on the target machine.
]]
function(CMagneto__expect_external_shared_libraries_on_target_machine)
    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "" # Single-value keywords (strings).
        "IMPORTED_TARGETS" # Multi-value keywords (lists).
        ${ARGN}
    )

    if(ARG_IMPORTED_TARGETS STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__expect_external_shared_libraries_on_target_machine: no IMPORTED_TARGETS were provided.")
    endif()

    CMagnetoInternal__register_external_shared_libraries_install_mode("EXPECT_ON_TARGET_MACHINE" "${ARG_IMPORTED_TARGETS}")
endfunction()


#[[
    CMagneto__bundle_external_shared_libraries

    Marks imported shared-library targets to be bundled into the install tree.
    Use this for non-system dependencies that must travel with the package.

    On platforms whose runtime-resolution strategy is EMBEDDED_RUNTIME_PATHS,
    bundled libraries are installed into `${CMagneto__SUBDIR_SHARED}` and
    project binaries use relative INSTALL_RPATH entries such as `$ORIGIN/../lib`.
    Build-variant-defined policies are preferred. This function is an optional manual override.

    The function must be called after the imported targets exist. It may be called from
    any project `CMakeLists.txt` that runs before `CMagneto__set_up__project()`
    finishes configuring the project.

    Named arguments:
    IMPORTED_TARGETS - imported shared-library targets to install into the package.
]]
function(CMagneto__bundle_external_shared_libraries)
    cmake_parse_arguments(ARG
        "" # Options (boolean flags).
        "" # Single-value keywords (strings).
        "IMPORTED_TARGETS" # Multi-value keywords (lists).
        ${ARGN}
    )

    if(ARG_IMPORTED_TARGETS STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__bundle_external_shared_libraries: no IMPORTED_TARGETS were provided.")
    endif()

    CMagnetoInternal__register_external_shared_libraries_install_mode("BUNDLE_WITH_PACKAGE" "${ARG_IMPORTED_TARGETS}")
endfunction()


#[[
    CMagneto__bundle_runtime_dependency_files

    Registers explicit runtime dependency files that must be bundled into the install tree.
    Use this as a low-level override for files that are not represented cleanly by imported
    shared-library targets.

    Named arguments:
    FILES - runtime dependency files to bundle.
]]
function(CMagneto__bundle_runtime_dependency_files)
    cmake_parse_arguments(ARG
        ""
        ""
        "FILES"
        ${ARGN}
    )

    if(ARG_FILES STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__bundle_runtime_dependency_files: no FILES were provided.")
    endif()

    CMagnetoInternal__register_bundled_runtime_dependency_files("${ARG_FILES}" "${CMAKE_CURRENT_SOURCE_DIR}")
endfunction()


#[[
    CMagneto__bundle_runtime_dependency_file_patterns

    Registers low-level file masks that must be searched and bundled into the install tree.

    Named arguments:
    PATTERNS - file masks to search for runtime dependency files to bundle.
]]
function(CMagneto__bundle_runtime_dependency_file_patterns)
    cmake_parse_arguments(ARG
        ""
        ""
        "PATTERNS"
        ${ARGN}
    )

    if(ARG_PATTERNS STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__bundle_runtime_dependency_file_patterns: no PATTERNS were provided.")
    endif()

    CMagnetoInternal__register_bundled_runtime_dependency_file_patterns("${ARG_PATTERNS}" "${CMAKE_CURRENT_SOURCE_DIR}")
endfunction()


#[[
    CMagneto__exclude_bundled_runtime_dependency_files

    Registers explicit runtime dependency files that must not be bundled into the install tree.

    Named arguments:
    FILES - runtime dependency files to exclude from bundling.
]]
function(CMagneto__exclude_bundled_runtime_dependency_files)
    cmake_parse_arguments(ARG
        ""
        ""
        "FILES"
        ${ARGN}
    )

    if(ARG_FILES STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__exclude_bundled_runtime_dependency_files: no FILES were provided.")
    endif()

    CMagnetoInternal__register_excluded_bundled_runtime_dependency_files("${ARG_FILES}" "${CMAKE_CURRENT_SOURCE_DIR}")
endfunction()


#[[
    CMagneto__exclude_bundled_runtime_dependency_file_patterns

    Registers low-level file masks that must not be bundled into the install tree.

    Named arguments:
    PATTERNS - file masks to exclude from bundling.
]]
function(CMagneto__exclude_bundled_runtime_dependency_file_patterns)
    cmake_parse_arguments(ARG
        ""
        ""
        "PATTERNS"
        ${ARGN}
    )

    if(ARG_PATTERNS STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__exclude_bundled_runtime_dependency_file_patterns: no PATTERNS were provided.")
    endif()

    CMagnetoInternal__register_excluded_bundled_runtime_dependency_file_patterns("${ARG_PATTERNS}" "${CMAKE_CURRENT_SOURCE_DIR}")
endfunction()
