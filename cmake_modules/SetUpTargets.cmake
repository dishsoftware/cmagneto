include_guard(GLOBAL)  # Ensures this file is included only once
include(CMakePackageConfigHelpers)


set(SUBDIR_STATIC "lib")
set(SUBDIR_SHARED "lib")
set(SUBDIR_EXECUTABLE "bin")
set(SUBDIR_INCLUDE "include")
set(SUBDIR_CMAKE "lib/cmake")
set(SUBDIR_RESOURCES "resources")
set(PACKAGE_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/${SUBDIR_INCLUDE}")
set(PACKAGE_LIB_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/${SUBDIR_SHARED}")


set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_STATIC}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_SHARED}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}")


function(print_platform_and_compiler)
    message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    message(STATUS "Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
    message(STATUS "Compiler Path: ${CMAKE_CXX_COMPILER}")
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
            message(DEBUG "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        else()
            message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        endif()
    else()
        if(CMAKE_CONFIGURATION_TYPES)
            message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        else()
            message(DEBUG "Single-configuration generator")
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
    create_list_of_paths_to_shared_libs

    The method collects paths to 3rd-party shared libraries, which iTargetName is linked to, and stores them in a global property PATHS_TO_SHARED_LIBS__${iTargetName}.
    Should be called from the same folder where iTargetName is declared after libraries are linked to iTargetName.

    The method was written to overcome the following limitation:
        "get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)" does not return all linked libraries, if called from not the same folder where iTargetName is declared.

    Parameters:
    iTargetName - name of a target in the project.
]]
function(create_list_of_paths_to_shared_libs iTargetName)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    set(_libraryPaths "")

    get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)
    if(_targetLinkLibraries STREQUAL "NOTFOUND")
        set_property(GLOBAL PROPERTY PATHS_TO_SHARED_LIBS__${iTargetName} "")
        return()
    endif()

    # Collect library paths for each linked shared library.
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

        get_target_property(_libPath ${_lib} IMPORTED_LOCATION)
        if(NOT (_libPath AND EXISTS ${_libPath}))
            message(WARNING "create_list_of_paths_to_shared_libs: shared library path \"${_libPath}\" of \"${_lib}\" is not found.")
            continue()
        endif()

        list(APPEND _libraryPaths ${_libPath})
    endforeach()

    list(REMOVE_DUPLICATES _libraryPaths)
    set_property(GLOBAL PROPERTY PATHS_TO_SHARED_LIBS__${iTargetName} "${_libraryPaths}")
endfunction()


#[[
    get_paths_to_shared_libs

    Parameters:
    iTargetName - name of a target in the project.

    Paths to shared libs for iTargetName are filled when set_up_library(iTargetName) or set_up_executable(iTargetName) are called.
]]
function(get_paths_to_shared_libs iTargetName oPaths)
    get_property(_isSet GLOBAL PROPERTY PATHS_TO_SHARED_LIBS__${iTargetName} SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY PATHS_TO_SHARED_LIBS__${iTargetName})
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


function(set_up_project)
    # Export all targets to a single export set.
    install(EXPORT ${PROJECT_NAME}Targets
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
    )

    # Generate the ${PROJECT_NAME}Config.cmake using the template .in file.
    configure_package_config_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in"
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
    )
endfunction()


#[[
    set_up_library

    Sets up building and installation of a library-target iLibName.
    Also registers iLibName in the global property REGISTERED_TARGETS.
    Must be called after linking libraries to iLibName.

    Parameters:
    iLibHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iLibSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(set_up_library iLibName iLibHeaders iLibSources iTSResources iOtherResources)
    add_library(${PROJECT_NAME}::${iLibName} ALIAS ${iLibName})

    target_sources(${iLibName}
        PRIVATE
            ${iLibSources}
            $<BUILD_INTERFACE:${iLibHeaders}> # Headers are added to make them appear in IDEs like Visual Studio.
    )

    target_include_directories(${iLibName}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>
    )

    set_target_properties(${iLibName}
        PROPERTIES
            EXPORT_NAME ${iLibName}
            PUBLIC_HEADER "${iLibHeaders}"
    )
    ####################################################################


    # Installation
    install(TARGETS ${iLibName}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE DESTINATION ${SUBDIR_STATIC}
        LIBRARY DESTINATION ${SUBDIR_SHARED}
        RUNTIME DESTINATION ${SUBDIR_EXECUTABLE}
        PUBLIC_HEADER DESTINATION ${SUBDIR_INCLUDE}/${iLibName}
        # INCLUDES DESTINATION ${SUBDIR_INCLUDE}/${iLibName} is unnecessary.
        # If ^ line is uncommented, a generated ${iLibName}Config.cmake will have
        # INTERFACE_INCLUDE_DIRECTORIES with duplicated "${_IMPORT_PREFIX}/${SUBDIR_INCLUDE}/${iLibName}",
        # because the target_include_directories(${iLibName} PUBLIC $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>) is already set.
    )

    qt_install_ts_resources("${iTSResources}" ${SUBDIR_RESOURCES}/${iLibName}/translations)
    install(FILES ${iOtherResources} DESTINATION ${SUBDIR_RESOURCES}/${iLibName}/other)
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iLibName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    create_list_of_paths_to_shared_libs(${iLibName})
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
function(set_up_executable iExeName iExeHeaders iExeSources iTSResources iOtherResources)
    target_sources(${iExeName} PRIVATE ${iExeSources} ${iExeHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.

    target_include_directories(${iExeName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    )
    ####################################################################


    install(TARGETS ${iExeName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${SUBDIR_EXECUTABLE}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iExeName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    create_list_of_paths_to_shared_libs(${iExeName})
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
            message(FATAL_ERROR "set_project_entrypoint: The project entry point executable is already set to \"${_exeName}\".")
        endif()
    endif()

    get_target_property(_targetType ${iExeName} TYPE)
    if(NOT (${_targetType} STREQUAL "EXECUTABLE"))
        message(FATAL_ERROR "set_project_entrypoint: The target type must be EXECUTABLE.")
    endif()

    set_property(GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE ${iExeName})

    # Make ${iExeName} the startup project in Visual Studio.
    set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${iExeName})
endfunction()


#[[
    get_linked_shared_library_dirs

    Returns directories, containing shared libraries, which iTargets are linked to.
    If a shared library is in iTargets or defined in the project, it's path is not returned.
]]
function(get_linked_shared_library_dirs oLibraryDirs iTargets)
    set(_libraryDirs "")

    foreach(_target ${iTargets})
        if(NOT TARGET ${_target})
            continue()
        endif()

        get_target_property(_targetLinkLibraries ${_target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        get_paths_to_shared_libs(${_target} _libPaths)
        message(DEBUG "get_linked_shared_library_dirs: target " ${_target} " shared lib paths: ${_libPaths}")
        foreach(_libPath ${_libPaths})
            get_filename_component(_libDir ${_libPath} DIRECTORY)
            list(APPEND _libraryDirs ${_libDir})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
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
set(SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/SetUpTargets/${SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")

set(RUN__SCRIPT_NAME_WE "run")
set(RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/SetUpTargets/${RUN__SCRIPT_NAME_WE}__TEMPLATE")


#[[
    set_up__env_vscode__file

    Generates and places to build directory ".env.vscode" file.
    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__env_vscode__file)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    # Generate file content.
    is_multiconfig(IS_MULTICONFIG)
    if (IS_MULTICONFIG)
        set(_libraryDirs "")
        get_linked_shared_library_dirs(_libraryDirs "${_registeredTargets}") #TODO Get shared library paths with respect to $<CONFIG>.
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_fileContent "Path=\"${_libraryDirsNative}\"")
            set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${ENV_VSCODE__SCRIPT_NAME}")
        else()
            set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
            set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${ENV_VSCODE__SCRIPT_NAME}")
        endif()
    else()
        set(_libraryDirs "")
        get_linked_shared_library_dirs(_libraryDirs "${_registeredTargets}")
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_fileContent "Path=\"${_libraryDirsNative}\"")
            set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${ENV_VSCODE__SCRIPT_NAME}")
        else()
            set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
            set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${ENV_VSCODE__SCRIPT_NAME}")
        endif()
    endif()

    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _fileContent "${_fileContent}")

    # Add the file to build dir(s).
    file(GENERATE OUTPUT "${_filePath}" CONTENT "${_fileContent}")
endfunction()


#[[
    set_up__set_env__script

    Generates, places to build directory and installs "set_env" script.
    The script sets paths to 3rd-party shared libraries, which registered targets are linked to.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__set_env__script)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    # Values to replace the param-strings with.
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    message(STATUS "REGISTERED_TARGETS: ${_registeredTargets}")
    ####################################################################

    # Generate script content.
    is_multiconfig(IS_MULTICONFIG)
    if (IS_MULTICONFIG)
        set(_libraryDirs "")
        get_linked_shared_library_dirs(_libraryDirs "${_registeredTargets}") #TODO Get shared library paths with respect to $<CONFIG>.
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}")
        else()
            set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX_STANDARD}.${SCRIPT_EXTENSION_UNIX}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}")
        endif()
    else()
        set(_libraryDirs "")
        get_linked_shared_library_dirs(_libraryDirs "${_registeredTargets}")
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}")
        else()
            set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX_STANDARD}.${SCRIPT_EXTENSION_UNIX}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}")
        endif()
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    # Add the script to build dir(s).
    file(GENERATE OUTPUT "${_scriptPath}" CONTENT "${_scriptContent}")
    if(UNIX)
        add_custom_command(
            OUTPUT "${_scriptPath}"
            COMMAND chmod +x "${_scriptPath}"
            DEPENDS "${_scriptPath}"
            COMMENT "Setting execute permission on ${_scriptPath}"
        )
    endif()

    # Install the script.
    install(
        FILES "${_scriptPath}"
        DESTINATION "${SUBDIR_EXECUTABLE}"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
    )
endfunction()


#[[
    set_up__run__script

    Generates, places to build directory and installs "run" script.
    If a project entrypoint executable is set (look at set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after set_up__set_env__script() is called.
]]
function(set_up__run__script)
    # Strings to replace in the template script.
    set(EXECUTABLE_NAME_WE "param\\nEXECUTABLE_NAME_WE\\nparam")
    ####################################################################

    # Values to replace the param-strings with.
    get_property(_is_PROJECT_ENTRYPOINT_EXE_set GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(NOT (_is_PROJECT_ENTRYPOINT_EXE_set))
        message(WARNING "set_up__run__script: The project entrypoint executable is not set.")
        return()
    endif()
    get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
    ####################################################################

    # Generate script content.
    is_multiconfig(IS_MULTICONFIG)
    if (IS_MULTICONFIG)
        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}")
        else()
            set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}")
        endif()
    else()
        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}")
        else()
            set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
            set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}")
        endif()
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

    # Add the script to build dir(s).
    file(GENERATE OUTPUT "${_scriptPath}" CONTENT "${_scriptContent}")
    if(UNIX)
        add_custom_command(
            OUTPUT "${_scriptPath}"
            COMMAND chmod +x "${_scriptPath}"
            DEPENDS "${_scriptPath}"
            COMMENT "Setting execute permission on ${_scriptPath}"
        )
    endif()

    # Install the script.
    install(
        FILES "${_scriptPath}"
        DESTINATION "${SUBDIR_EXECUTABLE}"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
    )
endfunction()