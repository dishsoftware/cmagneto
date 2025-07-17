# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from __future__ import annotations
from .const_meta_class import ConstMetaClass
from enum import Enum
from typing import NoReturn
import sys


class Log(metaclass=ConstMetaClass):
    class PrintColor(Enum):
        Red = "\033[91m"
        Green = "\033[92m"
        Yellow = "\033[93m"
        Blue = "\033[94m"
        Magenta = "\033[95m"
        Cyan = "\033[96m"
        White = "\033[97m"


    RESET_PRINT_COLOR__STR = "\033[0m"

    @staticmethod
    def printColored(iText: str, iColor: PrintColor) -> None:
        """ Prints text in the specified color."""
        print(f"{iColor.value}{iText}{Log.RESET_PRINT_COLOR__STR}", flush=True)

    @staticmethod
    def makeColored(iText: str, iColor: PrintColor) -> str:
        """ Returns text in the specified color."""
        return f"{iColor.value}{iText}{Log.RESET_PRINT_COLOR__STR}"

    @staticmethod
    def makeIndented(iText: str, iIndent: str | None) -> str:
        """ If iIndent is non-empty string, every new line is prepended with the indent."""
        if (iIndent is None or iIndent == ""):
            return iText
        else:
            indentedText = ""
            for line in iText.splitlines():
                indentedText += f"{iIndent}{line}\n"
            return indentedText

    __LOG_MESSAGE_PREFIX = "[CMagneto] "

    @staticmethod
    def error(iMessage: str) -> NoReturn:
        """ Prints an error message in red color and exits the program. Adds "[CMagneto] Error: " prefix."""
        Log.printColored(f"{Log.__LOG_MESSAGE_PREFIX}Error: {iMessage}", Log.PrintColor.Red)
        sys.exit(1)

    @staticmethod
    def warning(iMessage: str) -> None:
        """ Prints a warning message in yellow color. Adds "[CMagneto] Warning: " prefix."""
        Log.printColored(f"{Log.__LOG_MESSAGE_PREFIX}Warning: {iMessage}", Log.PrintColor.Yellow)

    @staticmethod
    def message(iMessage: str, iIndent: str | None = None) -> None:
        """ Prints a message in default color. If iIndent is non-empty string, every new line is prepended with the indent and "[CMagneto] " prefix."""
        print(Log.makeIndented(iMessage, Log.__LOG_MESSAGE_PREFIX + iIndent if iIndent else Log.__LOG_MESSAGE_PREFIX))

    @staticmethod
    def status(iMessage: str) -> None:
        """ Prints an informational message in green color."""
        Log.printColored(Log.__LOG_MESSAGE_PREFIX + iMessage, Log.PrintColor.Green)
