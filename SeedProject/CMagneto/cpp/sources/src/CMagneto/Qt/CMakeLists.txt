find_package(Qt6 QUIET COMPONENTS Core Widgets)

if(NOT TARGET Qt6::Core OR NOT TARGET Qt6::Widgets)
    message(STATUS "Skipping CMagneto_Qt because Qt6::Core or Qt6::Widgets is unavailable.")
    return()
endif()

set(_TARGET_NAME CMagneto_Qt)

set(_public_HEADERS
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/helpers/string.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/helpers/settings/leafs.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/AppContext.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/IHasHierarchicalID.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/MainWindow.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/mixins/Base.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/mixins/WithGeometryAndStateSettings.hpp"
    "${CMagneto__CPP_SOURCES_INCLUDE__DIR}/CMagneto/Qt/Widgets/mixins/WithGeometrySettings.hpp"
)

set(_private_HEADERS)

add_library(${_TARGET_NAME}
    Widgets/AppContext.cpp
    Widgets/MainWindow.cpp
    Widgets/mixins/WithGeometrySettings.cpp
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
