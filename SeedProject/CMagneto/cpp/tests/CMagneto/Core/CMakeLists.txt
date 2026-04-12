set(_TESTS_TargetName "TESTS_CMagneto_Core")

add_executable(${_TESTS_TargetName}
    TEST_AppContext.cpp
    TEST_HierarchicalID.cpp
    TEST_Logger.cpp
    TEST_logger_sinks.cpp
)

target_link_libraries(${_TESTS_TargetName}
    PRIVATE
        CMagneto::Core
        GTest::gtest_main
)

target_include_directories(${_TESTS_TargetName}
    PRIVATE
        $<BUILD_INTERFACE:${CMagneto__CPP_TESTS__DIR}>
)

CMagneto__register_test_target(${_TESTS_TargetName})
