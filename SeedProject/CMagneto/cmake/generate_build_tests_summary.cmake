# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

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