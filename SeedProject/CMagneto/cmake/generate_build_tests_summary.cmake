# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

if(TEST_TARGETS)
    file(WRITE "${FILE_PATH}" "Built test targets:\n")
    foreach(_target IN LISTS TEST_TARGETS)
        file(APPEND "${FILE_PATH}" "${_target}\n")
    endforeach()
else()
    file(WRITE "${FILE_PATH}" "No test targets were found.\n")
endif()

string(TIMESTAMP _targetCompilationFinishTime "%Y-%m-%d %H:%M:%S" UTC)
file(APPEND "${FILE_PATH}" "Compilation of test targets finished at: ${_targetCompilationFinishTime} UTC\n")