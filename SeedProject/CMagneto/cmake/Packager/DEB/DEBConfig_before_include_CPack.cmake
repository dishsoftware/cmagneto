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

# Automatically compute shared lib dependencies. dpkg-shlibdeps is required (part of dpkg-dev).
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

list(APPEND CPACK_CUSTOM_INSTALL_VARIABLES "CMagnetoInternal__IS_CPACK_INSTALL=TRUE")
