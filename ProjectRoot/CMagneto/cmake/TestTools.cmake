# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions and variables for GoogleTest integration.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/TestTools_Internals.cmake")


function(CMagneto__register_test_target iTestTargetName)
    get_property(_registeredTestTargets GLOBAL PROPERTY CMagnetoInternal__RegisteredTestTargets)
    list(APPEND _registeredTestTargets ${iTestTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__RegisteredTestTargets "${_registeredTestTargets}")

    # Set test discovery for the test target.
    CMagnetoInternal__set_test_discovery(${iTestTargetName})
endfunction()