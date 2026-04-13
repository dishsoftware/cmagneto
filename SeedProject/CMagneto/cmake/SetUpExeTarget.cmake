# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions and variables for setting up executable targets.
    Notes:
        - Whenever a "target" is mentioned without an additinal context, it means "target created in the project using add_library() or add_executable()".
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpExeTarget_Internals.cmake")

set(CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_WINDOWS_ICON_ABS_PATH "CMagnetoInternal__EXECUTABLE_WINDOWS_ICON_ABS_PATH")
set(CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_LINUX_ICON_ABS_PATH   "CMagnetoInternal__EXECUTABLE_LINUX_ICON_ABS_PATH")
set(CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_MACOS_ICON_ABS_PATH   "CMagnetoInternal__EXECUTABLE_MACOS_ICON_ABS_PATH")
set(CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_PLATFORM_ICON_PLACED   "CMagnetoInternal__EXECUTABLE_PLATFORM_ICON_PLACED")


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
    - HEADERS and SOURCES paths must be relative to the source root directory of the target
      (parent dir of the target's CMakeLists.txt) and must reside under that source root directory.
    - OTHER_RESOURCES paths must be relative to the mirrored resource root of the target,
      obtained from the target source root by replacing `${CMagneto__SUBDIR_SOURCES_SRC}` with `${CMagneto__SUBDIR_SOURCES_RESOURCES}`.
    - All paths must not contain backslashes.
    - Source file paths are also allowed to reside under the build root directory of the target,
      and if they are under the dir, are allowed to be absolute and contain backslashes.
]]
function(CMagneto__set_up__executable iExeTargetName)
    CMagnetoInternal__check_target_name_validity(${iExeTargetName})
    CMagnetoInternal__compose_namespaced_target_name("${iExeTargetName}" _namespacedTargetName)
    add_executable(${_namespacedTargetName} ALIAS ${iExeTargetName})

    cmake_parse_arguments(ARG "" "" "HEADERS;SOURCES;QT_TS_RESOURCES;OTHER_RESOURCES" ${ARGN})

    CMagnetoInternal__set_up_defs_header("${iExeTargetName}" "PRIVATE" FALSE _defsHeaderRelPath)
    list(FIND ARG_HEADERS "${_defsHeaderRelPath}" _defsHeaderIndex)
    if(_defsHeaderIndex EQUAL -1)
        list(APPEND ARG_HEADERS "${_defsHeaderRelPath}")
    endif()

    CMagnetoInternal__get_target_resource_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetResourceRoot)

    set(_baseDirDescription "executable target \"${iExeTargetName}\"")
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_HEADERS}" OUTPUT_REL_PATHS _relHeaders IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)
    CMagnetoInternal__handle_source_paths("${CMAKE_CURRENT_SOURCE_DIR}/" "${_baseDirDescription}" "${ARG_SOURCES}" OUTPUT_REL_PATHS _relSources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL ALLOW_PATHS_UNDER_BUILD_BASE_DIR)
    CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_OTHER_RESOURCES}" OUTPUT_ABS_PATHS _absOtherResources IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL)

    # Add target sources.
    target_sources(${iExeTargetName} PRIVATE ${_relSources} ${_relHeaders} ${_absOtherResources}) # Headers and resources are added to make them appear in IDEs like Visual Studio.
    ####################################################################

    target_include_directories(${iExeTargetName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES_INCLUDE}>  # Set up compiler.
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_SOURCES}>
    )
    CMagnetoInternal__set_up_project_build_info_for_target(${iExeTargetName} PRIVATE)

    # Set up binary.
    CMagneto__compose_binary_OUTPUT_NAME(${iExeTargetName} _binaryOutputName)
    set_target_properties(${iExeTargetName}
        PROPERTIES
            EXPORT_NAME ${_namespacedTargetName}
            OUTPUT_NAME ${_binaryOutputName}
    )

    # Install.
    ## _exeSourceRootRelativeToProjectSourcesSrcRoot helps to keep install dir structure the same as source dir structure.
    CMagneto__get_dir_relative_to_project_sources_src_root("${CMAKE_CURRENT_SOURCE_DIR}" _exeSourceRootRelativeToProjectSourcesSrcRoot)
    CMagnetoInternal__message(TRACE "CMagneto__set_up__executable(${iExeTargetName}): exe's root CMakeLists.txt directory relative to project source dir: \"${_exeSourceRootRelativeToProjectSourcesSrcRoot}\"")

    install(TARGETS ${iExeTargetName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${CMagneto__SUBDIR_EXECUTABLE}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )
    ####################################################################

    # Set up Qt TS resources.
    CMagnetoInternal__set_up_QtTS_files(${iExeTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_QT_TS_RESOURCES}")

    # Set up other resources (not Qt RCC embedded, not Qt TS).
    CMagnetoInternal__set_up_other_resource_files(${iExeTargetName} "${CMAKE_CURRENT_SOURCE_DIR}/" "${ARG_OTHER_RESOURCES}")
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


function(CMagnetoInternal__set_executable_icon_metadata iExeTargetName)
    cmake_parse_arguments(ARG "" "WINDOWS_ICON_ABS_PATH;LINUX_ICON_ABS_PATH;MACOS_ICON_ABS_PATH" "" ${ARGN})

    set_target_properties(${iExeTargetName} PROPERTIES
        ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_WINDOWS_ICON_ABS_PATH} "${ARG_WINDOWS_ICON_ABS_PATH}"
        ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_LINUX_ICON_ABS_PATH}   "${ARG_LINUX_ICON_ABS_PATH}"
        ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_MACOS_ICON_ABS_PATH}   "${ARG_MACOS_ICON_ABS_PATH}"
    )
endfunction()

function(CMagnetoInternal__get_executable_icon_metadata iExeTargetName oWindowsIconAbsPath oLinuxIconAbsPath oMacIconAbsPath)
    get_target_property(_windowsIconAbsPath ${iExeTargetName} ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_WINDOWS_ICON_ABS_PATH})
    get_target_property(_linuxIconAbsPath   ${iExeTargetName} ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_LINUX_ICON_ABS_PATH})
    get_target_property(_macIconAbsPath     ${iExeTargetName} ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_MACOS_ICON_ABS_PATH})

    if(_windowsIconAbsPath MATCHES "-NOTFOUND$")
        set(_windowsIconAbsPath "")
    endif()
    if(_linuxIconAbsPath MATCHES "-NOTFOUND$")
        set(_linuxIconAbsPath "")
    endif()
    if(_macIconAbsPath MATCHES "-NOTFOUND$")
        set(_macIconAbsPath "")
    endif()

    set(${oWindowsIconAbsPath} "${_windowsIconAbsPath}" PARENT_SCOPE)
    set(${oLinuxIconAbsPath}   "${_linuxIconAbsPath}" PARENT_SCOPE)
    set(${oMacIconAbsPath}     "${_macIconAbsPath}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__place_executable_platform_icon iExeTargetName iIconAbsPath)
    if(iIconAbsPath STREQUAL "")
        return()
    endif()

    get_target_property(_iconAlreadyPlaced ${iExeTargetName} ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_PLATFORM_ICON_PLACED})
    if(NOT _iconAlreadyPlaced MATCHES "-NOTFOUND$" AND _iconAlreadyPlaced)
        return()
    endif()

    cmake_path(GET iIconAbsPath FILENAME _iconFileName)

    add_custom_command(TARGET ${iExeTargetName} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${iIconAbsPath}"
            "$<TARGET_FILE_DIR:${iExeTargetName}>/${_iconFileName}"
        COMMENT "Copying icon \"${_iconFileName}\" near executable target \"${iExeTargetName}\"."
    )

    install(FILES "${iIconAbsPath}"
        DESTINATION ${CMagneto__SUBDIR_EXECUTABLE}
        COMPONENT ${CMagneto__COMPONENT__RUNTIME}
    )

    set_target_properties(${iExeTargetName} PROPERTIES
        ${CMagnetoInternal__TARGET_PROPERTY__EXECUTABLE_PLATFORM_ICON_PLACED} TRUE
    )
endfunction()


#[[
    CMagneto__bind_icon_to_executable

    Declares platform-specific application icons for the executable target `${iExeTargetName}`
    and performs platform-native binding where applicable.

    It must be called:
    - After `${iExeTargetName}` has been created.
    - From the root `CMakeLists.txt` of `${iExeTargetName}`.

    Parameters:
    iExeTargetName - The name of the executable target.

    Named arguments (all optional):
    WINDOWS_ICON - Path to a Windows `.ico` file to embed into the executable binary.
    LINUX_ICON   - Path to a Linux icon file, typically `.png` or `.svg`.
    MACOS_ICON   - Path to a macOS `.icns` file to attach to the app bundle.

    Notes:
    - Paths are expected to be relative to the executable target resource root mirrored from the executable target source root.
    - Generated files under the target build base dir are also allowed.
    - The declared icon paths are stored as target metadata and reused by
      `CMagneto__place_icon_near_executable(...)` and
      `CMagneto__add_executable_to_application_menu(...)`.
    - Linux executables do not have a standard embedded desktop icon concept, so on
      Linux this function places the Linux icon near the executable instead.
    - On macOS, the icon only takes effect for `MACOSX_BUNDLE` executables.
]]
function(CMagneto__bind_icon_to_executable iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__bind_icon_to_executable")

    cmake_parse_arguments(ARG "" "WINDOWS_ICON;LINUX_ICON;MACOS_ICON" "" ${ARGN})

    if(ARG_WINDOWS_ICON STREQUAL "" AND ARG_LINUX_ICON STREQUAL "" AND ARG_MACOS_ICON STREQUAL "")
        CMagnetoInternal__message(FATAL_ERROR "CMagneto__bind_icon_to_executable(\"${iExeTargetName}\"): at least one of WINDOWS_ICON, LINUX_ICON or MACOS_ICON must be specified.")
    endif()

    CMagnetoInternal__get_target_resource_root("${CMAKE_CURRENT_SOURCE_DIR}" _targetResourceRoot)

    set(_baseDirDescription "executable target \"${iExeTargetName}\" app icon")
    set(_windowsIconAbsPath "")
    set(_linuxIconAbsPath "")
    set(_macIconAbsPath "")

    if(NOT ARG_WINDOWS_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_WINDOWS_ICON}"
            OUTPUT_ABS_PATHS _windowsIconAbsPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _windowsIconAbsPaths 0 _windowsIconAbsPath)
    endif()

    if(NOT ARG_LINUX_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_LINUX_ICON}"
            OUTPUT_ABS_PATHS _linuxIconAbsPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _linuxIconAbsPaths 0 _linuxIconAbsPath)
    endif()

    if(NOT ARG_MACOS_ICON STREQUAL "")
        CMagnetoInternal__handle_source_paths("${_targetResourceRoot}/" "${_baseDirDescription}" "${ARG_MACOS_ICON}"
            OUTPUT_ABS_PATHS _macIconAbsPaths
            IF_PATH_OUTSIDE_SOURCE_BASE_DIR FAIL
            ALLOW_PATHS_UNDER_BUILD_BASE_DIR
        )
        list(GET _macIconAbsPaths 0 _macIconAbsPath)
    endif()

    CMagnetoInternal__set_executable_icon_metadata(${iExeTargetName}
        WINDOWS_ICON_ABS_PATH "${_windowsIconAbsPath}"
        LINUX_ICON_ABS_PATH "${_linuxIconAbsPath}"
        MACOS_ICON_ABS_PATH "${_macIconAbsPath}"
    )

    if(WIN32 AND NOT _windowsIconAbsPath STREQUAL "")
        CMagnetoInternal__set_up_windows_executable_icon("${iExeTargetName}" "${_windowsIconAbsPath}")
    endif()

    if(UNIX AND NOT APPLE AND NOT _linuxIconAbsPath STREQUAL "")
        CMagnetoInternal__place_executable_platform_icon("${iExeTargetName}" "${_linuxIconAbsPath}")
    endif()

    if(APPLE AND NOT _macIconAbsPath STREQUAL "")

        get_target_property(_isMacBundle ${iExeTargetName} MACOSX_BUNDLE)
        if(NOT _isMacBundle)
            CMagnetoInternal__message(WARNING "CMagneto__bind_icon_to_executable(\"${iExeTargetName}\"): target is not a MACOSX_BUNDLE executable, so MACOS_ICON has no effect.")
            return()
        endif()

        cmake_path(GET _macIconAbsPath FILENAME _macIconFileName)
        set_source_files_properties("${_macIconAbsPath}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
        target_sources(${iExeTargetName} PRIVATE "${_macIconAbsPath}")
        set_target_properties(${iExeTargetName} PROPERTIES MACOSX_BUNDLE_ICON_FILE "${_macIconFileName}")
    endif()
endfunction()

#[[
    CMagneto__place_icon_near_executable

    Places the already-declared platform-specific icon near the executable in the
    build tree and install tree.

    It must be called:
    - After `${iExeTargetName}` has been created.
    - From the root `CMakeLists.txt` of `${iExeTargetName}`.

    Parameters:
    iExeTargetName - The name of the executable target.

    Notes:
    - The function reuses icon metadata previously declared through
      `CMagneto__bind_icon_to_executable(...)`.
    - Only the icon matching the current platform is copied.
    - The copied file keeps its original file name.
    - The installed icon is placed into `${CMagneto__SUBDIR_EXECUTABLE}`, so packaging includes it as a runtime asset.
]]
function(CMagneto__place_icon_near_executable iExeTargetName)
    CMagnetoInternal__check_executable_target_type("${iExeTargetName}" "CMagneto__place_icon_near_executable")

    CMagnetoInternal__get_executable_icon_metadata("${iExeTargetName}" _windowsIconAbsPath _linuxIconAbsPath _macIconAbsPath)

    set(_iconAbsPath "")
    if(WIN32)
        set(_iconAbsPath "${_windowsIconAbsPath}")
    elseif(APPLE)
        set(_iconAbsPath "${_macIconAbsPath}")
    elseif(UNIX)
        set(_iconAbsPath "${_linuxIconAbsPath}")
    endif()

    CMagnetoInternal__place_executable_platform_icon("${iExeTargetName}" "${_iconAbsPath}")
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
