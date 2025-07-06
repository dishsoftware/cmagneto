# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines general-purpose functions to simplify integration with CMake generators of build system files.
]]


#[[
    CMagnetoInternal__set__IS_MULTTCONFIG__property

    Defines CMagnetoInternal__IS_MULTTCONFIG global boolean property as TRUE, if generator supports multi-config, and FALSE otherwise.
    The property should not be accessed or modified directly.
]]
function(CMagnetoInternal__set__IS_MULTTCONFIG__property)
    get_property(_isSet GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG SET)
    if(_isSet)
        return()
    endif()

    if(CMAKE_VERSION VERSION_LESS "3.3.0")
        # Bug https://cmake.org/Bug/view.php?id=15577 .
        if(CMAKE_BUILD_TYPE)
            set_property(GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG FALSE)
        else()
            set_property(GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG TRUE)
        endif()
    else()
        if(CMAKE_CONFIGURATION_TYPES)
            set_property(GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG TRUE)
        else()
            set_property(GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG FALSE)
        endif()
    endif()
endfunction()


# Calling it directly is not necessary, if CMagnetoInternal__IS_MULTTCONFIG is only retrieved using CMagneto__is_multiconfig(oIsMulticonfig).
# However, it is better to invoke this function early to avoid errors if the property is accessed directly against recommendations.
CMagnetoInternal__set__IS_MULTTCONFIG__property()


function(CMagneto__is_multiconfig oIsMulticonfig)
    get_property(_isSet GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG SET)
    if(NOT _isSet)
        CMagnetoInternal__set__IS_MULTTCONFIG__property()
    endif()

    get_property(_isMulticonfig GLOBAL PROPERTY CMagnetoInternal__IS_MULTTCONFIG)
    set(${oIsMulticonfig} ${_isMulticonfig} PARENT_SCOPE)
endfunction()