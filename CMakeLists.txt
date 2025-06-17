set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

cmake_minimum_required(VERSION 3.28) # The oldest version of CMake (on Ubuntu 24 LTS) among the platforms supported by the project.

# Parse ./meta/project.json.
file(READ "${CMAKE_SOURCE_DIR}/meta/Project.json" PROJECT_JSON_TEXT)
string(JSON PROJECT_JSON__COMPANY_NAME_LEGAL GET "${PROJECT_JSON_TEXT}" "CompanyName_LEGAL")
string(JSON PROJECT_JSON__COMPANY_NAME_FULL GET "${PROJECT_JSON_TEXT}" "CompanyName_FULL")
string(JSON PROJECT_JSON__COMPANY_NAME_SHORT GET "${PROJECT_JSON_TEXT}" "CompanyName_SHORT")
string(JSON PROJECT_JSON__PROJECT_NAME_BASE GET "${PROJECT_JSON_TEXT}" "ProjectNameBase")
string(JSON PROJECT_JSON__PROJECT_DESCRIPTION GET "${PROJECT_JSON_TEXT}" "ProjectDescription")
string(JSON PROJECT_JSON__PROJECT_HOMEPAGE GET "${PROJECT_JSON_TEXT}" "ProjectHomepage")
string(JSON PROJECT_JSON__PROJECT_VERSION GET "${PROJECT_JSON_TEXT}" "ProjectVersion")


project("${PROJECT_JSON__COMPANY_NAME_SHORT}_${PROJECT_JSON__PROJECT_NAME_BASE}"
    DESCRIPTION "${PROJECT_JSON__PROJECT_DESCRIPTION}"
    HOMEPAGE_URL "${PROJECT_JSON__PROJECT_HOMEPAGE}"
    VERSION "${PROJECT_JSON__PROJECT_VERSION}"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON) # GoogleTest requires at least C++17.


# Include custom CMake modules.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules") # Search of modules in directories from CMAKE_MODULE_PATH is not recursive.
include(SetUpTargets)

print_platform_and_compiler()
set__IS_MULTTCONFIG__property()


add_subdirectory(src)

set_up_project()
set_up__3rd_party_shared_libs__list()
set_up__set_env__script()
set_up__env_vscode__file()
set_up__run__script()
set_up__run_tests__script()
set_up__build_summary__file()


add_subdirectory(tests EXCLUDE_FROM_ALL) # Exclude tests from the default build target, so they are not built unless explicitly requested.
add__build_tests__target()


# The project only tries to define packaging if it is the top level project.
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
    include(${CMAKE_CURRENT_SOURCE_DIR}/packaging/CPackConfig.cmake)
endif()