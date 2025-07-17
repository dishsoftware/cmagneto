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

# Generates separate .deb packages for each CMake component defined in the project.
# set(CPACK_DEB_COMPONENT_INSTALL ON)

# Maintainer field in the Debian control file.
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CMagneto__PACKAGING_JSON__PACKAGE_MAINTAINER}")

# Purpose of the software as a logical category within the Debian package ecosystem.
set(CPACK_DEBIAN_PACKAGE_SECTION "utils")

# Defines the Priority: field in the Debian control file,
# which gives an indication of the package’s importance or necessity within the Debian system.
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")

set(CPACK_DEBIAN_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
set(CPACK_DEBIAN_COMPRESSION_TYPE "xz")

# Manually set dependencies.
# set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.27), libqt5core5a (>= 5.15)")

# Filename format.
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)  # Default naming, e.g. "project-version-arch.deb".
