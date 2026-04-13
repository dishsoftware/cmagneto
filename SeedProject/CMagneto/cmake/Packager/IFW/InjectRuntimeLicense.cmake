# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto Framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto Framework.
#
# By default, the CMagneto Framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

if(NOT DEFINED CPACK_TEMPORARY_DIRECTORY)
    return()
endif()

cmake_path(SET _runtimeMetaDir NORMALIZE "${CPACK_TEMPORARY_DIRECTORY}/packages/runtime/meta")
cmake_path(SET _runtimePackageXml NORMALIZE "${_runtimeMetaDir}/package.xml")
if(NOT EXISTS "${_runtimePackageXml}")
    return()
endif()

if(NOT DEFINED CPACK_RESOURCE_FILE_LICENSE OR NOT EXISTS "${CPACK_RESOURCE_FILE_LICENSE}")
    return()
endif()

get_filename_component(_licenseFileName "${CPACK_RESOURCE_FILE_LICENSE}" NAME)
cmake_path(SET _stagedLicensePath NORMALIZE "${_runtimeMetaDir}/${_licenseFileName}")
file(COPY_FILE "${CPACK_RESOURCE_FILE_LICENSE}" "${_stagedLicensePath}" ONLY_IF_DIFFERENT)

file(READ "${_runtimePackageXml}" _packageXmlText)
if(_packageXmlText MATCHES "<Licenses>")
    return()
endif()

set(_licensesXml [=[
	<Licenses>
		<License name="MIT License" file="@licenseFileName@" />
	</Licenses>
]=])
string(REPLACE "@licenseFileName@" "${_licenseFileName}" _licensesXml "${_licensesXml}")

string(REPLACE "</Package>" "${_licensesXml}\n</Package>" _packageXmlText "${_packageXmlText}")
file(WRITE "${_runtimePackageXml}" "${_packageXmlText}")
