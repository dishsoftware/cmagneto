include_guard(GLOBAL)  # Ensures this file is included only once.

# Default package generators for each supported platform.
## _packageGenerators is defined along with the CPACK_GENERATOR variable, because include(CPack) overrides CPACK_GENERATOR with a default list.
if(WIN32)
    set(_packageGenerators "IFW")
# elseif(APPLE)
    # set(_packageGenerators productbuild)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    execute_process(COMMAND which dpkg
                    RESULT_VARIABLE _hasDPKG
                    OUTPUT_QUIET ERROR_QUIET)

    execute_process(COMMAND which rpm
                    RESULT_VARIABLE _hasRPM
                    OUTPUT_QUIET ERROR_QUIET)

    if(_hasDPKG EQUAL 0)
        set(_packageGenerators "DEB")
    elseif(_hasRPM EQUAL 0)
        set(_packageGenerators "RPM")
    else()
        set(_packageGenerators "TGZ")
    endif()
else()
    set(_packageGenerators "TGZ")
endif()
set(CPACK_GENERATOR "${_packageGenerators}")



# Generic setup for all package generators.

## Ensures all content are passed to CPack exactly as it defined, without modification or escaping.
set(CPACK_VERBATIM_VARIABLES YES)
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${SUBDIR_PACKAGES}")

set(CPACK_PACKAGE_NAME "EnowContacts")
set(CPACK_PACKAGE_VENDOR "Enow Software")
set(CPACK_PACKAGE_CONTACT "Dim Shvydkoy <dmit.shvyd@gmail.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${CMAKE_PROJECT_DESCRIPTION}")

set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

set(CPACK_PACKAGE_INSTALL_DIRECTORY "EnowSW/Contacts")

# ? Force the package to be installed in /opt/EnowSW/Contacts on Linux, instead of /usr/local/EnowSW/Contacts.
if(NOT WIN32)
    message(STATUS "Setting CPACK_PACKAGING_INSTALL_PREFIX to /opt/EnowSW/Contacts")
    set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/EnowSW/Contacts")
endif()

set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

set(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_CURRENT_LIST_DIR}/Description.txt)
set(CPACK_RESOURCE_FILE_WELCOME ${CMAKE_CURRENT_LIST_DIR}/Welcome.txt)
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_LIST_DIR}/License.txt)
set(CPACK_RESOURCE_FILE_README ${CMAKE_CURRENT_LIST_DIR}/Readme.txt)


## Component setup.
set(INSTALL_TYPE__NORMAL__NAME "Normal")
set(INSTALL_TYPE__NORMAL__NAME_ru "Обычная")

set(INSTALL_TYPE__DEVELOPMENT__NAME "Development")
set(INSTALL_TYPE__DEVELOPMENT__NAME_ru "Разработка")
set(INSTALL_TYPE__DEVELOPMENT__DESCRIPTION "Install files required to use the project as a dependency in a software, being developed on this machine.")
set(INSTALL_TYPE__DEVELOPMENT__DESCRIPTION_ru "Установить файлы, необходимые для использования проекта как зависимости в программном обеспечении, разрабатываемом на этом компьютере.")

set(COMPONENT__RUNTIME___NAME "Runtime")
set(COMPONENT__RUNTIME___NAME_ru "Исполняемые файлы")
set(COMPONENT__RUNTIME___DESCRIPTION "Runtime libraries and executables.")
set(COMPONENT__RUNTIME___DESCRIPTION_ru "Исполняемые файлы и библиотеки.")

set(COMPONENT__DEVELOPMENT___NAME "Development")
set(COMPONENT__DEVELOPMENT___NAME_ru "Разработка")
set(COMPONENT__DEVELOPMENT___DESCRIPTION "Headers, static libraries and CMake package configuration files.")
set(COMPONENT__DEVELOPMENT___DESCRIPTION_ru "Заголовочные файлы, статические библиотеки и файлы конфигурации CMake пакета.")

set(COMPONENT__BUILD_MACHINE_SPECIFIC___NAME "Build Machine Specific")
set(COMPONENT__BUILD_MACHINE_SPECIFIC___DESCRIPTION "Files that, most probably, are not usable anywhere, except the machine the project was built on.")


### Exclude some components from installation entirely.
get_cmake_property(CPACK_COMPONENTS_ALL COMPONENTS)
list(REMOVE_ITEM CPACK_COMPONENTS_ALL
    ${COMPONENT__BUILD_MACHINE_SPECIFIC}
)

# Include generator-specific (*Config_before_include_CPack.cmake) config files.
foreach(_generator IN LISTS _packageGenerators)
    message(STATUS "Configuring CPack for generator '${_generator}'...")
    if(_generator STREQUAL "DEB")
        include(${CMAKE_CURRENT_LIST_DIR}/DEB/DEBConfig_before_include_CPack.cmake)
    endif()
endforeach()

include(CPack)

cpack_add_install_type(INSTALL_TYPE__NORMAL
    DISPLAY_NAME "${INSTALL_TYPE__NORMAL__NAME}"
)

cpack_add_install_type(INSTALL_TYPE__DEVELOPMENT
    DISPLAY_NAME "${INSTALL_TYPE__DEVELOPMENT__NAME}"
    DESCRIPTION "${INSTALL_TYPE__DEVELOPMENT__DESCRIPTION}"
)

cpack_add_component(${COMPONENT__RUNTIME}
    DISPLAY_NAME "${COMPONENT__RUNTIME___NAME}"
    DESCRIPTION "${COMPONENT__RUNTIME___DESCRIPTION}"
    REQUIRED
    INSTALL_TYPES INSTALL_TYPE__NORMAL INSTALL_TYPE__DEVELOPMENT
)

cpack_add_component(${COMPONENT__DEVELOPMENT}
    DISPLAY_NAME "${COMPONENT__DEVELOPMENT___NAME}"
    DESCRIPTION "${COMPONENT__DEVELOPMENT___DESCRIPTION}"
    DEPENDS ${COMPONENT__RUNTIME}
    INSTALL_TYPES INSTALL_TYPE__DEVELOPMENT
)

### Exclude the component from installation entirely.
cpack_add_component(${COMPONENT__BUILD_MACHINE_SPECIFIC}
    DISPLAY_NAME "${COMPONENT__BUILD_MACHINE_SPECIFIC___NAME}"
    DESCRIPTION "${COMPONENT__BUILD_MACHINE_SPECIFIC___DESCRIPTION}"
    DEPENDS ${COMPONENT__RUNTIME}
    DISABLED HIDDEN
)



# Include generator-specific config files.
foreach(_generator IN LISTS _packageGenerators)
    message(STATUS "Configuring CPack for generator '${_generator}'...")
    if(_generator STREQUAL "IFW")
        include(${CMAKE_CURRENT_LIST_DIR}/IFW/IFWConfig.cmake)
    elseif(_generator STREQUAL "DEB")
        include(${CMAKE_CURRENT_LIST_DIR}/DEB/DEBConfig.cmake)
    else()
        message(WARNING "CPack configuration for generator '${_generator}' is not supported properly. Only the package properties common to all generators are set.")
    endif()
endforeach()