set(_TARGET_NAME DishSW_CMagnetoCore)

add_library(${_TARGET_NAME}
    src/FrameworkInfo.cpp
)

add_library(DishSW::CMagnetoCore ALIAS ${_TARGET_NAME})

target_compile_features(${_TARGET_NAME} PUBLIC cxx_std_17)

target_include_directories(${_TARGET_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
