# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

enable_testing()

include(FetchContent)

# Prevent GTest from being installed.
set(INSTALL_GTEST OFF)

FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/52eb8108c5bdec04579160ae17225d66034bd723.zip # v1.17.0
)
# For Windows: Prevent overriding project's compiler/linker settings.
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(googletest)
include(GoogleTest)

add_subdirectory("${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}/${CMagneto__PROJECT_JSON__PROJECT_NAME_BASE}")