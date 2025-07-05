# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.


set(CMagnetoPrivate__PROJECT_JSON__PATH "${CMAKE_SOURCE_DIR}/meta/Project.json")
set(CMagnetoPrivate__PACKAGING_JSON__PATH "${CMAKE_SOURCE_DIR}/meta/Packaging.json")


#[[
    CMagneto__parse__project_json

    Parses ./meta/Project.json.

    The function must be called before the project() in the root CMakeLists.txt.
    The parsed values are exported to the parent scope, so they can be used in the top-level CMakeLists.txt.
]]
function(CMagneto__parse__project_json)
    file(READ "${CMagnetoPrivate__PROJECT_JSON__PATH}" PROJECT_JSON_TEXT)

    string(JSON PROJECT_JSON__COMPANY_NAME_LEGAL     GET "${PROJECT_JSON_TEXT}" "CompanyName_LEGAL")
    string(JSON PROJECT_JSON__COMPANY_NAME_FULL      GET "${PROJECT_JSON_TEXT}" "CompanyName_FULL")
    string(JSON PROJECT_JSON__COMPANY_NAME_SHORT     GET "${PROJECT_JSON_TEXT}" "CompanyName_SHORT")
    string(JSON PROJECT_JSON__PROJECT_NAME_BASE      GET "${PROJECT_JSON_TEXT}" "ProjectNameBase")
    string(JSON PROJECT_JSON__PROJECT_NAME_FOR_UI    GET "${PROJECT_JSON_TEXT}" "ProjectNameForUI")
    string(JSON PROJECT_JSON__PROJECT_DESCRIPTION    GET "${PROJECT_JSON_TEXT}" "ProjectDescription")
    string(JSON PROJECT_JSON__PROJECT_HOMEPAGE       GET "${PROJECT_JSON_TEXT}" "ProjectHomepage")
    string(JSON PROJECT_JSON__PROJECT_VERSION        GET "${PROJECT_JSON_TEXT}" "ProjectVersion")

    # Export to parent scope so they're accessible after calling the function.
    set(PROJECT_JSON__COMPANY_NAME_LEGAL     "${PROJECT_JSON__COMPANY_NAME_LEGAL}"     PARENT_SCOPE)
    set(PROJECT_JSON__COMPANY_NAME_FULL      "${PROJECT_JSON__COMPANY_NAME_FULL}"      PARENT_SCOPE)
    set(PROJECT_JSON__COMPANY_NAME_SHORT     "${PROJECT_JSON__COMPANY_NAME_SHORT}"     PARENT_SCOPE)
    set(PROJECT_JSON__PROJECT_NAME_BASE      "${PROJECT_JSON__PROJECT_NAME_BASE}"      PARENT_SCOPE)
    set(PROJECT_JSON__PROJECT_NAME_FOR_UI    "${PROJECT_JSON__PROJECT_NAME_FOR_UI}"    PARENT_SCOPE)
    set(PROJECT_JSON__PROJECT_DESCRIPTION    "${PROJECT_JSON__PROJECT_DESCRIPTION}"    PARENT_SCOPE)
    set(PROJECT_JSON__PROJECT_HOMEPAGE       "${PROJECT_JSON__PROJECT_HOMEPAGE}"       PARENT_SCOPE)
    set(PROJECT_JSON__PROJECT_VERSION        "${PROJECT_JSON__PROJECT_VERSION}"        PARENT_SCOPE)
endfunction()


# Call it immediately along with
#   include("${CMAKE_SOURCE_DIR}/cmake/modules/CMagneto/parse_meta.cmake").
CMagneto__parse__project_json()


#[[
    CMagneto__parse__packaging_json

    Parses ./meta/Packaging.json.

    The function must be called before the project() in the root CMakeLists.txt.
    The parsed values are exported to the parent scope, so they can be used in the top-level CMakeLists.txt.
]]
function(CMagneto__parse__packaging_json)
    # Parse ./meta/packaging.json.
    file(READ "${CMagnetoPrivate__PACKAGING_JSON__PATH}" PACKAGING_JSON_TEXT)

    string(JSON PACKAGING_JSON__PACKAGE_ID          GET "${PACKAGING_JSON_TEXT}" "PackageID")
    string(JSON PACKAGING_JSON__PACKAGE_NAME_PREFIX GET "${PACKAGING_JSON_TEXT}" "PackageNamePrefix")
    string(JSON PACKAGING_JSON__PACKAGE_MAINTAINER  GET "${PACKAGING_JSON_TEXT}" "PackageMaintainer")

    # Export to parent scope so they're accessible after calling the function.
    set(PACKAGING_JSON__PACKAGE_ID          "${PACKAGING_JSON__PACKAGE_ID}"          PARENT_SCOPE)
    set(PACKAGING_JSON__PACKAGE_NAME_PREFIX "${PACKAGING_JSON__PACKAGE_NAME_PREFIX}" PARENT_SCOPE)
    set(PACKAGING_JSON__PACKAGE_MAINTAINER  "${PACKAGING_JSON__PACKAGE_MAINTAINER}"  PARENT_SCOPE)
endfunction()
