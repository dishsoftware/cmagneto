# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

enable_testing()

find_package(GTest CONFIG QUIET)

if(NOT GTest_FOUND)
    include(FetchContent)

    # Prevent bundled GTest from being installed.
    set(INSTALL_GTEST OFF)

    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/52eb8108c5bdec04579160ae17225d66034bd723.zip # v1.17.0
    )

    FetchContent_MakeAvailable(googletest)
endif()

include(GoogleTest)

option(
    CMagneto__ENABLE_CPP_NATIVE_TESTS
    "Compile native tests from ./CMagneto/cpp/tests/ as part of the project's native test suite."
    OFF
)

if(CMagneto__ENABLE_CPP_NATIVE_TESTS)
    add_subdirectory(
        "${CMAKE_SOURCE_DIR}/CMagneto/cpp/tests"
        "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_TESTS_NATIVE}/CMagneto/cpp"
        EXCLUDE_FROM_ALL
    )
endif()

add_subdirectory("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")
