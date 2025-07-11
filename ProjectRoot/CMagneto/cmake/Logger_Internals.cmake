# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

include_guard(GLOBAL)

#[[
    This submodule of the CMagneto module defines internal logging functions and associated log level variables.
]]


# Set up CMagneto CMake module logging.
## Define default CMagneto__MESSAGE_LOG_LEVEL variable.
set(CMagneto__MESSAGE_LOG_LEVEL "${CMAKE_MESSAGE_LOG_LEVEL}"
    CACHE STRING "CMagneto log level. Allows to enable more verbose, than CMAKE_MESSAGE_LOG_LEVEL, output from CMagnetoInternal__message(), without affecting output of message()."
)

## The set of levels must be a subset of the CMAKE_MESSAGE_LOG_LEVEL values (modes) with a preserved order (descending severity).
## See https://cmake.org/cmake/help/latest/command/message.html .
set(CMagnetoInternal__MESSAGE_LOG_LEVELS
    FATAL_ERROR SEND_ERROR WARNING AUTHOR_WARNING DEPRECATION NOTICE STATUS VERBOSE DEBUG TRACE
)

## NOTE! The link above is lying about NOTICE and empty string (default) being the same level. In reality, STATUS and empty string are the same level.
set(CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT "STATUS")

## Limit GUI options of CMagneto__MESSAGE_LOG_LEVEL.
set_property(CACHE CMagneto__MESSAGE_LOG_LEVEL PROPERTY STRINGS ${CMagnetoInternal__MESSAGE_LOG_LEVELS})


# ANSI color codes.
string(ASCII 27 ANSI_ESCAPE_CHAR)  # 27 = ESCAPE character.

set(ANSI_COLOR_CODE__BLACK   "${ANSI_ESCAPE_CHAR}[30m")
set(ANSI_COLOR_CODE__RED     "${ANSI_ESCAPE_CHAR}[31m")
set(ANSI_COLOR_CODE__GREEN   "${ANSI_ESCAPE_CHAR}[32m")
set(ANSI_COLOR_CODE__YELLOW  "${ANSI_ESCAPE_CHAR}[33m")
set(ANSI_COLOR_CODE__BLUE    "${ANSI_ESCAPE_CHAR}[34m")
set(ANSI_COLOR_CODE__MAGENTA "${ANSI_ESCAPE_CHAR}[35m")
set(ANSI_COLOR_CODE__CYAN    "${ANSI_ESCAPE_CHAR}[36m")
set(ANSI_COLOR_CODE__WHITE   "${ANSI_ESCAPE_CHAR}[37m")
set(ANSI_COLOR_CODE__RESET   "${ANSI_ESCAPE_CHAR}[0m")

set(ANSI_COLOR_CODES
    ${ANSI_COLOR_CODE__BLACK}
    ${ANSI_COLOR_CODE__RED}
    ${ANSI_COLOR_CODE__GREEN}
    ${ANSI_COLOR_CODE__YELLOW}
    ${ANSI_COLOR_CODE__BLUE}
    ${ANSI_COLOR_CODE__MAGENTA}
    ${ANSI_COLOR_CODE__CYAN}
    ${ANSI_COLOR_CODE__WHITE} # Reset code is always the last one.
)


#[[
    CMagneto__make_colored

    Makes iText colored with iANSIColorCode.
    Returns oColoredText.
]]
function(CMagneto__make_colored iText iANSIColorCode oColoredText)
    # list(FIND ...) does not behave as expected when the list elements are complex strings, such as ANSI escape sequences.
    # It fails to find a match, returning -1, even when the string looks identical.
    # list(FIND ANSI_COLOR_CODES "${iANSIColorCode}" _colorIdx)
    # if(_colorIdx EQUAL -1)
    #    CMagnetoInternal__message(WARNING "CMagneto__make_colored: Invalid ANSI color code. Returning iText without color.")
    #    set(oColoredText "${iText}" PARENT_SCOPE)
    #    return()
    # endif()
    set(${oColoredText} "${iANSIColorCode}${iText}${ANSI_COLOR_CODE__RESET}" PARENT_SCOPE)
endfunction()


# Define constants with indices of the log levels in the CMagnetoInternal__MESSAGE_LOG_LEVELS list to reduce the number of calls to list(FIND) in the code.
foreach(_level IN LISTS CMagnetoInternal__MESSAGE_LOG_LEVELS)
    list(FIND CMagnetoInternal__MESSAGE_LOG_LEVELS "${_level}" _idx)
    set(_constName "CMagnetoInternal__MESSAGE_LOG_LEVELS__${_level}_idx")
    set(${_constName} ${_idx})
endforeach()
list(FIND CMagnetoInternal__MESSAGE_LOG_LEVELS "${CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT}" CMagneto__MESSAGE_LOG_LEVEL__DEFAULT_idx)
if(CMagneto__MESSAGE_LOG_LEVEL__DEFAULT_idx EQUAL -1)
    CMagnetoInternal__message(FATAL_ERROR "Invalid logics in CMagneto CMake module: CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT must be equal to one of strings from CMagnetoInternal__MESSAGE_LOG_LEVELS.")
endif()


#[[
    CMagnetoInternal__make_colored_as_log_level_idx

    Makes iText colored according to the iMessageLogLevelIdx.
    Returns oColoredText.
]]
function(CMagnetoInternal__make_colored_as_log_level_idx iText iMessageLogLevelIdx oColoredText)
    if (iMessageLogLevelIdx LESS_EQUAL CMagnetoInternal__MESSAGE_LOG_LEVELS__SEND_ERROR_idx)
        CMagneto__make_colored("${iText}" "${ANSI_COLOR_CODE__RED}" _coloredText)
    elseif (iMessageLogLevelIdx LESS_EQUAL CMagnetoInternal__MESSAGE_LOG_LEVELS__DEPRECATION_idx)
        CMagneto__make_colored("${iText}" "${ANSI_COLOR_CODE__YELLOW}" _coloredText)
    elseif (iMessageLogLevelIdx LESS_EQUAL CMagnetoInternal__MESSAGE_LOG_LEVELS__VERBOSE_idx)
        CMagneto__make_colored("${iText}" "${ANSI_COLOR_CODE__GREEN}" _coloredText)
    else()
        set(_coloredText "${iText}")
    endif()

    set(${oColoredText} "${_coloredText}" PARENT_SCOPE)
endfunction()


#[[
    CMagnetoInternal__get_message_log_level_idx

    Returns oMessageLogLevelIdx - the index of the iMessageLogLevel in the CMagnetoInternal__MESSAGE_LOG_LEVELS list.
    If iMessageLogLevel is empty, returns the index of CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT.
    If iMessageLogLevel is invalid, warns and returns the index of CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT.
]]
function(CMagnetoInternal__get_message_log_level_idx iMessageLogLevel oMessageLogLevelIdx)
    if(iMessageLogLevel STREQUAL "")
        set(${oMessageLogLevelIdx} "${CMagneto__MESSAGE_LOG_LEVEL__DEFAULT_idx}" PARENT_SCOPE)
    else()
        list(FIND CMagnetoInternal__MESSAGE_LOG_LEVELS "${iMessageLogLevel}" _foundIdx)
        if (_foundIdx EQUAL -1)
            set(_msgTemplate [=[
CMagnetoInternal__get_message_log_level_idx: Invalid iMessageLogLevel: "${iMessageLogLevel}"".
Returning index of ${CMagnetoInternal__MESSAGE_LOG_LEVEL__DEFAULT}.
            ]=])

            string(CONFIGURE "${_msgTemplate}" _msg)
            CMagnetoInternal__message(WARNING "${_msg}")

            set(${oMessageLogLevelIdx} "${CMagneto__MESSAGE_LOG_LEVEL__DEFAULT_idx}" PARENT_SCOPE)
        else()
            set(${oMessageLogLevelIdx} "${_foundIdx}" PARENT_SCOPE)
        endif()
    endif()
endfunction()


set(CMagnetoInternal__MESSAGE_PREFIX "[CMagneto]")


#[[
    CMagnetoInternal__message

    If the current CMAKE_MESSAGE_LOG_LEVEL >= iMessageLogLevel or CMagneto__MESSAGE_LOG_LEVEL >= iMessageLogLevel,
    logs iText with iMessagePrefix colored with an appropriate to iMessageLogLevel color.

    Notes:
    - It would be more convenient to read warnings and errors if CMagnetoInternal__message was a macro instead of a function,
      but that would pollute the caller’s namespace with internal temporary variables.
]]
function(CMagnetoInternal__message iMessageLogLevel iText)
    CMagnetoInternal__get_message_log_level_idx("${iMessageLogLevel}" _messageLogLevel_idx)
    CMagnetoInternal__get_message_log_level_idx("${CMagneto__MESSAGE_LOG_LEVEL}" _MESSAGE_LOG_LEVEL_idx)
    CMagnetoInternal__get_message_log_level_idx("${CMAKE_MESSAGE_LOG_LEVEL}" _CMAKE_MESSAGE_LOG_LEVEL_idx)

    if (_MESSAGE_LOG_LEVEL_idx       LESS _messageLogLevel_idx AND
        _CMAKE_MESSAGE_LOG_LEVEL_idx LESS _messageLogLevel_idx)
        return()
    endif()

    CMagnetoInternal__make_colored_as_log_level_idx("${CMagnetoInternal__MESSAGE_PREFIX} ${iText}" ${_messageLogLevel_idx} oColoredText)
    set(CMAKE_MESSAGE_LOG_LEVEL "${iMessageLogLevel}")
    message(${iMessageLogLevel} "${oColoredText}")
endfunction()