# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines general-purpose functions to simplify integration with CMake generators of build system files.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/GeneratorTools_Internals.cmake")


function(CMagneto__is_multiconfig oIsMulticonfig)
    get_property(_isSet GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG SET)
    if(NOT _isSet)
        CMagnetoInternal__set__IS_MULTTCONFIG__property()
    endif()

    get_property(_isMulticonfig GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG)
    set(${oIsMulticonfig} ${_isMulticonfig} PARENT_SCOPE)
endfunction()