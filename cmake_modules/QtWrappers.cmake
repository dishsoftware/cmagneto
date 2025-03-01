# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
if (NOT DEFINED Qt6_FOUND)
  find_package(Qt6 REQUIRED COMPONENTS Core)
  if (NOT Qt6_FOUND)
    message(FATAL_ERROR "Qt6 is required. Stopping CMake.")
  else()
    message(STATUS "Qt6 found. Version: ${Qt6_VERSION}. Path: ${Qt6_DIR}")
  endif()
endif()


# The macro uses the following vars:
# - QT_LRELEASE_EXECUTABLE - set by FindQT.cmake.
#
# Arguments:
# tsFiles - list of *.ts files to compile.
# installDir - directory (relative to install_prefix) to install *.qm files after compilation of *.ts files.
macro(qt_install_ts_resources tsFiles installDir)
  foreach(_input ${tsFiles})
    get_filename_component(_name ${_input} NAME_WE)
    set(_output ${CMAKE_CURRENT_BINARY_DIR}/${_name}.qm)
    set(_cmd_${_name} ${QT_LRELEASE_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/${_input} -qm ${_output})
    add_custom_target(qt_install_ts_resources_${_name} ALL COMMAND ${_cmd_${_name}} DEPENDS ${_input})
    install(FILES ${_output} DESTINATION ${installDir})
  endforeach()
endmacro(qt_install_ts_resources)


macro(qt_wrap_moc)
  qt6_wrap_cpp(${ARGN})
  # Workaround for a bug in MOC preprocessor of Qt 5.6.0 and newer.
  # The problem emerges on Linux, if system-native Qt is installed, and "-I/usr/include" precedes custom Qt includes in MOC command line.
  # To avoid it, move "-I/usr/include" parameter in the "MOC parameters" file to the end of the "include section".
  if (NOT WIN32)
    foreach(_inputFilePath ${ARGN})
      get_filename_component(_inputFilePath ${_inputFilePath} ABSOLUTE)
      get_filename_component(_fileNameWE ${_inputFilePath} NAME_WE)
      set(_outFilePath ${CMAKE_CURRENT_BINARY_DIR}/moc_${_fileNameWE}.cpp_parameters)
      if(EXISTS ${_outFilePath})
        set(_newContent)
        set(_isIncludeSection TRUE)
        set(_hasSystemInc FALSE)
        file(READ ${_outFilePath} _content)
        string(REGEX REPLACE "\n" ";" _content "${_content}")
        list(REMOVE_DUPLICATES _content)
        foreach(S ${_content})
          if("${S}" MATCHES "^-I")
            if("${S}" STREQUAL "-I/usr/include")
              set(_hasSystemInc TRUE)
            else()
              set(_newContent ${_newContent} "${S}\n")
            endif()
          else()
            set(_isIncludeSection FALSE)
          endif()
          if(NOT _isIncludeSection)
            if(_hasSystemInc)
              set(_newContent ${_newContent} "-I/usr/include\n")
              set(_hasSystemInc FALSE)
            endif()
            set(_newContent ${_newContent} "${S}\n")
          endif()
        endforeach()
        file(WRITE ${_outFilePath} ${_newContent})
      endif()
    endforeach()
  endif()
endmacro(qt_wrap_moc)
