# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations
from .utils.good_path import GoodPath
from .utils.log import Log
from pathlib import Path
from typing import TypeAlias, cast
import json


JSONValue: TypeAlias = None | bool | int | float | str | list["JSONValue"] | dict[str, "JSONValue"]


class MetadataHolder:
    """
    Parses and holds in a buffer JSON files within 'meta' and its subdirectories.
    """

    # CMagneto__* constants are in synch (as the methods of this file) with the CMagneto CMake module,
    # and the constants' names do not obey the Python naming convention.
    CMagneto__SUBDIR_META: Path = Path("meta/")
    ##################################################################################################

    __METADDATA_ROOT: Path = (GoodPath.projectRoot() / CMagneto__SUBDIR_META).resolve()
    __sInstance = None

    def __new__(cls):
        if cls.__sInstance is None:
            cls.__sInstance = super().__new__(cls)
            cls.__sInstance.__initialized = False
        return cls.__sInstance

    def __init__(self):
        if self.__initialized:
            return
        # {fileName, fileContent}[]
        self.__metadataBuffer: dict[Path, JSONValue] = dict()
        self.__initialized = True

    @staticmethod
    def getMetadataRoot() -> Path:
        """Returns a base dir, where all metadata files must be placed. Subdirs are allowed."""
        return MetadataHolder.__METADDATA_ROOT

    def __readMetadataFile(self, iFilePathInMetadataDir: Path) -> JSONValue:
        """Returns data of iFilePathInMetadataDir"""

        # Check if the buffer contains iFilePathInMetadataDir and return key in single lookup.
        try:
            data = self.__metadataBuffer[iFilePathInMetadataDir]
            # iFilePathInMetadataDir was read previously.
            return data
        except KeyError:
            # iFilePathInMetadataDir was not read previously.
            if not iFilePathInMetadataDir.exists():
                Log.error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" file not found.")

            if not iFilePathInMetadataDir.is_file():
                Log.error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" is not a file.")

            if not iFilePathInMetadataDir.is_relative_to(MetadataHolder.getMetadataRoot()):
                Log.error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" must be within \"{MetadataHolder.getMetadataRoot()}\".")

            with iFilePathInMetadataDir.open("r", encoding="utf-8") as textFile:
                data = cast(JSONValue, json.load(textFile))

            self.__metadataBuffer[iFilePathInMetadataDir] = data
        return data

    @staticmethod
    def __getNestedValue(iData: JSONValue, iKeySequence: list[str]) -> JSONValue | None:
        for key in iKeySequence:
            if isinstance(iData, dict):
                nestedData = iData
                if key not in nestedData:
                    return None
                iData = nestedData[key]
            else:
                return None
        return iData

    def getMetadataValue(self, iFilePathRelativeToMetadataDir: Path, iKeys: list[str]) -> JSONValue | None:
        """
        Returns value of a nested structure in a JSON file.

        :param iFilePathRelativeToMetadataDir must refer to a file within 'meta' or its subdirectory.
        :param iKeys is a sequence of names of ancestor structures.
        """
        filePath = (MetadataHolder.getMetadataRoot() / iFilePathRelativeToMetadataDir).resolve()
        data = self.__readMetadataFile(filePath)
        if (data is None):
            return None

        return MetadataHolder.__getNestedValue(data, iKeys)
