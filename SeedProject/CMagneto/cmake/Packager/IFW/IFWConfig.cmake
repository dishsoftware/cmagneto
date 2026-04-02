# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

include(CPackIFW)


## Component setup.
cpack_ifw_configure_component(${CMagneto__COMPONENT__RUNTIME}
    NAME "runtime"
    DISPLAY_NAME "${COMPONENT__RUNTIME___NAME}"
        ru "${COMPONENT__RUNTIME___NAME_ru}"
    DESCRIPTION "${COMPONENT__RUNTIME___DESCRIPTION}"
        ru "${COMPONENT__RUNTIME___DESCRIPTION_ru}"
    LICENSES "MIT License" "${CMagneto__PACKAGE_RESOURCES_DIR}/License.txt"
)

cpack_ifw_configure_component(${CMagneto__COMPONENT__DEVELOPMENT}
    NAME "development"
    DISPLAY_NAME "${COMPONENT__DEVELOPMENT___NAME}"
        ru "${COMPONENT__DEVELOPMENT___NAME_ru}"
    DESCRIPTION "${COMPONENT__DEVELOPMENT___DESCRIPTION}"
        ru "${COMPONENT__DEVELOPMENT___DESCRIPTION_ru}"
    DEPENDENCIES "runtime"
    DEFAULT OFF # Do not select "Development" component by default in IFW UI.
)
