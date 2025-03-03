include(${CMAKE_CURRENT_LIST_DIR}/QtWrappers.cmake)


set(SUBDIR_STATIC "lib")
set(SUBDIR_SHARED "bin")
set(SUBDIR_EXECUTABLE "bin")
set(SUBDIR_INCLUDE "include")
set(SUBDIR_CMAKE "lib/cmake")
set(SUBDIR_RESOURCES "resources")


set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_STATIC}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_SHARED}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}")


# Appended every time install_library(iLibName) or install_executable(iExeName) is called.
set_property(GLOBAL PROPERTY REGISTERED_TARGETS "")


function(set_IS_MULTTCONFIG_property)
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
        set_IS_MULTTCONFIG_property()
    endif()

    get_property(_isMulticonfig GLOBAL PROPERTY IS_MULTTCONFIG)
    set(${oIsMulticonfig} ${_isMulticonfig} PARENT_SCOPE)
endfunction()



#[[
    install_library
    Also registers iLibName in the global property REGISTERED_TARGETS.

    Parameters:
    iLibHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iLibSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(install_library iLibName iLibHeaders iLibSources iTSResources iOtherResources)
    target_sources(${iLibName} PRIVATE ${iLibSources} ${iLibHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.

    target_include_directories(${iLibName} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>
    )
    ####################################################################


    # Installation
    install(TARGETS ${iLibName}
        EXPORT ${PROJECT_NAME}TargetGroup
        ARCHIVE DESTINATION ${SUBDIR_STATIC}
        LIBRARY DESTINATION ${SUBDIR_SHARED}
        RUNTIME DESTINATION ${SUBDIR_EXECUTABLE}
        INCLUDES DESTINATION ${SUBDIR_INCLUDE}/${iLibName} # TODO Remove this line if not needed.
        # If ^ uncommented, a generated ${iLibName}Config.cmake will have
        # INTERFACE_INCLUDE_DIRECTORIES with duplicated "${_IMPORT_PREFIX}/${SUBDIR_INCLUDE}/${iLibName}",
        # because the target_include_directories(${iLibName} PUBLIC $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>) is already set.
    )

    install(FILES ${iLibHeaders} DESTINATION ${SUBDIR_INCLUDE}/${iLibName})
    qt_install_ts_resources("${iTSResources}" ${SUBDIR_RESOURCES}/${iLibName}/translations)
    install(FILES ${iOtherResources} DESTINATION ${SUBDIR_RESOURCES}/${iLibName}/other)

    # Generate ${iLibName}Config.cmake
    install(EXPORT ${PROJECT_NAME}TargetGroup
        FILE ${iLibName}Config.cmake
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${SUBDIR_CMAKE}/${iLibName}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iLibName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")
endfunction()


#[[
    install_executable
    Also registers iExeName in the global property REGISTERED_TARGETS.

    Parameters:
    iExeHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iExeSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(install_executable iExeName iExeHeaders iExeSources iTSResources iOtherResources)
    target_sources(${iExeName} PRIVATE ${iExeSources} ${iExeHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.

    target_include_directories(${iExeName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    )
    ####################################################################


    install(TARGETS ${iExeName}
        EXPORT ${PROJECT_NAME}TargetGroup
        DESTINATION ${SUBDIR_EXECUTABLE}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iExeName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")
endfunction()


#[[
    set_project_entrypoint

    Sets the project entry point executable.

    The entry point is run by "run.py" script. The script is generated and installed by install__run__script().
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
    get_shared_library_dirs

    Appends directories, containing shared libraries linked to iTargets, to oLibraryDirs.
]]
function(get_shared_library_dirs oLibraryDirs iTargets)
    set(_libraryDirs "")

    foreach(target ${iTargets})
        get_target_property(_targetLinkLibraries ${target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        # Collect library paths for each linked shared library.
        foreach(_lib ${_targetLinkLibraries})
            if(NOT TARGET ${_lib})
                continue()
            endif()

            # Skip if linked library is a target, created in this project.
            list(FIND iTargets ${_lib} _index)
            if (${_index} GREATER -1)
                continue()
            endif()

            get_target_property(_libType ${_lib} TYPE)
            if(NOT (_libType STREQUAL "SHARED_LIBRARY"))
                continue()
            endif()

            get_target_property(_libPath ${_lib} IMPORTED_LOCATION)
            if(NOT (_libPath AND EXISTS ${_libPath}))
                message(WARNING "get_shared_library_dirs: Shared library of \"${_lib}\" is not found.")
                continue()
            endif()

            get_filename_component(_libDir ${_libPath} DIRECTORY)
            list(APPEND _libraryDirs ${_libDir})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


set(RUN__SCRIPT_NAME "run.py")
set(RUN__TEMPLATE_SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/run_TEMPLATE.py")


#[[
    install__run__script

    The function must be called after all install_library(iLibName) and install_executable(iExeName) are called.
    The script sets paths to shared libraries and runs the project entry point executable.
    The shared library paths are collected from the all registered targets.
]]
function(install__run__script)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param:SHARED_LIB_DIRS_STRING:param")
    set(PARAM__EXECUTABLE_NAME_WE "param:EXECUTABLE_NAME_WE:param")
    ####################################################################

    # Values to replace the param-strings with.
    get_property(_is_PROJECT_ENTRYPOINT_EXE_set GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(NOT (_is_PROJECT_ENTRYPOINT_EXE_set))
        message(FATAL_ERROR "install__run__script: The project entry point executable is not set.")
    endif()
    get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)

    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    message(STATUS "REGISTERED_TARGETS: ${_registeredTargets}")
    ####################################################################

    is_multiconfig(IS_MULTICONFIG)
    if (IS_MULTICONFIG)
        set(_libraryDirs "")
        get_shared_library_dirs(_libraryDirs "${_registeredTargets}") #TODO Get shared library paths with respect to $<CONFIG>.
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        string(JOIN "\\n" _libraryDirsString ${_libraryDirs})

        file(READ "${RUN__TEMPLATE_SCRIPT_PATH}" _scriptContent)
        string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsString}" _scriptContent "${_scriptContent}")
        string(REPLACE "${PARAM__EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

        set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${RUN__SCRIPT_NAME}")

        # Add the script to build dirs.
        file(GENERATE OUTPUT "${_scriptPath}" CONTENT "${_scriptContent}")
        if(UNIX)
            execute_process(COMMAND chmod +x "${_scriptPath}")
        endif()

        # Install the script.
        install(
            FILES "${_scriptPath}"
            DESTINATION ${SUBDIR_EXECUTABLE}
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
        )
    else()
        set(_libraryDirs "")
        get_shared_library_dirs(_libraryDirs "${_registeredTargets}")
        message(DEBUG "Shared lib dirs: ${_libraryDirs}")
        string(JOIN "\\n" _libraryDirsString ${_libraryDirs})

        file(READ "${RUN__TEMPLATE_SCRIPT_PATH}" _scriptContent)
        string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsString}" _scriptContent "${_scriptContent}")
        string(REPLACE "${PARAM__EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

        # Add the script to build dir.
        set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${RUN__SCRIPT_NAME}")
        file(GENERATE OUTPUT "${_scriptPath}" CONTENT "${_scriptContent}")
        if(UNIX)
            execute_process(COMMAND chmod +x ${_scriptPath})
        endif()

        # Install the script.
        install(
            FILES "${_scriptPath}"
            DESTINATION ${SUBDIR_EXECUTABLE}
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
        )
    endif()
endfunction()