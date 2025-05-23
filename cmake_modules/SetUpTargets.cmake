include_guard(GLOBAL)  # Ensures this file is included only once.

#[[
    This file contains functions and variables to set up targets, install them and generate scripts and auxilliary files.
    Dictionary:
        - configure time:
            CMake processes the top-level CMakeLists.txt and all subdirectories to understand your project structure, options, and dependencies.
        - generation time:
            CMake generates the build system files (e.g., Makefiles, Visual Studio project files) based on the configuration.
            Dependencies and build rules are created.
        - build time:
            CMake builds the project using the generated build system files.
            This is when the actual compilation and linking of the code happens.
        - install time:
            CMake installs the built targets to the specified locations.
            This is when the final binaries, libraries, and resources are copied to their installation directories.

        Whenever a "target" is mentioned without additinal context, it means a target created in the project using add_library() or add_executable().
]]


include(CMakePackageConfigHelpers)


set(SUBDIR_STATIC "lib")
set(SUBDIR_SHARED "lib")
set(SUBDIR_EXECUTABLE "bin")
set(SUBDIR_INCLUDE "include")
set(SUBDIR_CMAKE "lib/cmake")
set(SUBDIR_RESOURCES "resources")
set(SUBDIR_TMP "TMP")
set(SUBDIR_CTESTTESTFILE "tests")


set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_STATIC}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_SHARED}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}")

# These postfixes do not affect on executable target output names.
set(CMAKE_DEBUG_POSTFIX "_D")
set(CMAKE_RELWITHDEBINFO_POSTFIX "_RDI")
set(CMAKE_MINSIZEREL_POSTFIX "_MSR")

function(compose_binary_OUTPUT_NAME iTargetName oBinaryOutputName)
    set(${oBinaryOutputName} "${PROJECT_NAME}${CMAKE_PROJECT_VERSION_MAJOR}_${iTargetName}" PARENT_SCOPE)
endfunction()



function(print_platform_and_compiler)
    message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
    message(STATUS "Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
    message(STATUS "Compiler Path: ${CMAKE_CXX_COMPILER}")
endfunction()


#[[
    set__IS_MULTTCONFIG__property

    Defines IS_MULTTCONFIG global boolean property as TRUE, if generator supports multi-config, and FALSE otherwise.
    Calling it directly is not necessary, if IS_MULTTCONFIG is only retrieved using is_multiconfig(oIsMulticonfig).
    However, it is better to call it as early as possible to avoid errors,
    if get_property(oIsMulticonfig GLOBAL PROPERTY IS_MULTTCONFIG) is used and called earlier, than is_multiconfig(oIsMulticonfig).
]]
function(set__IS_MULTTCONFIG__property)
    get_property(_isSet GLOBAL PROPERTY IS_MULTTCONFIG SET)
    if(_isSet)
        return()
    endif()

    if(CMAKE_VERSION VERSION_LESS "3.3.0")
        # Bug https://cmake.org/Bug/view.php?id=15577 .
        if(CMAKE_BUILD_TYPE)
            message(DEBUG "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        else()
            message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        endif()
    else()
        if(CMAKE_CONFIGURATION_TYPES)
            message(DEBUG "Multi-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG TRUE)
        else()
            message(DEBUG "Single-configuration generator")
            set_property(GLOBAL PROPERTY IS_MULTTCONFIG FALSE)
        endif()
    endif()
endfunction()


function(is_multiconfig oIsMulticonfig)
    get_property(_isSet GLOBAL PROPERTY IS_MULTTCONFIG SET)
    if(NOT _isSet)
        set__IS_MULTTCONFIG__property()
    endif()

    get_property(_isMulticonfig GLOBAL PROPERTY IS_MULTTCONFIG)
    set(${oIsMulticonfig} ${_isMulticonfig} PARENT_SCOPE)
endfunction()


include(${CMAKE_CURRENT_LIST_DIR}/QtWrappers.cmake)


# Appended every time set_up_library(iLibName) or set_up_executable(iExeName) is called.
set_property(GLOBAL PROPERTY REGISTERED_TARGETS "")


#[[
    check_target_name_validity

    Checks if a target name is valid and not already registered. Registered target names are compared case-insensitively.
    Valid target names:
        * must start with a letter or underscore;
        * must contain only letters, digits, and underscores;
        * must not be made only of underscores.
]]
function(check_target_name_validity iTargetName)
    # Reject names made only of underscores
    string(REGEX MATCH "^_+$" _only_underscores "${iTargetName}")
    if(_only_underscores)
        message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must not be composed only of underscores.")
    endif()

    string(REGEX MATCH "^[a-zA-Z_][a-zA-Z0-9_]*$" _isValid "${iTargetName}")
    if(NOT _isValid)
        message(FATAL_ERROR "Target name \"${iTargetName}\" is invalid. It must start with a letter or underscore and contain only letters, digits, and underscores.")
    endif()

    # Check if the target name is already registered.
    string(TOUPPER "${iTargetName}" _targetNameUC)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    foreach(_registeredTarget IN LISTS _registeredTargets)
        string(TOUPPER "${_registeredTarget}" _registeredTargetUC)
        if(_targetNameUC STREQUAL _registeredTargetUC)
            if(iTargetName STREQUAL _registeredTarget)
                message(FATAL_ERROR "Target name \"${iTargetName}\" is already registered.")
            else()
                message(FATAL_ERROR "Target name \"${iTargetName}\" conflicts with previosly registered \"${_registeredTarget}\".")
            endif()
        endif()
    endforeach()
endfunction()


#[[
    add_path_to_shared_libs

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    iPath - path to a binary of a shared lib, which iTargetName is linked to.
]]
function(add_path_to_shared_libs iTargetName iBuildType iPath)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    if(NOT _paths)
        set(_paths "")
    endif()

    list(APPEND _paths ${iPath})
    list(REMOVE_DUPLICATES _paths)

    set_property(GLOBAL PROPERTY "${_propName}" "${_paths}")
endfunction()


#[[
    get_paths_to_shared_libs

    Returns paths to binaries of shared libraries, which iTargetName is linked to.

    Parameters:
    iTargetName - name of a target created in the project.

    iBuildType - build type (e.g. Debug, Release, etc.). To get non-build-type-specific paths, set it to "NonSpecific". Case doesn't matter.

    Paths to shared libs for iTargetName are filled when set_up_library(iTargetName) or set_up_executable(iTargetName) are called.
]]
function(get_paths_to_shared_libs iTargetName iBuildType oPaths)
    string(TOUPPER "${iBuildType}" _buildType)
    if (_buildType STREQUAL "NONSPECIFIC")
        set(_propName "PATHS_TO_SHARED_LIBS__${iTargetName}")
    else()
        set(_propName "PATHS_TO_${_buildType}_SHARED_LIBS__${iTargetName}")
    endif()

    get_property(_isSet GLOBAL PROPERTY "${_propName}" SET)
    if(NOT _isSet)
        set(${oPaths} "" PARENT_SCOPE)
        return()
    endif()

    get_property(_paths GLOBAL PROPERTY "${_propName}")
    set(${oPaths} "${_paths}" PARENT_SCOPE)
endfunction()


#[[
    get_shared_library_dirs

    Returns directories, containing 3rd-party shared libraries, which iTargets are linked to.
    If a shared library is in iTargets or defined in the project, it's path is not returned.
]]
function(get_shared_library_dirs oLibraryDirs iTargets iBuildType)
    set(_libraryDirs "")

    foreach(_target ${iTargets})
        if(NOT TARGET ${_target})
            continue()
        endif()

        get_target_property(_targetLinkLibraries ${_target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        get_paths_to_shared_libs(${_target} ${iBuildType} _libPaths)
        foreach(_libPath ${_libPaths})
            get_filename_component(_libDir ${_libPath} DIRECTORY)
            list(APPEND _libraryDirs ${_libDir})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


#[[
    collect_paths_to_shared_libs

    The method collects paths to binaries of 3rd-party shared libraries, which iTargetName is linked to,
    and stores them in a global properties PATHS_TO_SHARED_LIBS__${iTargetName} and PATHS_TO_${BUILD_TYPE}_SHARED_LIBS__${iTargetName}.
    Should be called from the same folder where iTargetName is declared after libraries are linked to iTargetName.

    The method was written to overcome the following limitation:
        "get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)" does not return all linked libraries, if called from not the same folder where iTargetName is declared.

    Parameters:
    iTargetName - name of a target created in the project.
]]
function(collect_paths_to_shared_libs iTargetName)
    get_target_property(_targetLinkLibraries ${iTargetName} LINK_LIBRARIES)
    if(_targetLinkLibraries STREQUAL "NOTFOUND")
        return()
    endif()

    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    foreach(_lib ${_targetLinkLibraries})
        if(NOT TARGET ${_lib})
            continue()
        endif()

        # Skip, if the linked library is a target of the project.
        list(FIND _registeredTargets ${_lib} _index)
        if (${_index} GREATER -1)
            continue()
        endif()

        get_target_property(_libType ${_lib} TYPE)
        if(NOT (_libType STREQUAL "SHARED_LIBRARY"))
            continue()
        endif()

        get_target_property(_nonBuildSpecificLibPath ${_lib} IMPORTED_LOCATION)
        if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
            add_path_to_shared_libs(${iTargetName} "NonSpecific" ${_nonBuildSpecificLibPath})
        endif()

        is_multiconfig(IS_MULTICONFIG)
        if(IS_MULTICONFIG)
            set(_buildConfigs ${CMAKE_CONFIGURATION_TYPES})
        else()
            set(_buildConfigs "${CMAKE_BUILD_TYPE}")
        endif()

        foreach(_config ${_buildConfigs})
            string(TOUPPER "${_config}" _config)

            get_target_property(_libPath ${_lib} IMPORTED_LOCATION_${_config})
            if(NOT (_libPath AND EXISTS ${_libPath}))
                message(STATUS "collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\". Trying to get a path to RELEASE or non-build-type-specific binary instead.")
                get_target_property(_libPath ${_lib} IMPORTED_LOCATION_RELEASE)
                if(NOT (_libPath AND EXISTS ${_libPath}))
                    if(_nonBuildSpecificLibPath AND EXISTS ${_nonBuildSpecificLibPath})
                        set(_libPath ${_nonBuildSpecificLibPath})
                    else()
                        message(WARNING "collect_paths_to_shared_libs(\"${iTargetName}\"): path to ${_config} binary of shared library \"${_lib}\" is not found or invalid: \"${_libPath}\".")
                        continue()
                    endif()
                endif()
            endif()

            add_path_to_shared_libs(${iTargetName} ${_config} ${_libPath})
        endforeach()
    endforeach()
endfunction()


function(set_up_project)
    # Export all targets to a single export set.
    install(EXPORT ${PROJECT_NAME}Targets
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
    )

    # Create a template "${PROJECT_NAME}Config.cmake.in" file.
    set(_cmake_in__content [[
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@Targets.cmake")
    ]])
    set(_cmake_in__path "${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE "${_cmake_in__path}" "${_cmake_in__content}")

    # Generate the ${PROJECT_NAME}Config.cmake using the template file.
    configure_package_config_file(
        "${_cmake_in__path}"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
    )

    # Create the ${PROJECT_NAME}ConfigVersion.cmake file.
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # Install the package configuration files.
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION ${SUBDIR_CMAKE}/${PROJECT_NAME}
    )
endfunction()


#[[
    get_library_type

    Defines cache variable LIB_<iLibName>_SHARED.
    Returns the type of a library (STATIC or SHARED) according to value of LIB_<iLibName>_SHARED or BUILD_SHARED_LIBS is the LIB_<iLibName>_SHARED is DEFAULT.
    If iLibName is shared, -DLIB_<iLibName>_SHARED define flag is added to compilation.
]]
function(get_library_type iLibName oLibType)
    string(TOUPPER "${iLibName}" _libNameUC)
    set(_cacheVarName "LIB_${_libNameUC}_SHARED")
    get_property(_cachedVarVal CACHE "${_cacheVarName}" PROPERTY VALUE)

    # Create a cache variable with string input.
    set("${_cacheVarName}" "DEFAULT" CACHE STRING "Build \"${iLibName}\" as a shared library. Can be ON, OFF, or DEFAULT.")

    # Restrict allowed values in GUIs like CMake GUI or ccmake.
    set_property(CACHE "${_cacheVarName}" PROPERTY STRINGS ON OFF DEFAULT)

    if("${_cachedVarVal}" STREQUAL "ON")
        set(_libType "SHARED")
    elseif("${_cachedVarVal}" STREQUAL "OFF")
        set(_libType "STATIC")
    else()
        if(BUILD_SHARED_LIBS)
            set(_libType "SHARED")
        else()
            set(_libType "STATIC")
        endif()
    endif()

    set(${oLibType} ${_libType} PARENT_SCOPE)
    if(${_libType} STREQUAL "SHARED")
        add_definitions(-D${_cacheVarName}) # Define preproceccor macro LIB_LIBNAME_SHARED.
    endif()
    message(STATUS "\"${iLibName}\" library will be built as ${_libType}.")
endfunction()


#[[
    set_up_library

    Sets up building and installation of a library-target iLibName.
    Also registers iLibName in the global property REGISTERED_TARGETS.
    Must be called after linking libraries to iLibName.

    Parameters:
    iLibHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iLibSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(set_up_library iLibName iLibHeaders iLibSources iTSResources iOtherResources)
    check_target_name_validity(${iLibName})
    add_library(${PROJECT_NAME}::${iLibName} ALIAS ${iLibName})

    target_sources(${iLibName}
        PRIVATE
            ${iLibSources} # TODO Check if it works with INTERFACE library and empty iLibSources.
            $<BUILD_INTERFACE:${iLibHeaders}> # Headers are added to make them appear in IDEs like Visual Studio.
    )

    target_include_directories(${iLibName}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>
    )

    compose_binary_OUTPUT_NAME(${iLibName} _binaryOutputName)
    set_target_properties(${iLibName}
        PROPERTIES
            EXPORT_NAME ${iLibName}
            OUTPUT_NAME ${_binaryOutputName}
            PUBLIC_HEADER "${iLibHeaders}"
            # CMAKE_VISIBILITY_INLINES_HIDDEN ON  # TODO Parameterize it.
            # POSITION_INDEPENDENT_CODE ON  # TODO Parameterize it.
    )
    ####################################################################


    # Installation
    install(TARGETS ${iLibName}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE DESTINATION ${SUBDIR_STATIC}
        LIBRARY DESTINATION ${SUBDIR_SHARED}
        RUNTIME DESTINATION ${SUBDIR_EXECUTABLE}
        PUBLIC_HEADER DESTINATION ${SUBDIR_INCLUDE}/${iLibName}
        # INCLUDES DESTINATION ${SUBDIR_INCLUDE}/${iLibName} is unnecessary.
        # If ^ line is uncommented, a generated ${iLibName}Config.cmake will have
        # INTERFACE_INCLUDE_DIRECTORIES with duplicated "${_IMPORT_PREFIX}/${SUBDIR_INCLUDE}/${iLibName}",
        # because the target_include_directories(${iLibName} PUBLIC $<INSTALL_INTERFACE:${SUBDIR_INCLUDE}/${iLibName}>) is already set.
    )

    qt_install_ts_resources("${iTSResources}" ${SUBDIR_RESOURCES}/${iLibName}/translations)
    install(FILES ${iOtherResources} DESTINATION ${SUBDIR_RESOURCES}/${iLibName}/other)
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iLibName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    collect_paths_to_shared_libs(${iLibName})
endfunction()


#[[
    set_up_executable

    Sets up building and installation of a executable-target iExeName.
    Also registers iExeName in the global property REGISTERED_TARGETS.
    Must be called after linking libraries to iExeName.

    Parameters:
    iExeHeaders - regular headers (_regular_HEADERS) and Qt MOC headers (_moc_HEADERS).
    iExeSources - regular sources (_regular_SOURCES), Qt MOC sources (qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})) and RCC sources (qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})).
    iTSResources - TS resources (*.ts files).
    iOtherResources - other resources (icons. jsons etc.).
]]
function(set_up_executable iExeName iExeHeaders iExeSources iTSResources iOtherResources)
    check_target_name_validity(${iExeName})
    target_sources(${iExeName} PRIVATE ${iExeSources} ${iExeHeaders}) # Headers are added to make them appear in IDEs like Visual Studio.

    target_include_directories(${iExeName} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    )

    compose_binary_OUTPUT_NAME(${iExeName} _binaryOutputName)
    set_target_properties(${iExeName}
        PROPERTIES
            EXPORT_NAME ${iExeName}
            OUTPUT_NAME ${_binaryOutputName}
    )
    ####################################################################


    install(TARGETS ${iExeName}
        EXPORT ${PROJECT_NAME}Targets
        DESTINATION ${SUBDIR_EXECUTABLE}
    )
    ####################################################################


    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(APPEND _registeredTargets ${iExeName})
    set_property(GLOBAL PROPERTY REGISTERED_TARGETS "${_registeredTargets}")

    collect_paths_to_shared_libs(${iExeName})
endfunction()


#[[
    set_project_entrypoint

    Sets the project entry point executable.

    The entry point is run by "run" script, which is set up by set_up__run__script().
    The entry point executable is run when the project is started in Visual Studio.

    Parameters:
    iExeName - the name of the executable that is the project entry point.
]]
function(set_project_entrypoint iExeName)
    get_property(_isSet GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(_isSet)
        get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
        if(NOT (_exeName STREQUAL iExeName))
            message(FATAL_ERROR "set_project_entrypoint: The project entry point executable is already set to \"${_exeName}\".")
        endif()
    endif()

    get_target_property(_targetType ${iExeName} TYPE)
    if(NOT (${_targetType} STREQUAL "EXECUTABLE"))
        message(FATAL_ERROR "set_project_entrypoint: The target type must be EXECUTABLE.")
    endif()

    set_property(GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE ${iExeName})

    # Make ${iExeName} the startup project in Visual Studio.
    set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${iExeName})
endfunction()


#[[
    set_up_file

    Places to build directory and installs to ${SUBDIR_EXECUTABLE} a file with name and content,
    which are returned by fileNameGetter(oFileName) and contentGetter(iConfig oContent) functions.
    If a generator supports multi-config, temporary files are generated for every configuration (Debug, Release, etc.) during
    configure/generation time and copied to ${SUBDIR_EXECUTABLE} during build of corresponding $<CONFIG>.
    oFileName - is also a name of an utility target (created within the function) that depends on the output file, if multi-config generator is used.
    It must not contain characters that are not allowed in target names; dots are replaced with underscores.

    parameters:
        iAddExePermission - if TRUE, the file is given execute permission (Unix only).
        iInstall - if TRUE, the file is installed to ${SUBDIR_EXECUTABLE}.
]]
function(set_up_file iFileNameGetterName iContentGetterName iAddExePermission iInstall)
    is_multiconfig(IS_MULTICONFIG)
    set(_TMP_FILE_DIR "${CMAKE_BINARY_DIR}/${SUBDIR_TMP}")
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
        set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/$<CONFIG>/${_fileName}")
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
        set(_filePath "${CMAKE_BINARY_DIR}/${SUBDIR_EXECUTABLE}/${_fileName}")

        # Add the file to build dir(s) at configire time.
        file(WRITE "${_filePath}" "${_fileContent}")
        if (UNIX AND iAddExePermission)
            execute_process(COMMAND chmod +x "${_filePath}")
        endif()
    endif()

    # Install the file.
    if(iInstall)
        if(UNIX AND iAddExePermission)
            install(
                FILES "${_filePath}"
                DESTINATION "${SUBDIR_EXECUTABLE}"
                PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
            )
        else()
            install(
                FILES "${_filePath}"
                DESTINATION "${SUBDIR_EXECUTABLE}"
                PERMISSIONS OWNER_READ OWNER_WRITE
            )
        endif()
    endif()
endfunction()


set(3RD_PARTY_SHARED_LIBS__LIST_NAME "3rd_party_shared_libs.json")
function(get__3rd_party_shared_libs__file_name oFileName)
    set(${oFileName} "${3RD_PARTY_SHARED_LIBS__LIST_NAME}" PARENT_SCOPE)
endfunction()


#[[
    generate_3rd_party_shared_libs__content

    Returns content of the "3rd_party_shared_libs.json" file.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__3rd_party_shared_libs__content iBuildType oContent)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    list(LENGTH _registeredTargets _registeredTargetsLength)

    set(_fileContent "{\n")
    set(_targetIdx 0)
    foreach(_target ${_registeredTargets})
        set(_fileContent "${_fileContent}\t\"${_target}\": [")

        get_paths_to_shared_libs(${_target} "${iBuildType}" _libPaths)
        list(LENGTH _libPaths _libPathsLength)
        if(NOT _libPathsLength EQUAL 0)
            string(JOIN "\",\n\t\t\"" _libPathsJoined ${_libPaths})
            set(_fileContent "${_fileContent}\n\t\t\"${_libPathsJoined}\"\n\t]")
        endif()

        math(EXPR _targetIdx "${_targetIdx} + 1")
        if(_targetIdx LESS ${_registeredTargetsLength})
            set(_fileContent "${_fileContent},\n")
        else()
            set(_fileContent "${_fileContent}\n")
        endif()
    endforeach()
    set(_fileContent "${_fileContent}}")

    set(${oContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__3rd_party_shared_libs__list

    Generates, places to build directory and installs "3rd_party_shared_libs.json" file.
    The file contains paths to binaries of 3rd-party shared libraries, which registered (created) targets are linked to.
    The file may be used to make distributable packages.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__3rd_party_shared_libs__list)
    set_up_file("get__3rd_party_shared_libs__file_name" "generate__3rd_party_shared_libs__content" FALSE TRUE)
endfunction()


set(SCRIPT_EXTENSION_UNIX "sh")
set(SCRIPT_EXTENSION_WINDOWS "bat")

set(SCRIPT_NAME_SUFFIX_UNIX "_Unix")
# The differentiation is required, because Unix_standard scripts can't be run on Unix or don't do what they are intented for.
# E.g. Android is also Unix, but not Unix-standard: some variables and functions are not available or restricted.
set(SCRIPT_NAME_SUFFIX_UNIX_STANDARD "_Unix_standard")
set(SCRIPT_NAME_SUFFIX_WINDOWS "_Windows")

set(ENV_VSCODE__SCRIPT_NAME ".env.vscode")

set(SET_ENV__SCRIPT_NAME_WE "set_env")
set(SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/SetUpTargets/${SET_ENV__SCRIPT_NAME_WE}__TEMPLATE")

set(RUN__SCRIPT_NAME_WE "run")
set(RUN__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/SetUpTargets/${RUN__SCRIPT_NAME_WE}__TEMPLATE")


function(get__set_env__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${SET_ENV__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    generate__shared_lib_dirs__string_value

    Call "set "%{oEnvString}"" on Windows or "export ${oEnvString}" on Unix to set the paths to 3rd-party shared libs.

    TODO Check if the function is required.
]]
function(generate__shared_lib_dirs__string_value iDirs oEnvString)
    cmake_path(CONVERT "${iDirs}" TO_NATIVE_PATH_LIST _dirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_envString "Path=${_dirsNative};%Path%")
    else()
        set(_envString "LD_LIBRARY_PATH=\"${_dirsNative}:${LD_LIBRARY_PATH}\"")
    endif()

    set(${oEnvString} "${_envString}" PARENT_SCOPE)
endfunction()



#[[
    generate__set_env__script_content

    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__set_env__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(PARAM__SHARED_LIB_DIRS_STRING "param\\nSHARED_LIB_DIRS_STRING\\nparam")
    ####################################################################

    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    set(_libraryDirs "")
    get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${SET_ENV__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX_STANDARD}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${PARAM__SHARED_LIB_DIRS_STRING}" "${_libraryDirsNative}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__set_env__script

    Generates, places to build directory and installs "set_env" script.
    The script sets paths to directories with 3rd-party shared libraries, which registered (created) targets are linked to.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__set_env__script)
    set_up_file("get__set_env__script_file_name" "generate__set_env__script_content" TRUE TRUE)
endfunction()


function(get__env_vscode__file_name oFileName)
    set(${oFileName} "${ENV_VSCODE__SCRIPT_NAME}" PARENT_SCOPE)
endfunction()


#[[
    generate__env_vscode__file_content

    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(generate__env_vscode__file_content iBuildType oFileContent)# Strings to replace in the template script.
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)

    set(_libraryDirs "")
    get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${iBuildType}")
    cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_fileContent "Path=\"${_libraryDirsNative}\"")
    else()
        set(_fileContent "LD_LIBRARY_PATH=\"${_libraryDirsNative}\"")
    endif()

    set(${oFileContent} "${_fileContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__env_vscode__file

    Generates and places to build directory ".env.vscode" file.
    The file sets Path/LD_LIBRARY_PATH equal to list of dirs to 3rd-party shared libraries, which registered (created) targets are linked to.

    The only reason ".env.vscode" is requred - VS Code can't execute normal scripts in the same terminal, as it launches
    an executable for debugging.

    The function must be called after all set_up_library(iLibName) and set_up_executable(iExeName) are called.
]]
function(set_up__env_vscode__file)
    set_up_file("get__env_vscode__file_name" "generate__env_vscode__file_content" FALSE FALSE)
endfunction()


function(get__run__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${RUN__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    generate__run__script_content

    If a project entrypoint executable is set (look at set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after set_up__set_env__script() is called.
]]
function(generate__run__script_content iBuildType oScriptContent)
    # Strings to replace in the template script.
    set(EXECUTABLE_NAME_WE "param\\nEXECUTABLE_NAME_WE\\nparam")
    ####################################################################

    get_property(_is_PROJECT_ENTRYPOINT_EXE_set GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE SET)
    if(NOT (_is_PROJECT_ENTRYPOINT_EXE_set))
        message(WARNING "generate__run__script_content: The project entrypoint executable is not set.")
        return()
    endif()
    get_property(_exeName GLOBAL PROPERTY PROJECT_ENTRYPOINT_EXE)
    compose_binary_OUTPUT_NAME(${_exeName} _exeName)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${RUN__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${EXECUTABLE_NAME_WE}" "${_exeName}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    set_up__run__script

    Generates, places to build directory and installs "run" script.
    If a project entrypoint executable is set (look at set_project_entrypoint(iExeName)), "run" script is generated.
    The script runs "set_env" script and the project entrypoint executable.

    The function must be called after set_up__set_env__script() is called.
]]
function(set_up__run__script)
    set_up_file("get__run__script_file_name" "generate__run__script_content" TRUE TRUE)
endfunction()


set(RUN_TESTS__SCRIPT_NAME_WE "run_tests")
set(RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX "${CMAKE_CURRENT_LIST_DIR}/SetUpTargets/${RUN_TESTS__SCRIPT_NAME_WE}__TEMPLATE")


#[[
    generate__run_tests__script_content

    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after set_up__set_env__script() is called.
]]
function(generate__run_tests__script_content iBuildType oScriptContent)
# Strings to replace in the template script.
    set(DIR_WITH_CTESTTESTFILE "param\\nDIR_WITH_CTESTTESTFILE\\nparam")
    set(BUILD_CONFIG "param\\nBUILD_CONFIG\\nparam")
    ####################################################################

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_template_script_path "${RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_WINDOWS}.${SCRIPT_EXTENSION_WINDOWS}")
    else()
        set(_template_script_path "${RUN_TESTS__TEMPLATE_SCRIPT_PATH_PREFIX}${SCRIPT_NAME_SUFFIX_UNIX}.${SCRIPT_EXTENSION_UNIX}")
    endif()

    is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        set(_dirWithCtestTestFile "../../${SUBDIR_CTESTTESTFILE}")
    else()
        set(_dirWithCtestTestFile "../${SUBDIR_CTESTTESTFILE}")
    endif()

    file(READ "${_template_script_path}" _scriptContent)
    string(REPLACE "${DIR_WITH_CTESTTESTFILE}" "${_dirWithCtestTestFile}" _scriptContent "${_scriptContent}")
    string(REPLACE "${BUILD_CONFIG}" "${iBuildType}" _scriptContent "${_scriptContent}")

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


function(get__run_tests__script_file_name oFileName)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${oFileName} "${RUN_TESTS__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_WINDOWS}" PARENT_SCOPE)
    else()
        set(${oFileName} "${RUN_TESTS__SCRIPT_NAME_WE}.${SCRIPT_EXTENSION_UNIX}" PARENT_SCOPE)
    endif()
endfunction()


#[[
    set_up__run_tests__script

    Generates, places to build directory and installs "run_tests" script.
    The script runs "set_env" script and "ctest" with proper arguments.

    The function must be called after set_up__set_env__script() is called.
]]
function(set_up__run_tests__script)
    set_up_file("get__run_tests__script_file_name" "generate__run_tests__script_content" TRUE FALSE)
endfunction()


#[[
    set_test_discovery

    Sets up path to directories with 3rd-party shared libraries, which registered (created) targets are linked to, before GTest discovery at build time.

    The function must be called after:
        * all set_up_library(iLibName) and set_up_executable(iExeName) are called;
        * include(GoogleTest).
]]
function(set_test_discovery iTestTargetName)
    get_property(_registeredTargets GLOBAL PROPERTY REGISTERED_TARGETS)
    is_multiconfig(IS_MULTICONFIG)
    if(IS_MULTICONFIG)
        foreach(_config ${CMAKE_CONFIGURATION_TYPES})
            get_shared_library_dirs(_libraryDirs_${_config} "${_registeredTargets}" "${_config}")
            cmake_path(CONVERT "${_libraryDirs_${_config}}" TO_NATIVE_PATH_LIST _libraryDirsNative_${_config})

            # Triggers test discovery: runs the test executable with the --gtest_list_tests argument during build time.
            # Creates a list of all test suites and test names (without executing their bodies).
            # Parses the list of tests, and adds each one to ctest.
            gtest_discover_tests(${iTestTargetName}
                DISCOVERY_MODE PRE_TEST
                CONFIG ${_config}
                PROPERTIES
                    ENVIRONMENT "PATH=${_libraryDirsNative_${_config}};$ENV{PATH}" # Without the PATH variable, test discovery can't be performed during build time and build fails.
                    LABELS "${_config}"
                    # TODO Check if works on all platforms.
            )

            # Tests should be run with "--build-config" flag.
            # Otherwise, the test executable the follwing error occurs:
            # "include could not find requested file: <path_to_the_project>/build/<toolset>/tests/<target_CMakeLists_dir>/${iTestTargetName}[1]_include-.cmake".
            # <target_CMakeLists_dir> is the directory where the target, whose code is to be tested (not a test target), is declared.
        endforeach()
    else()
        get_shared_library_dirs(_libraryDirs "${_registeredTargets}" "${CMAKE_BUILD_TYPE}")
        cmake_path(CONVERT "${_libraryDirs}" TO_NATIVE_PATH_LIST _libraryDirsNative)

        # Triggers test discovery: runs the test executable with the --gtest_list_tests argument during build time.
        # Creates a list of all test suites and test names (without executing their bodies).
        # Parses the list of tests, and adds each one to ctest.
        gtest_discover_tests(${iTestTargetName}
            DISCOVERY_MODE PRE_TEST
            PROPERTIES
                ENVIRONMENT "PATH=${_libraryDirsNative};$ENV{PATH}" # Without the PATH variable, test discovery can't be performed during build time and build fails.
                # TODO Check if works on all platforms.
            )
    endif()
endfunction()