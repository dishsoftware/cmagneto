set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

cmake_minimum_required(VERSION 3.28)

project(EnowSWContacts
    VERSION 1.0.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)


list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")


if(WIN32)
    message(STATUS "Building on Windows")
    if (MSVC)
        message(STATUS "Compiler: MSVC")
    elseif (MINGW)
        message(STATUS "Compiler: MinGW")
    else()
        message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif()
elseif(APPLE)
    message(STATUS "Building on macOS")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
else()
    message(STATUS "Building on Linux")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()


option(LIB_CONTACTS_SHARED "Build Contacts as a shared library." OFF)
if(LIB_CONTACTS_SHARED)
    message(STATUS "Contacts library will be built as SHARED.")
    add_definitions(-DLIB_CONTACTS_SHARED) # Define preproceccor macro LIB_CONTACTS_SHARED.
else()
    message(STATUS "Contacts library will be built as STATIC.")
endif()


# Include custom CMake modules.
include(QtWrappers)
include(InstallTargets)


set_IS_MULTTCONFIG_property()


add_subdirectory(src)


install__run__script()