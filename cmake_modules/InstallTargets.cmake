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
    generate__set_shared_lib_dirs__script

    Must be called after all install_library(iLibName) and install_executable are called.
]]
function(generate__set_shared_lib_dirs__script)
    get_property(_installedTargets GLOBAL PROPERTY INSTALLED_TARGETS)
    message(STATUS "INSTALLED_TARGETS: ${_installedTargets}")
    generate__set_shared_lib_dirs__script_content(_scriptContent "${_installedTargets}")
    message(STATUS "\n${SET_SHARED_LIB_DIRS__SCRIPT_NAME}:\n ${_scriptContent}")
    #file(GENERATE OUTPUT ${SET_SHARED_LIB_DIRS__SCRIPT_NAME} CONTENT "${_scriptContent}")
    file(WRITE "${CMAKE_BINARY_DIR}/${SET_SHARED_LIB_DIRS__SCRIPT_NAME}" "${_scriptContent}")
endfunction()