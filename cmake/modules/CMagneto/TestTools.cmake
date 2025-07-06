# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This submodule of the CMagneto module defines functions for GoogleTest integration.
]]


#[[
    CMagnetoInternal__set_test_discovery

    Sets test discovery after build time and just before execution of test bodies.

    The function must be called after include(GoogleTest).
    If the function is not called, test discovery may be started during build time,
    and if paths to 3rd-party shared libraries are not set, build will fail.
]]
function(CMagnetoInternal__set_test_discovery iTestTargetName)
    # Triggers test discovery: runs the test executable with the --gtest_list_tests argument after build time just before execution of test bodies.
    # Creates a list of all test suites and test names (without executing their bodies).
    # Parses the list of tests, and adds each one to ctest.
    gtest_discover_tests(${iTestTargetName}
        DISCOVERY_MODE PRE_TEST # Not using of DISCOVERY_MODE POST_BUILD allows to not add ENVIRONMENT argument which is $<CONFIG>-dependent.
    )
endfunction()


# Appended every time CMagneto__register_test_target(iTestTargetName) is called.
set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS "")


function(CMagneto__register_test_target iTestTargetName)
    get_property(_registeredTestTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS)
    list(APPEND _registeredTestTargets ${iTestTargetName})
    set_property(GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS "${_registeredTestTargets}")

    # Set test discovery for the test target.
    CMagnetoInternal__set_test_discovery(${iTestTargetName})
endfunction()


set(CMagnetoInternal__GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH "${CMAKE_CURRENT_LIST_DIR}/generate_build_tests_summary.cmake")


#[[
    CMagnetoInternal__add__build_tests__target

    Creates "build_tests" target that depends on all registered test targets.
    Allows to build all tests with a single command, e.g.: "cmake --build . --target build_tests".
]]
function(CMagnetoInternal__add__build_tests__target)
    get_property(_registeredTestTargets GLOBAL PROPERTY CMagnetoInternal__REGISTERED_TEST_TARGETS)
    if(NOT DEFINED _registeredTestTargets OR _registeredTestTargets STREQUAL "")
        CMagnetoInternal__message(STATUS "CMagnetoInternal__add__build_tests__target: No registered test targets.")
    endif()

    set(_fileDir "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_SUMMARY}")

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_filePath "${_fileDir}/$<CONFIG>/${CMagneto__TEST_BUILD_SUMMARY__FILE_NAME}")
        set(_buildType $<CONFIG>)
    else()
        set(_filePath "${_fileDir}/${CMagneto__TEST_BUILD_SUMMARY__FILE_NAME}")
    endif()

    # Add a target that depends on all registered test targets.
    add_custom_target(build_tests
        DEPENDS ${_registeredTestTargets}
        COMMENT "Compiling tests."
    )

    # The file is used by "build.py" to determine whether tests are compiled.
    add_custom_command(
        TARGET build_tests POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            -DFILE_PATH="${_filePath}"
            -DTEST_TARGETS="${_registeredTestTargets}"
            -P "${CMagnetoInternal__GENERATE_TEST_BUILD_SUMMARY__SCRIPT_PATH}"
        COMMENT "Composing ${CMagneto__TEST_BUILD_SUMMARY__FILE_NAME}"
    )
endfunction()


set(CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}__TEMPLATE")


#[[
    CMagnetoInternal__generate__run_tests__script_content

    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after CMagnetoInternal__set_up__set_env__script() is called.
]]
function(CMagnetoInternal__generate__run_tests__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(DIR_WITH_CTESTTESTFILE "param\\nDIR_WITH_CTESTTESTFILE\\nparam")
    set(BUILD_CONFIG "param\\nBUILD_CONFIG\\nparam")
    set(REPORT_PATH "param\\nREPORT_PATH\\nparam")
    ####################################################################

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_WINDOWS}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${CMagnetoInternal__RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${CMagnetoInternal__SCRIPT_NAME_SUFFIX_UNIX}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}")
    endif()

    CMagneto__is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_dirWithCtestTestFile "../../${CMagneto__SUBDIR_TESTS}")
        set(_reportPath "../../${CMagneto__SUBDIR_SUMMARY}/${iBuildType}/${CMagneto__TEST_REPORT__FILE_NAME}")
    else()
        set(_dirWithCtestTestFile "../${CMagneto__SUBDIR_TESTS}")
        set(_reportPath "../${CMagneto__SUBDIR_SUMMARY}/${CMagneto__TEST_REPORT__FILE_NAME}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${DIR_WITH_CTESTTESTFILE}" "${_dirWithCtestTestFile}" _scriptContent "${_scriptContent}")
    string(REPLACE "${BUILD_CONFIG}" "${iBuildType}" _scriptContent "${_scriptContent}")
    string(REPLACE "${REPORT_PATH}" "${_reportPath}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


function(CMagnetoInternal__get__run_tests__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${CMagneto__RUN_TESTS__SCRIPT_NAME_WE}.${CMagnetoInternal__SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    CMagnetoInternal__set_up__run_tests__script

    Generates, places to build directory and installs "run_tests" script.
    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after CMagnetoInternal__set_up__set_env__script() is called.
    If the function is not called, "build.py" will not be able to run tests: "build.py" calls "run_tests" scripts.
]]
function(CMagnetoInternal__set_up__run_tests__script)
    CMagnetoInternal__set_up_file("CMagnetoInternal__get__run_tests__script_file_name" "CMagnetoInternal__generate__run_tests__script_content" TRUE FALSE ${CMagneto__COMPONENT__BUILD_MACHINE_SPECIFIC})
endfunction()