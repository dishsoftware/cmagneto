add_executable(contacts_tests
    TEST_Contacts_FieldTypeExtension.cpp
)

target_link_libraries(contacts_tests
    GTest::gtest_main
    contacts
)

gtest_discover_tests(contacts_tests)