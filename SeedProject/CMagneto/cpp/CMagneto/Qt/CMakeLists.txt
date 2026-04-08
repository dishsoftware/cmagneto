find_package(Qt6 QUIET COMPONENTS Core)

if(NOT TARGET Qt6::Core)
    message(STATUS "Skipping DishSW_CMagnetoQt because Qt6::Core is unavailable.")
    return()
endif()

set(_TARGET_NAME DishSW_CMagnetoQt)

add_library(${_TARGET_NAME}
    src/FrameworkInfo.cpp
)

add_library(DishSW::CMagnetoQt ALIAS ${_TARGET_NAME})

target_compile_features(${_TARGET_NAME} PUBLIC cxx_std_17)

target_link_libraries(${_TARGET_NAME}
    PUBLIC
        DishSW::CMagnetoCore
        Qt6::Core
)

target_include_directories(${_TARGET_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
