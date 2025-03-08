set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

cmake_minimum_required(VERSION 3.28) # The oldest version of CMake (on Ubuntu 24 LTS) among the platforms supported by the project.

project(EnowSW_Contacts
    VERSION 1.0.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)


# Include custom CMake modules.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")
include(SetUpTargets)


print_platform_and_compiler()


option(LIB_CONTACTS_SHARED "Build Contacts as a shared library." OFF)
if(LIB_CONTACTS_SHARED)
    message(STATUS "Contacts library will be built as SHARED.")
    add_definitions(-DLIB_CONTACTS_SHARED) # Define preproceccor macro LIB_CONTACTS_SHARED.
else()
    message(STATUS "Contacts library will be built as STATIC.")
endif()


set__IS_MULTTCONFIG__property()


add_subdirectory(src)


set_up__set_env__script()
set_up__env_vscode__file()
set_up__run__script()