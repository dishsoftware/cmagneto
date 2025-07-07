# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines internal general-purpose functions and constants for platform handling.
]]


# Platform-dependent script extensions.
set(CMagnetoInternal__SCRIPT_EXTENSION_UNIX "sh")
set(CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS "bat")

# Platfrom-dependent script name suffixes.
set(CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX "_Unix")
set(CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS "_Windows")