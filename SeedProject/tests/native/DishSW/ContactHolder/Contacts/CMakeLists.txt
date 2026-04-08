set(_TESTS_TargetName "TESTS_${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}_${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}_Contacts")

add_executable(${_TESTS_TargetName}
    TEST_FieldTypeExtension.cpp
)

target_link_libraries(${_TESTS_TargetName}
    PRIVATE
        GTest::gtest_main
        DishSW::ContactHolder::Contacts
)

CMagneto__register_test_target(${_TESTS_TargetName})
