# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)

#[[
    This submodule of the CMagneto module defines logging functions and associated log level variables.
]]


# Load internals of the submodule.
include("${CMAKE_CURRENT_LIST_DIR}/Logger_Internals.cmake")


#[[
    CMagneto__message

    If the current CMAKE_MESSAGE_LOG_LEVEL >= iMessageLogLevel,
    logs iText with iMessagePrefix colored with an appropriate to iMessageLogLevel color.

    Notes:
    - It would be more convenient to read warnings and errors if CMagneto__message was a macro instead of a function,
      but that would pollute the caller’s namespace with internal temporary variables.
]]
function(CMagneto__message iMessageLogLevel iMessagePrefix iText)
    CMagnetoInternal__get_message_log_level_idx("${iMessageLogLevel}" _messageLogLevel_idx)
    CMagnetoInternal__make_colored_as_log_level_idx("${iMessagePrefix} ${iText}" ${_messageLogLevel_idx} oColoredText)
    message(${iMessageLogLevel} "${oColoredText}")
endfunction()


#[[
    CMagneto__wrap_strings_and_join

    Wraps each string from iStrings as {iBra}{string}{iKet}, and joins them with iDelimiter.
]]
function(CMagneto__wrap_strings_and_join oString iBra iKet iDelimiter iStrings)
    set(_quotedStrings "")
    foreach(_string IN LISTS iStrings)
        string(APPEND _quotedStrings "${iBra}${_string}${iKet}")
    endforeach()

    string(JOIN "${iDelimiter}" _joined "${_quotedStrings}")
    set(${oString} "${_joined}" PARENT_SCOPE)
endfunction()


function(CMagneto__wrap_strings_in_quotes_and_join oString iDelimiter iStrings)
    CMagneto__wrap_strings_and_join(oString "\"" "\"" "${iDelimiter}" "${iStrings}")
    set(${oString} "${oString}" PARENT_SCOPE)
endfunction()