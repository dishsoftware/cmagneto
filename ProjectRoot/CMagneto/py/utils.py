# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from enum import Enum
from pathlib import Path
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
    __PROJECT_ROOT: Path = Path(__file__).resolve().parent.parent.parent

    @staticmethod
    def projectRoot() -> Path:
        """Returns absolute path of the project root."""
        return Utils.__PROJECT_ROOT


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

    __LOG_MESSAGE_PREFIX = "[CMagneto] "

    @staticmethod
    def error(iMessage: str) -> NoReturn:
        """ Prints an error message in red color and exits the program. Adds "[CMagneto] Error: " prefix."""
        Utils.printColored(f"{Utils.__LOG_MESSAGE_PREFIX}Error: {iMessage}", Utils.PrintColor.Red)
        sys.exit(1)

    @staticmethod
    def runtimeError(iMessage: str) -> None:
        """ Makes iMessage in red color and raises RuntimeError."""
        raise RuntimeError(Utils.makeColored(Utils.__LOG_MESSAGE_PREFIX + iMessage, Utils.PrintColor.Red))

    @staticmethod
    def warning(iMessage: str) -> None:
        """ Prints a warning message in yellow color. Adds "[CMagneto] Warning: " prefix."""
        Utils.printColored(f"{Utils.__LOG_MESSAGE_PREFIX}Warning: {iMessage}", Utils.PrintColor.Yellow)

    @staticmethod
    def message(iMessage: str, iIndent: str | None = None) -> None:
        """ Prints a message in default color. If iIndent is non-empty string, every new line is prepended with the indent and "[CMagneto] " prefix."""
        print(Utils.makeIndented(iMessage, Utils.__LOG_MESSAGE_PREFIX + iIndent if iIndent else Utils.__LOG_MESSAGE_PREFIX))

    @staticmethod
    def status(iMessage: str) -> None:
        """ Prints an informational message in green color."""
        Utils.printColored(Utils.__LOG_MESSAGE_PREFIX + iMessage, Utils.PrintColor.Green)

    @staticmethod
    def runCommand(iCommand: list[str], iCWD: Path | None = None, *, iCheck: bool = True, iCaptureOutput: bool = False) -> subprocess.CompletedProcess | None:
        currentCWD = os.getcwd()
        if iCWD is not None:
            os.chdir(iCWD)

        print(
            Utils.makeColored("Running command: ", Utils.PrintColor.Cyan) + \
            Utils.makeColored(f"{os.getcwd()}> ", Utils.PrintColor.Magenta) + \
            Utils.makeColored(shlex.join(iCommand), Utils.PrintColor.Blue),
            flush=True
        )

        try:
            process = subprocess.Popen(
                iCommand,
                stdout=subprocess.PIPE,   # Stream output line-by-line.
                stderr=subprocess.STDOUT, # Merge `stderr` into `stdout` to preserve order.
                text=True,                # Convert bytes into text to render escaped characters, etc.
                bufsize=1,                # Enable line buffering for real-time printing.
                universal_newlines=True,  # Interpret `\r\n`, etc. `\n`.
            )
            assert process.stdout is not None # For type checker.

            capturedLines = []
            for line in process.stdout:
                print(line, end='') # Print from the sub process `stdout` stream in real time. Each line already has a endline.
                if iCaptureOutput:
                    capturedLines.append(line) # Output is requested. Save captured lines and return them later as a batch placed inside a `CompletedProcess` entity.

            returnCode = process.wait()
            if iCheck and returnCode != 0:
                Utils.printColored(f"{Utils.__LOG_MESSAGE_PREFIX}Command failed with error.", Utils.PrintColor.Red)
                raise subprocess.CalledProcessError(returnCode, iCommand, output="".join(capturedLines))

            if iCaptureOutput:
                return subprocess.CompletedProcess(
                    args=iCommand,
                    returncode=returnCode,
                    stdout="".join(capturedLines),
                    stderr=None
                )
            else:
                return None

        finally:
            if iCWD is not None:
                os.chdir(currentCWD)

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