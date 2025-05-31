add_executable(TESTS_contacts
    TEST_Contacts_FieldTypeExtension.cpp
)

target_link_libraries(TESTS_contacts
    PRIVATE
        GTest::gtest_main
        contacts
)

register_test_target(TESTS_contacts)