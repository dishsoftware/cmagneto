# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from enum import Enum
from typing import NoReturn
import os
import re
import shlex
import subprocess
import sys


class ConstMetaClass(type):
    """
    Prohibits modification of class attributes after they are set.
    """
    def __setattr__(cls, key, value):
        if key in cls.__dict__:
            raise AttributeError(f"Cannot modify const member '{key}'")
        super().__setattr__(key, value)


class Utils(metaclass=ConstMetaClass):


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
        print(f"{iColor.value}{iText}{Utils.RESET_PRINT_COLOR__STR}", flush=True)

    @staticmethod
    def makeColored(iText: str, iColor: PrintColor) -> str:
        """ Returns text in the specified color."""
        return f"{iColor.value}{iText}{Utils.RESET_PRINT_COLOR__STR}"

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

    @staticmethod
    def error(iMessage: str) -> NoReturn:
        """ Prints an error message in red color and exits the program. Adds "Error: " prefix."""
        Utils.printColored(f"Error: {iMessage}", Utils.PrintColor.Red)
        sys.exit(1)

    @staticmethod
    def runtimeError(iMessage: str) -> None:
        """ Makes iMessage in red color and raises RuntimeError."""
        raise RuntimeError(Utils.makeColored(iMessage, Utils.PrintColor.Red))

    @staticmethod
    def warning(iMessage: str) -> None:
        """ Prints a warning message in yellow color. Adds "Warning: " prefix."""
        Utils.printColored(f"Warning: {iMessage}", Utils.PrintColor.Yellow)

    @staticmethod
    def message(iMessage: str, iIndent: str | None = None) -> None:
        """ Prints a message in default color. If iIndent is non-empty string, every new line is prepended with the indent."""
        print(Utils.makeIndented(iMessage, iIndent))

    @staticmethod
    def status(iMessage: str) -> None:
        """ Prints an informational message in green color."""
        Utils.printColored(iMessage, Utils.PrintColor.Green)

    @staticmethod
    def runCommand(iCommand: list[str]) -> None:
        print(Utils.makeColored("Running command: ", Utils.PrintColor.Cyan) + \
              Utils.makeColored(f"{os.getcwd()}> ", Utils.PrintColor.Magenta) + \
              Utils.makeColored(shlex.join(iCommand), Utils.PrintColor.Blue),
              flush=True
        )
        subprocess.run(iCommand, check=True)

    # Regex to allow only safe characters.
    SAFE_DIRNAME_PATTERN = re.compile(r"^[a-zA-Z0-9._-]+$")

    # Reserved Windows names (case-insensitive).
    WINDOWS_RESERVED_NAMES = {
        "CON", "PRN", "AUX", "NUL",
        *(f"COM{i}" for i in range(1, 10)),
        *(f"LPT{i}" for i in range(1, 10)),
    }

    @staticmethod
    def isDirNamePortable(iDirName: str) -> bool:
        if not iDirName:
            return False
        if not Utils.SAFE_DIRNAME_PATTERN.fullmatch(iDirName):
            return False
        if iDirName.upper() in Utils.WINDOWS_RESERVED_NAMES:
            return False
        if iDirName[0] == "." or iDirName[-1] in {" ", "."}:
            return False
        return True