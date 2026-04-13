# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines internal functions and variables for handling 3rd-party shared libraries.
    The implementation is split into smaller internal submodules, but this file remains the stable internal entrypoint.
]]

include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/SharedState_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/Detection_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/RuntimeDependencyOverrides_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/Policy_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/Manifest_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/Runtime_Internals.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ThirdPartySharedLibsTools/HelperScripts_Internals.cmake")
