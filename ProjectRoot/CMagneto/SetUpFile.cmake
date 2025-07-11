# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions and variables for generation and installation of arbitrary files.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/SetUpFile_Internals.cmake")