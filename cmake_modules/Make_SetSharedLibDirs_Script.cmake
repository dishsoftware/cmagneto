set(SET_SHARED_LIB_DIRS__SCRIPT_NAME "set_shared_lib_dirs.sh")


#[[
    get_shared_library_dirs

    Appends directories, containing shared libraries linked to iTargets, to oLibraryDirs.
]]
function(get_shared_library_dirs oLibraryDirs iTargets)
    set(_libraryDirs "")

    foreach(target ${iTargets})
        get_target_property(_targetLinkLibraries ${target} LINK_LIBRARIES)
        if(_targetLinkLibraries STREQUAL "NOTFOUND")
            continue()
        endif()

        # Collect library paths for each linked shared library.
        foreach(_lib ${_targetLinkLibraries})
            if(NOT TARGET ${_lib})
                continue()
            endif()

            get_target_property(_libType ${_lib} TYPE)
            if(NOT (_libType STREQUAL "SHARED_LIBRARY"))
                continue()
            endif()

            get_target_property(_libPath ${_lib} IMPORTED_LOCATION)
            if(NOT (_libPath AND EXISTS ${_libPath}))
                message(WARNING "get_shared_library_dirs: Shared library of \"${_lib}\" is not found.")
                continue()
            endif()

            get_filename_component(_libDir ${_libPath} DIRECTORY)
            list(APPEND _libraryDirs ${_libDir})
            message(STATUS "Library: ${_lib}")
            message(STATUS "Library path: ${_libPath}")
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES _libraryDirs)
    set(${oLibraryDirs} "${_libraryDirs}" PARENT_SCOPE)
endfunction()


#[[
    generate__set_shared_lib_dirs__script_content

    Generates content of a script, which adds directories, containing shared libraries linked to iTargets,
    to the environment variable LD_LIBRARY_PATH (Linux) or PATH (Windows).
]]
function(generate__set_shared_lib_dirs__script_content oScriptContent iTargets)
    set(_scriptContent "#!/bin/bash\n")

    set(_libraryDirs "")
    get_shared_library_dirs(_libraryDirs "${iTargets}")
    message(STATUS "Library dirs: ${_libraryDirs}")

    # Depending on the platform, create a script that sets LD_LIBRARY_PATH (Linux) or PATH (Windows)
    if(UNIX AND NOT APPLE) # Linux
        foreach(_libPath ${_libraryDirs})
            set(_scriptContent "${_scriptContent}export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${_libPath}\n")
        endforeach()
    elseif(WIN32) # Windows
        foreach(_libPath ${_libraryDirs})
            set(_scriptContent "${_scriptContent}set PATH=${_libPath};%PATH%\n")
        endforeach()
    else()
        message(WARNING "generate__set_shared_lib_dirs__script_content: Unsupported platform.")
    endif()

    set(${oScriptContent} "${_scriptContent}" PARENT_SCOPE)
endfunction()


#[[
    make_shared_lib_paths_script

    Generates a script, named ${SET_SHARED_LIB_DIRS__SCRIPT_NAME}, that sets the environment variable
    LD_LIBRARY_PATH (Linux) or PATH (Windows) to the directories containing the libraries linked to the targets in iTargets.
]]
function(make_shared_lib_paths_script iTargets iDirectory)
    set(_scriptContent "")
    generate__set_shared_lib_dirs__script_content(_scriptContent ${iTargets})
    set(_scriptPath ${iDirectory}/${SET_SHARED_LIB_DIRS__SCRIPT_NAME})
    file(WRITE ${_scriptPath} ${_scriptContent})
    if(UNIX)
        execute_process(COMMAND chmod +x ${_scriptPath})
    endif()
endfunction()