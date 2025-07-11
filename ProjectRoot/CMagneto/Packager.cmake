# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module should be included by `./packaging/CPackConfig.cmake` of the project.
    This submodule sets up packaging using project metadata in `./meta/` and packaging assets in `./packaging/` of the project.
]]


# Set up CMagneto CMake module logging.
include("${CMAKE_CURRENT_LIST_DIR}/Logger.cmake")

# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")

# Define functions to load project metadata.
include("${CMAKE_CURRENT_LIST_DIR}/MetaLoader.cmake")


CMagneto__parse__packaging_json()


# Check if Qt IFW is available.
find_program(QTIFW_BINARYCREATOR_EXECUTABLE binarycreator)
find_program(QTIFW_REPOGEN_EXECUTABLE repogen)
if(QTIFW_BINARYCREATOR_EXECUTABLE AND QTIFW_REPOGEN_EXECUTABLE) # TODO Move to Qt submodule.
    set(_msgTemplate [=[
Qt Installer Framework found:
    binarycreator is "${QTIFW_BINARYCREATOR_EXECUTABLE}";
    repogen       is "${QTIFW_REPOGEN_EXECUTABLE}".
    ]=])
    string(CONFIGURE "${_msgTemplate}" _msg)
    CMagnetoInternal__message(STATUS "${_msg}")
    set(QT_IFW_AVAILABLE TRUE)
endif()


# Default package generators for each supported platform.
## _packageGenerators is defined along with the CPACK_GENERATOR variable, because include(CPack) overrides CPACK_GENERATOR with a default list.
if(WIN32)
    set(_packageGenerators "ZIP")
    if(QT_IFW_AVAILABLE)
        list(APPEND _packageGenerators "IFW")
    endif()
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

    if(QT_IFW_AVAILABLE)
        list(APPEND _packageGenerators "IFW")
    endif()
else()
    set(_packageGenerators "TGZ")
endif()
set(CPACK_GENERATOR "${_packageGenerators}")


# Generic setup for all package generators.

## Ensures all content are passed to CPack exactly as it defined, without modification or escaping.
set(CPACK_VERBATIM_VARIABLES YES)
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${CMagneto__SUBDIR_PACKAGES}")

set(CPACK_PACKAGE_NAME "${CMagneto__PACKAGING_JSON__PACKAGE_NAME_PREFIX}")
set(CPACK_PACKAGE_VENDOR "CMagneto__PROJECT_JSON__COMPANY_NAME_LEGAL")
set(CPACK_PACKAGE_CONTACT "${CMagneto__PACKAGING_JSON__PACKAGE_MAINTAINER}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${CMAKE_PROJECT_DESCRIPTION}")

set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")

# ? Force the package to be installed in /opt/CompanyName_SHORT/ProjectNameBase on Linux, instead of /usr/local/CompanyName_SHORT/ProjectNameBase.
if(NOT WIN32)
    set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")
endif()

set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

# Packaging assets of the project.
## CMAKE_SOURCE_DIR, not CMAKE_CURRENT_SOURCE_DIR, is used to ensure the project is configured
## using top level directory, if the project is nested and is not added by a parent project using ExternalProject_Add().
set(CMagneto__PACKAGE_RESOURCES_DIR "${CMAKE_SOURCE_DIR}/${CMagneto__SUBDIR_CPACKCONFIG}/${CMagneto__SUBDIR_PACKAGE_RESOURCES}/")

cmake_path(SET CPACK_PACKAGE_DESCRIPTION_FILE NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/Description.txt")
cmake_path(SET CPACK_RESOURCE_FILE_WELCOME NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/Welcome.txt")
cmake_path(SET CPACK_RESOURCE_FILE_LICENSE NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/License.txt")
cmake_path(SET CPACK_RESOURCE_FILE_README NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/Readme.txt")


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
    ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC}
)

# Include generator-specific (*Config_before_include_CPack.cmake) config files.
# If these files are included after include(CPack), they have no effect.
foreach(_generator IN LISTS _packageGenerators)
    if(_generator STREQUAL "DEB")
        include("${CMAKE_CURRENT_LIST_DIR}/Packager/DEB/DEBConfig_before_include_CPack.cmake")
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

cpack_add_component(${CMagneto__COMPONENT__RUNTIME}
    DISPLAY_NAME "${COMPONENT__RUNTIME___NAME}"
    DESCRIPTION "${COMPONENT__RUNTIME___DESCRIPTION}"
    REQUIRED
    INSTALL_TYPES INSTALL_TYPE__NORMAL INSTALL_TYPE__DEVELOPMENT
)

cpack_add_component(${CMagneto__COMPONENT__DEVELOPMENT}
    DISPLAY_NAME "${COMPONENT__DEVELOPMENT___NAME}"
    DESCRIPTION "${COMPONENT__DEVELOPMENT___DESCRIPTION}"
    DEPENDS ${CMagneto__COMPONENT__RUNTIME}
    INSTALL_TYPES INSTALL_TYPE__DEVELOPMENT
)

### Exclude the component from installation entirely.
cpack_add_component(${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC}
    DISPLAY_NAME "${COMPONENT__BUILD_MACHINE_SPECIFIC___NAME}"
    DESCRIPTION "${COMPONENT__BUILD_MACHINE_SPECIFIC___DESCRIPTION}"
    DEPENDS ${CMagneto__COMPONENT__RUNTIME}
    DISABLED HIDDEN
)

# Include generator-specific config files.
foreach(_generator IN LISTS _packageGenerators)
    if(_generator STREQUAL "IFW")
        include("${CMAKE_CURRENT_LIST_DIR}/Packager/IFW/IFWConfig.cmake")
    elseif(_generator STREQUAL "DEB")
        include("${CMAKE_CURRENT_LIST_DIR}/Packager/DEB/DEBConfig.cmake")
    elseif(_generator STREQUAL "ZIP")
        include("${CMAKE_CURRENT_LIST_DIR}/Packager/ZIP/ZIPConfig.cmake")
    else()
        CMagnetoInternal__message(WARNING "CPack configuration for generator '${_generator}' is not supported properly. Only the package properties common to all generators are set.")
    endif()
endforeach()
