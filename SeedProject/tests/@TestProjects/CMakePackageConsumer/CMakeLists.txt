cmake_minimum_required(VERSION 3.23)

project(CMakePackageConsumer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED ENV{PRIMARY_PROJECT_INSTALL_DIR} OR "$ENV{PRIMARY_PROJECT_INSTALL_DIR}" STREQUAL "")
    message(FATAL_ERROR
        "Environment variable PRIMARY_PROJECT_INSTALL_DIR is not set.\n"
        "It must point to the primary project install prefix, for example:\n"
        "  /path/to/PrimaryProject/install/<build-variant>/<build-type>"
    )
endif()

list(PREPEND CMAKE_PREFIX_PATH "$ENV{PRIMARY_PROJECT_INSTALL_DIR}")

find_package(DishSW_ContactHolder CONFIG REQUIRED)

add_executable(CMakePackageConsumer
    src/main.cpp
)

target_link_libraries(CMakePackageConsumer PRIVATE
    DishSW::ContactHolder::Contacts
)
