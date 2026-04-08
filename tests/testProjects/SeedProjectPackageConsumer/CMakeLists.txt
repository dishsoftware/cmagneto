cmake_minimum_required(VERSION 3.23)

project(SeedProjectPackageConsumer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED ENV{SEEDPROJECT_INSTALL_DIR} OR "$ENV{SEEDPROJECT_INSTALL_DIR}" STREQUAL "")
    message(FATAL_ERROR
        "Environment variable SEEDPROJECT_INSTALL_DIR is not set.\n"
        "It must point to the SeedProject install prefix, for example:\n"
        "  /home/dim/Work/Dish/CMagneto/SeedProject/install/Makefiles_GCC/Release"
    )
endif()

list(PREPEND CMAKE_PREFIX_PATH "$ENV{SEEDPROJECT_INSTALL_DIR}")

find_package(DishSW_ContactHolder CONFIG REQUIRED)

add_executable(SeedProjectPackageConsumer
    src/main.cpp
)

target_link_libraries(SeedProjectPackageConsumer PRIVATE
    DishSW::ContactHolder::Contacts
)
