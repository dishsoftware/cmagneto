# Copyright (C) 2007-2024  CEA, EDF, OPEN CASCADE
#
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
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#
#
# Modified by Dmitrii Shvydkoi ("Dim Shvydkoy") in 2025.
# Originally from the SALOME project: https://github.com/SalomePlatform/shaper/blob/master/CMakeCommon/UseQtExt.cmake
# This file remains licensed under the LGPL v2.1 or later.


include_guard(GLOBAL)  # Ensures this file is included only once.


#[[
    QtWrappers__qt_wrap_cpp

    Workaround for a bug in MOC preprocessor of Qt 5.6.0 and newer.
    The problem emerges on Linux, if system-native Qt is installed, and "-I/usr/include" precedes custom Qt includes in MOC command line.
    To avoid it, move "-I/usr/include" parameter in the "MOC parameters" file to the end of the "include section".
]]
macro(QtWrappers__qt_wrap_cpp)
    qt_wrap_cpp(${ARGN})
    if(NOT WIN32)
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
endmacro(QtWrappers__qt_wrap_cpp)