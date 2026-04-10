find_package(Qt6 QUIET COMPONENTS Core Widgets)

if(NOT TARGET Qt6::Core OR NOT TARGET Qt6::Widgets)
    message(STATUS "Skipping CMagneto_Qt because Qt6::Core or Qt6::Widgets is unavailable.")
    return()
endif()

set(_TARGET_NAME CMagneto_Qt)

set(_public_HEADERS
    "${CMagneto__CPP_INCLUDE_CMAGNETO__DIR}/Qt/FrameworkInfo.hpp"
    "${CMagneto__CPP_INCLUDE_CMAGNETO__DIR}/Qt/Widgets/Mixin.hpp"
)

set(_private_HEADERS)

add_library(${_TARGET_NAME}
    FrameworkInfo.cpp
    Widgets/Mixin.cpp
)

add_library(CMagneto::Qt ALIAS ${_TARGET_NAME})

target_compile_features(${_TARGET_NAME} PUBLIC cxx_std_20)

target_link_libraries(${_TARGET_NAME}
    PUBLIC
        CMagneto::Core
        Qt6::Core
        Qt6::Widgets
)

target_include_directories(${_TARGET_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMagneto__CPP__DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        $<BUILD_INTERFACE:${CMagneto__CPP__DIR}>
)

target_sources(${_TARGET_NAME}
    PUBLIC
        FILE_SET public_headers TYPE HEADERS
        BASE_DIRS "${CMagneto__CPP__DIR}/include"
        FILES ${_public_HEADERS}
)

target_sources(${_TARGET_NAME}
    PRIVATE
        FILE_SET private_headers TYPE HEADERS
        BASE_DIRS "${CMagneto__CPP__DIR}"
        FILES ${_private_HEADERS}
)
