set(_TESTS_TargetName "TESTS_CMagneto_Core")

add_executable(${_TESTS_TargetName}
    TEST_HierarchicalID.cpp
)

target_link_libraries(${_TESTS_TargetName}
    PRIVATE
        CMagneto::Core
        GTest::gtest_main
)

CMagneto__register_test_target(${_TESTS_TargetName})
