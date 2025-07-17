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

#[[
    This submodule of the CMagneto module defines internal functions and variables for generation and installation of arbitrary files.
]]


# Define constants.
include("${CMAKE_CURRENT_LIST_DIR}/Constants.cmake")


#[[
    CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE

    Places to build directory and installs to ${CMagneto__SUBDIR_EXECUTABLE} a file with name and content,
    which are returned by fileNameGetter(oFileName) and contentGetter(iConfig oContent) functions.
    If a generator supports multi-config, temporary files are generated for every configuration (Debug, Release, etc.) during
    configure/generation time and copied to ${CMagneto__SUBDIR_EXECUTABLE} during build of corresponding $<CONFIG>.
    oFileName - is also a name of an utility target (created within the function) that depends on the output file, if multi-config generator is used.
    It must not contain characters that are not allowed in target names; dots are replaced with underscores.

    parameters:
        iAddExePermission - if TRUE, the file is given execute permission (Unix only).
        iInstall - if TRUE, the file is installed to ${CMagneto__SUBDIR_EXECUTABLE}.
        iComponentName - name of the component to which the file is installed.
            If iInstall is FALSE, this parameter is ignored.
]]
function(CMagnetoInternal__set_up_file_into_SUBDIR_EXECUTABLE iFileNameGetterName iContentGetterName iAddExePermission iInstall iComponentName)
    CMagneto__is_multiconfig(IS_MULTICONFIG)
    set(_TMP_FILE_DIR "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_TMP}")
    cmake_language(CALL ${iFileNameGetterName} _fileName)

    if(IS_MULTICONFIG)
        foreach(_config ${CMAKE_CONFIGURATION_TYPES})
            cmake_language(CALL ${iContentGetterName} "${_config}" _fileContent)

            # Write contents to temporary files at configure time to copy them lately at build time.
            # Reason: there is no way to write $<CONFIG>-dependent generic contents to files at build time,
            # because CMake treats, for example, commas in JSONs as delimiters between arguments of generator expressions.
            # UPDATE: It is probably possible to escape commas with $<COMMA> (and other generator expression special characters) in contents.
            file(WRITE "${_TMP_FILE_DIR}/${_config}/${_fileName}" "${_fileContent}")
        endforeach()

        # Add a command to copy the file at build time.
        set(_filePath "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/$<CONFIG>/${_fileName}")
        set(_tmpFilePath "${_TMP_FILE_DIR}/$<CONFIG>/${_fileName}")

        set(_commands COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_tmpFilePath}" "${_filePath}")

        if(UNIX AND iAddExePermission)
            list(APPEND _commands COMMAND ${CMAKE_COMMAND} -E chmod +x "${_filePath}")
        endif()

        add_custom_command(
            OUTPUT "${_filePath}"
            ${_commands}
            DEPENDS "${_tmpFilePath}"
            COMMENT "Generating \"${_fileName}\" for config $<CONFIG>."
        )

        # Add an utility (phony) target that depends on the output file.
        string(REPLACE "." "_" _targetName "${_fileName}")
        add_custom_target(${_targetName} ALL
            DEPENDS "${_filePath}"
        )
    else()
        cmake_language(CALL ${iFileNameGetterName} _fileName)
        cmake_language(CALL ${iContentGetterName} "${CMAKE_BUILD_TYPE}" _fileContent)
        set(_filePath "${CMAKE_BINARY_DIR}/${CMagneto__SUBDIR_EXECUTABLE}/${_fileName}")

        # Add the file to build dir(s) at configire time.
        file(WRITE "${_filePath}" "${_fileContent}")
        if (UNIX AND iAddExePermission)
            execute_process(COMMAND chmod u+x "${_filePath}")
        endif()
    endif()

    # Install the file.
    if(iInstall)
        if(iComponentName)
            if(UNIX AND iAddExePermission)
            # Maybe, it is better to use USE_SOURCE_PERMISSIONS.
            # Explicit setting of permissions only provide a bit of additional security.
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    COMPONENT "${iComponentName}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        else()
            if(UNIX AND iAddExePermission)
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                )
            else()
                install(
                    FILES "${_filePath}"
                    DESTINATION "${CMagneto__SUBDIR_EXECUTABLE}"
                    PERMISSIONS OWNER_READ OWNER_WRITE
                )
            endif()
        endif()
    endif()
endfunction()