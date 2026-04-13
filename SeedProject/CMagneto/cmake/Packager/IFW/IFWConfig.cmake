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

include(CPackIFW)
include("${CMAKE_CURRENT_LIST_DIR}/IFWScriptSupport.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/IFWLicenseSupport.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/IFWShortcutSupport.cmake")

cmake_path(SET _ifwLicenseBundleWidgetUi NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/IFW/LicenseBundleWidget.ui")
CMagnetoInternal__ifw__generate_license_page_component_script_text(_ifwLicensePageScriptText)
CMagnetoInternal__ifw__generate_windows_shortcut_component_script_text(_ifwShortcutScriptText)

set(_ifwRuntimeComponentScriptText "")
if(NOT _ifwLicensePageScriptText STREQUAL "")
    string(APPEND _ifwRuntimeComponentScriptText "${_ifwLicensePageScriptText}")
endif()

if(NOT _ifwShortcutScriptText STREQUAL "")
    if(_ifwRuntimeComponentScriptText STREQUAL "")
        string(APPEND _ifwRuntimeComponentScriptText "function Component()\n{\n}\n\n")
    else()
        string(APPEND _ifwRuntimeComponentScriptText "\n\n")
    endif()
    string(APPEND _ifwRuntimeComponentScriptText "${_ifwShortcutScriptText}")
endif()

CMagnetoInternal__ifw__write_runtime_component_script("${_ifwRuntimeComponentScriptText}" _ifwGeneratedRuntimeComponentScript)

cpack_ifw_configure_component(${CMagneto__COMPONENT__RUNTIME}
    NAME "runtime"
    DISPLAY_NAME "${COMPONENT__RUNTIME___NAME}"
        ru "${COMPONENT__RUNTIME___NAME_ru}"
    DESCRIPTION "${COMPONENT__RUNTIME___DESCRIPTION}"
        ru "${COMPONENT__RUNTIME___DESCRIPTION_ru}"
    USER_INTERFACES "${_ifwLicenseBundleWidgetUi}"
    SCRIPT "${_ifwGeneratedRuntimeComponentScript}"
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
