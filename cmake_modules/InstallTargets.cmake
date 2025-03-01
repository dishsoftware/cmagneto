include(${CMAKE_CURRENT_LIST_DIR}/QtWrappers.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Make_SetSharedLibDirs_Script.cmake)


set(SUBDIR_STATIC "lib")
set(SUBDIR_SHARED "bin")
set(SUBDIR_EXECUTABLE "bin")
set(SUBDIR_INCLUDE "include")
set(SUBDIR_CMAKE "lib/cmake")
set(SUBDIR_RESOURCES "resources")


set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_STATIC}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_SHARED}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}")


# Is appended every time install_library(iLibName) or install_executable(iExeName) is called.
set_property(GLOBAL PROPERTY INSTALLED_TARGETS "")


function(set_IS_MULTTCONFIG_property)
    get_property(_isSet GLOBAL PROPERTY IS_MULTTCONFIG SET)
    if(_isSet)
        return()
    endif()

    if(CMAKE_VERSION VERSION_LESS "3.3.0")
        # Bug https://cmake.org/Bug/view.php?id=15577 .
        if(CMAKE_BUILD_TYPE)
            message(STATUS "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        else()
            message(STATUS "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        endif()
    else()
        if(CMAKE_CONFIGURATION_TYPES)
            message(STATUS "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        else()
            message(STATUS "Single-configuration generator")
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


    get_property(_installedTargets GLOBAL PROPERTY INSTALLED_TARGETS)
    list(APPEND _installedTargets ${iLibName})
    set_property(GLOBAL PROPERTY INSTALLED_TARGETS "${_installedTargets}")
endfunction()


#[[
    install_executable

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


    get_property(_installedTargets GLOBAL PROPERTY INSTALLED_TARGETS)
    list(APPEND _installedTargets ${iExeName})
    set_property(GLOBAL PROPERTY INSTALLED_TARGETS "${_installedTargets}")
endfunction()


#[[
    generate__set_shared_lib_dirs__script

    Must be called after all install_library(iLibName) and install_executable are called.
]]
function(generate__set_shared_lib_dirs__script)
    get_property(_installedTargets GLOBAL PROPERTY INSTALLED_TARGETS)
    message(STATUS "INSTALLED_TARGETS: ${_installedTargets}")
    generate__set_shared_lib_dirs__script_content(_scriptContent "${_installedTargets}")
    message(STATUS "\n${SET_SHARED_LIB_DIRS__SCRIPT_NAME}:\n ${_scriptContent}")

    set(_scriptPath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${SET_SHARED_LIB_DIRS__SCRIPT_NAME}")
    # file(GENERATE OUTPUT "${_scriptPath}" CONTENT "${_scriptContent}")
    file(WRITE "${_scriptPath}" "${_scriptContent}")
    if(UNIX)
        execute_process(COMMAND chmod +x ${_scriptPath})
    endif()
endfunction()