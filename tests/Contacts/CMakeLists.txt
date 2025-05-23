add_executable(TESTS_contacts
    TEST_Contacts_FieldTypeExtension.cpp
)

target_link_libraries(TESTS_contacts
    GTest::gtest_main
    contacts
)

get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
is_multiconfig(IS_MULTICONFIG)
if(IS_MULTICONFIG)
    foreach(_config ${CMAKE_CONFIGURATION_TYPES})
        get_shared_library_dirs(_libraryDirs_${_config} "${_registeredTargets}" "${_config}")
        cmake_path(CONVERT "${_libraryDirs_${_config}}" TO_NATIVE_PATH_LIST _libraryDirsNative_${_config})

        # Triggers test discovery: runs the test executable with the --gtest_list_tests argument during build time.
        # Creates a list of all test suites and test names (without executing their bodies).
        # Parses the list of tests, and adds each one to ctest.
        gtest_discover_tests(TESTS_contacts
            DISCOVERY_MODE PRE_TEST
            CONFIG ${_config}
            PROPERTIES
                ENVIRONMENT "PATH=${_libraryDirsNative_${_config}};$ENV{PATH}" # Without the PATH variable, test discovery can't be performed during build time and build fails.
                LABELS "${_config}"
                # TODO Check if works on all platforms.
        )

        # Tests should be run with "--build-config" flag.
        # Otherwise, the test executable the follwing error occurs:
        # "include could not find requested file: <path_to_the_project>/build/<toolset>/tests/Contacts/TESTS_contacts[1]_include-.cmake".
    endforeach()
else()
    get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${CMAKE_BUILD_TYPE}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    # Triggers test discovery: runs the test executable with the --gtest_list_tests argument during build time.
    # Creates a list of all test suites and test names (without executing their bodies).
    # Parses the list of tests, and adds each one to ctest.
    gtest_discover_tests(TESTS_contacts
        DISCOVERY_MODE PRE_TEST
        PROPERTIES
            ENVIRONMENT "PATH=${_libraryDirsNative};$ENV{PATH}" # Without the PATH variable, test discovery can't be performed during build time and build fails.
            # TODO Check if works on all platforms.
        )
endif()