set(_TARGET_NAME CMagneto_Core)

set(_public_HEADERS
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Core/FrameworkInfo.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Core/HierarchicalID.hpp"
)

set(_private_HEADERS
    "PrivateDummy.hpp"
)

add_library(${_TARGET_NAME}
    FrameworkInfo.cpp
    HierarchicalID.cpp
)

add_library(CMagneto::Core ALIAS ${_TARGET_NAME})

target_compile_features(${_TARGET_NAME} PUBLIC cxx_std_20)

target_include_directories(${_TARGET_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMagneto__CPP_SOURCES_INCLUDE__DIR}>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        $<BUILD_INTERFACE:${CMagneto__CPP_SOURCES__DIR}>
)

target_sources(${_TARGET_NAME}
    PUBLIC
        FILE_SET public_headers TYPE HEADERS
        BASE_DIRS "${CMagneto__CPP_SOURCES_INCLUDE__DIR}"
        FILES ${_public_HEADERS}
)

target_sources(${_TARGET_NAME}
    PRIVATE
        FILE_SET private_headers TYPE HEADERS
        BASE_DIRS "${CMagneto__CPP_SOURCES__DIR}"
        FILES ${_private_HEADERS}
)
