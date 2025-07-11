# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Make sure OUT variable is passed
if(NOT DEFINED OUT)
    message(FATAL_ERROR "Missing required variable: OUT")
endif()

set(_summaryText "")
string(APPEND _summaryText "Build Summary\n")
string(APPEND _summaryText "==============\n")
string(APPEND _summaryText "System: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_VERSION}\n")
string(APPEND _summaryText "CMake Generator: ${CMAKE_GENERATOR}\n")
string(APPEND _summaryText "C++ Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}\n")
string(APPEND _summaryText "C++ Compiler path: ${CMAKE_CXX_COMPILER}\n")
string(APPEND _summaryText "Build Type: ${CMAKE_BUILD_TYPE}\n") # If multi-config generator, the variable must be passed during build (compilation) time and equal to $<CONFIG>.

string(TIMESTAMP _targetCompilationFinishTime "%Y-%m-%d %H:%M:%S" UTC)
string(APPEND _summaryText "Compilation of targets (test targets are not considered) finished at: ${_targetCompilationFinishTime} UTC\n")

file(WRITE "${OUT}" "${_summaryText}")