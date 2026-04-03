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
    This submodule of the CMagneto module defines functions and variables for setting up executable targets.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpExeTarget_Internals.cmake")


#[[
    CMagneto__set_up__executable

    Sets up the build and installation process for the executable target `${iExeTargetName}`.
    This function also registers `${iExeTargetName}` in the global property `CMagnetoInternal__RegisteredTargets`.

    It must be called:
    - Once for the executable target.
    - After `${iExeTargetName}` has been created and linked against its dependencies.
    - From the root `CMakeLists.txt` of `${iExeTargetName}`. The root `CMakeLists.txt` must be in the source root of the executable.

    Parameters:
    iExeTargetName           - The name of the executable target to configure.

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
function(CMagneto__set_up__executable iExeTargetName)
    CMagnetoInternal__check_target_name_validity(${iExeTargetName})
    CMagnetoInternal__compose_namespaced_target_name("${iExeTargetName}" _namespacedTargetName)
    add_executable(${_namespacedTargetName} ALIAS ${iExeTargetName})

    cmake_parse_arguments(ARG "" "" "HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" ${ARGN})

    CMagnetoInternal__set_up_defs_header("${iExeTargetName}" FALSE _defsHeaderRelPath)
    list(FIND ARG_HEADERS "${_defsHeaderRelPath}" _defsHeaderIndex)
    if(_defsHeaderIndex EQUAL -1)
        list(APPEND ARG_HEADERS "${_defsHeaderRelPath}")
    endif()

    set(_baseDirDescription "executable target \"${iExeTargetName}\"")
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_HEADERS}" OUTPUT_REL_PATHS _relHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_SOURCES}" OUTPUT_REL_PATHS _relSources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
    #CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${OTHER_RESOURCES}" OUTPUT_REL_PATHS _relOtherResources)

    # Add target sources.
    target_sources(${iExeTargetName} PRIVATE ${_relSources} ${_relHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.
    ####################################################################

    target_include_directories(${iExeTargetName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCE}>  # Set up compiler.
    )

    # Set up binary.
    CMagneto__compose_binary_OUTPUT_NAME(${iExeTargetName} _binaryOutputName)
    set_target_properties(${iExeTargetName}
        PROPERTIES
            EXPORT_NAME ${_namespacedTargetName}
            OUTPUT_NAME ${_binaryOutputName}
    )

    # Install.
    ## _exeSourceRootRelativeToProjectSourceRoot helps to keep install dir structure the same as source dir structure.
    CMagneto__get_dir_relative_to_project_source_root("${CMAKE_CURRENT_SOURCE_DIR}" _exeSourceRootRelativeToProjectSourceRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__executable(${iExeTargetName}): exe's root CMakeLists.txt directory relative to project source dir: \"${_exeSourceRootRelativeToProjectSourceRoot}\"")

    install(TARGETS ${iExeTargetName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${CMagneto__SUBDIR_EXECUTABLE}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )
    ####################################################################

    # Set up Qt TS resources.
    CMagnetoInternal__set_up_QtTS_files(${iExeTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")

    # Set up other resources (not Qt RCC embedded, not Qt TS).
    # TODO
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets)
    list(APPEND _registeredTargets ${iExeTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTargets "${_registeredTargets}")

    # Linked imported shared-library targets are registered here so runtime artifact paths
    # can later be queried centrally by imported target through the manifest layer.
    CMagnetoInternal__register_linked_imported_shared_library_targets(${iExeTargetName})

    # Strategies based on target-local runtime files must be attached from the
    # same directory in which the target was created.
    CMagnetoInternal__get_runtime_resolution_strategy(_runtimeResolutionStrategy)
    if(_runtimeResolutionStrategy STREQUAL "${CMagnetoInternal__RUNTIME_RESOLUTION_STRATEGY__TARGET_LOCAL_RUNTIME_FILES}")
        CMagnetoInternal__set_up_target_runtime_resolution(${iExeTargetName})
    endif()
endfunction()


#[[
    CMagneto__bind_icon_to_exe_binary

    Binds platform-specific application icons to the executable binary target `${iExeTargetName}`.

    It must be called:
    - After `${iExeTargetName}` has been created.
    - From the root `CMakeLists.txt` of `${iExeTargetName}`.

    Parameters:
    iExeTargetName - The name of the executable target.

    Named arguments (all optional):
    WINDOWS_ICON - Path to a Windows `.ico` file to embed into the executable binary.
    MACOS_ICON   - Path to a macOS `.icns` file to attach to the app bundle.

    Notes:
    - Paths are expected to be relative to the executable target source root.
    - Generated files under the target build base dir are also allowed.
    - Linux executables do not have a standard embedded desktop icon concept, so this function is a no-op there.
    - On macOS, the icon only takes effect for `MACOSX_BUNDLE` executables.
]]
function(CMagneto__bind_icon_to_exe_binary iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__bind_icon_to_exe_binary")

    cmake_parse_arguments(ARG "" "WINDOWS_ICON;MACOS_ICON" "" ${ARGN})

    if(ARG_WINDOWS_ICON STREQUAL "" AND ARG_MACOS_ICON STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__bind_icon_to_exe_binary(\"${iExeTargetName}\"): at least one of WINDOWS_ICON or MACOS_ICON must be specified.")
    endif()

    set(_baseDirDescription "executable target \"${iExeTargetName}\" app icon")

    if(WIN32 AND NOT ARG_WINDOWS_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_WINDOWS_ICON}"
            OUTPUT_ABS_PATHS _windowsIconAbsPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _windowsIconAbsPaths 0 _windowsIconAbsPath)
        CMagnetoInternal__set_up_windows_executable_icon("${iExeTargetName}" "${_windowsIconAbsPath}")
    endif()

    if(APPLE AND NOT ARG_MACOS_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_MACOS_ICON}"
            OUTPUT_ABS_PATHS _macIconAbsPaths
            OUTPUT_REL_PATHS _macIconRelPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _macIconAbsPaths 0 _macIconAbsPath)
        list(GET _macIconRelPaths 0 _macIconRelPath)

        get_target_property(_isMacBundle ${iExeTargetName} MACOSX_BUNDLE)
        if(NOT _isMacBundle)
            CMagnetoInternal__message(WARNING "CMagneto__bind_icon_to_exe_binary(\"${iExeTargetName}\"): target is not a MACOSX_BUNDLE executable, so MACOS_ICON has no effect.")
            return()
        endif()

        cmake_path(GET _macIconRelPath FILENAME _macIconFileName)
        set_source_files_properties("${_macIconAbsPath}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
        target_sources(${iExeTargetName} PRIVATE "${_macIconAbsPath}")
        set_target_properties(${iExeTargetName} PROPERTIES MACOSX_BUNDLE_ICON_FILE "${_macIconFileName}")
    endif()
endfunction()


#[[
    CMagneto__place_icon_near_executable

    Places a platform-specific icon file near the executable in the build tree and install tree.

    It must be called:
    - After `${iExeTargetName}` has been created.
    - From the root `CMakeLists.txt` of `${iExeTargetName}`.

    Parameters:
    iExeTargetName - The name of the executable target.

    Named arguments (all optional):
    WINDOWS_ICON - Path to a Windows icon file, typically `.ico`.
    LINUX_ICON   - Path to a Linux icon file, typically `.png` or `.svg`.
    MACOS_ICON   - Path to a macOS icon file, typically `.icns`.

    Notes:
    - Paths are expected to be relative to the executable target source root.
    - Generated files under the target build base dir are also allowed.
    - Only the icon matching the current platform is copied.
    - The copied file keeps its original file name.
    - The installed icon is placed into `${CMagneto__SUBDIR_EXECUTABLE}`, so packaging includes it as a runtime asset.
]]
function(CMagneto__place_icon_near_executable iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__place_icon_near_executable")

    cmake_parse_arguments(ARG "" "WINDOWS_ICON;LINUX_ICON;MACOS_ICON" "" ${ARGN})

    if(ARG_WINDOWS_ICON STREQUAL "" AND ARG_LINUX_ICON STREQUAL "" AND ARG_MACOS_ICON STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__place_icon_near_executable(\"${iExeTargetName}\"): at least one of WINDOWS_ICON, LINUX_ICON or MACOS_ICON must be specified.")
    endif()

    set(_iconPath "")
    if(WIN32)
        set(_iconPath "${ARG_WINDOWS_ICON}")
    elseif(APPLE)
        set(_iconPath "${ARG_MACOS_ICON}")
    elseif(UNIX)
        set(_iconPath "${ARG_LINUX_ICON}")
    endif()

    if(_iconPath STREQUAL "")
        return()
    endif()

    set(_baseDirDescription "executable target \"${iExeTargetName}\" adjacent icon")
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${_iconPath}"
        OUTPUT_ABS_PATHS _iconAbsPaths
        OUTPUT_REL_PATHS _iconRelPaths
        IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
        ALLOW_PATHS_UNDER_BUILD_BASE_DIR
    )
    list(GET _iconAbsPaths 0 _iconAbsPath)
    list(GET _iconRelPaths 0 _iconRelPath)
    cmake_path(GET _iconRelPath FILENAME _iconFileName)

    add_custom_command(TARGET ${iExeTargetName} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_iconAbsPath}"
            "$<TARGET_FILE_DIR:${iExeTargetName}>/${_iconFileName}"
        COMMENT "Copying icon \"${_iconFileName}\" near executable target \"${iExeTargetName}\"."
    )

    install(FILES "${_iconAbsPath}"
        DESTINATION ${CMagneto__SUBDIR_EXECUTABLE}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )
endfunction()


#[[
    CMagneto__set_project_entrypoint

    Sets the project entry point executable.

    The entry point executable is run by "run" script, which is set up by CMagnetoInternal__set_up__run__script().
    The entry point executable is also run when the project is started in Visual Studio.

    Parameters:
    iExeTargetName - the name of the executable that is the project entry point.
]]
function(CMagneto__set_project_entrypoint iExeTargetName)
    get_property(_isSet GLOBAL PROPERTY CMagnetoInternal__ProjectEntrypointExeTargetName SET)
    if(_isSet)
        get_property(_exeTargetName GLOBAL PROPERTY CMagnetoInternal__ProjectEntrypointExeTargetName)
        if(NOT (_exeTargetName STREQUAL iExeTargetName))
            CMagnetoInternal__message(FATAL_ERROR "CMagneto__set_project_entrypoint: The project entry point executable target is already set to \"${_exeTargetName}\".")
        endif()
    endif()

    get_target_property(_targetType ${iExeTargetName} TYPE)
    if(NOT (${_targetType} STREQUAL "EXECUTABLE"))
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__set_project_entrypoint: The target type must be EXECUTABLE.")
    endif()

    set_property(GLOBAL PROPERTY CMagnetoInternal__ProjectEntrypointExeTargetName ${iExeTargetName})
    CMagnetoInternal__message(STATUS "\"${iExeTargetName}\" executable target is set as the \"${PROJECT_NAME}\" project entrypoint.")

    # Make ${iExeTargetName} the startup project in Visual Studio.
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${iExeTargetName})
endfunction()


function(CMagneto__get_project_entrypoint oExeTargetName)
    get_property(_isSet GLOBAL PROPERTY CMagnetoInternal__ProjectEntrypointExeTargetName SET)
    if(NOT _isSet)
        unset(${oExeTargetName} PARENT_SCOPE)
        return()
    endif()

    get_property(_exeTargetName GLOBAL PROPERTY CMagnetoInternal__ProjectEntrypointExeTargetName)
    set(${oExeTargetName} "${_exeTargetName}" PARENT_SCOPE)
endfunction()
