# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from scripts.python_utils import warning, error, status
import json
from pathlib import Path
from typing import Dict
from typing import Any


class MetadataHolder:
    """
    Parses and holds in a buffer JSON files within 'meta' and its subdirectories.
    """

    __METADATA_DIR: Path = (Path(__file__).parent.resolve() / "../meta").resolve()
    __METADATA_BUFFER: Dict[Path, Any] | None = None

    @staticmethod
    def GET_METADATA_DIR() -> Path:
        """Returns a base dir, where all metadata files must be placed. Subdirs are allowed."""
        return MetadataHolder.__METADATA_DIR

    def __GET_METADATA_BUFFER() -> Dict[Path, Any]:
        if MetadataHolder.__METADATA_BUFFER is None:
            MetadataHolder.__METADATA_BUFFER = {}
        return MetadataHolder.__METADATA_BUFFER

    @staticmethod
    def __READ_METADATA_FILE(iFilePathInMetadataDir: Path) -> Any:
        """Returns data of iFilePathInMetadataDir"""

        data = MetadataHolder.__GET_METADATA_BUFFER().get(iFilePathInMetadataDir)
        if data is not None:
            return data

        if not iFilePathInMetadataDir.exists():
            error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" file not found.")

        if not iFilePathInMetadataDir.is_file():
            error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" is not a file.")

        if not iFilePathInMetadataDir.is_relative_to(MetadataHolder.GET_METADATA_DIR()):
            error(f"{__class__.__name__}: \"{iFilePathInMetadataDir}\" must be within \"{MetadataHolder.GET_METADATA_DIR()}\".")

        with iFilePathInMetadataDir.open("r", encoding="utf-8") as textFile:
            data = json.load(textFile)

        MetadataHolder.__GET_METADATA_BUFFER()[iFilePathInMetadataDir] = data
        return data

    @staticmethod
    def __GET_NESTED_VALUE(iData: dict, iKeys: list[str]) -> Any:
        for key in iKeys:
            if isinstance(iData, dict):
                data = iData.get(key)
                if data is not None:
                    iData = data
            else:
                return None
        return iData

    @staticmethod
    def GET_METADATA_VALUE(iFilePathRelativeToMetadataDir: Path, iKeys: list[str]) -> Any:
        """
        Returns value of a nested structure in a JSON file.

        :param iFilePathRelativeToMetadataDir must refer to a file within 'meta' or its subdirectory.
        :param iKeys is a sequence of names of ancestor structures.
        """
        filePath = (MetadataHolder.GET_METADATA_DIR() / iFilePathRelativeToMetadataDir).resolve()
        data = MetadataHolder.__READ_METADATA_FILE(filePath)
        if (data is None):
            return None

        return MetadataHolder.__GET_NESTED_VALUE(data, iKeys)