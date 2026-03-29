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

#[[
    This submodule of the CMagneto module sets up instrumentation (flags of compilers and linkers)
    to generate metadata files for code coverage tools, e.g. GCOV.
]]


option(ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
if(ENABLE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(STATUS "Code coverage enabled")

        # GCC has a shorthand "--coverage" for the option "-fprofile-arcs -ftest-coverage".
        # But it is better to be a more explicit and use more portable option.
        # Arg breakdown:
        # -fprofile-arcs: Instruments control flow arcs (basic block execution tracking).
        #                 I.e. it inserts counters into a compiled binary that record:
        #                 1) How many times each arc is followed;
        #                 2) Which branches were taken and how often.
        # -ftest-coverage: Adds extra data for gcov to analyze line-by-line execution;
        # -O0: Prevents optimizations, ensures accurate mapping between code and coverage;
        # -g: Includes debug info (for line numbers in reports);
        # Adding these to both compile and link stages is necessary for complete functionality.
        CMagneto__is_multiconfig(_isGeneratorMulticonfig)
        if(_isGeneratorMulticonfig)
            add_compile_options(
                $<$<CONFIG:Debug>:-fprofile-arcs>
                $<$<CONFIG:Debug>:-ftest-coverage>
                $<$<CONFIG:Debug>:-O0>
                $<$<CONFIG:Debug>:-g>
            )

            add_link_options(
                $<$<CONFIG:Debug>:-fprofile-arcs>
                $<$<CONFIG:Debug>:-ftest-coverage>
            )
        else()
            if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                add_compile_options(-fprofile-arcs -ftest-coverage -O0 -g)
                add_link_options(-fprofile-arcs -ftest-coverage)
            else()
                CMagnetoInternal__message(WARNING "Code coverage makes sense only with Debug buid type. Ignored.")
            endif()
        endif()
    else()
        CMagnetoInternal__message(WARNING "Code coverage is only supported with GCC/Clang. Ignored.")
    endif()
endif()
