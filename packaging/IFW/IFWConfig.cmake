# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

include(CPackIFW)

set(CPACK_IFW_PACKAGE_NAME "${CMagneto__PACKAGING_JSON__PACKAGE_ID}")
set(CPACK_IFW_PACKAGE_TITLE "${CMagneto__PROJECT_JSON__PROJECT_NAME_FOR_UI} Installer")
set(CPACK_IFW_PACKAGE_PUBLISHER "${CPACK_PACKAGE_VENDOR}")
set(CPACK_IFW_PRODUCT_URL "${CMAKE_PROJECT_HOMEPAGE_URL}")

if(WIN32)
    set(CPACK_IFW_PACKAGE_ICON ${CMAKE_CURRENT_LIST_DIR}/PackageLogo.ico)
# elseif(APPLE)
    # set(CPACK_IFW_PACKAGE_ICON ${CMAKE_CURRENT_LIST_DIR}/PackageLogo.icns)
# elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # CPACK_IFW_PACKAGE_ICON is ignored on Linux.
endif()

set(CPACK_IFW_PACKAGE_WINDOW_ICON ${CMAKE_CURRENT_LIST_DIR}/PackageLogo.png)
set(CPACK_IFW_PACKAGE_LOGO ${CMAKE_CURRENT_LIST_DIR}/PackageLogo.png)


## Component setup.
cpack_ifw_configure_component(${CMagneto__COMPONENT__RUNTIME}
    DISPLAY_NAME "${COMPONENT__RUNTIME___NAME}"
        ru "${COMPONENT__RUNTIME___NAME_ru}"
    DESCRIPTION "${COMPONENT__RUNTIME___DESCRIPTION}"
        ru "${COMPONENT__RUNTIME___DESCRIPTION_ru}"
)

cpack_ifw_configure_component(${CMagneto__COMPONENT__DEVELOPMENT}
    DISPLAY_NAME "${COMPONENT__DEVELOPMENT___NAME}"
        ru "${COMPONENT__DEVELOPMENT___NAME_ru}"
    DESCRIPTION "${COMPONENT__DEVELOPMENT___DESCRIPTION}"
        ru "${COMPONENT__DEVELOPMENT___DESCRIPTION_ru}"
    DEFAULT OFF # Do not select "Development" component by default in IFW UI.
)
