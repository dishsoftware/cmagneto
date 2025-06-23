add_executable(TESTS_Contacts
    TEST_Contacts_FieldTypeExtension.cpp
)

target_link_libraries(TESTS_Contacts
    PRIVATE
        GTest::gtest_main
        Contacts
)

register_test_target(TESTS_Contacts)