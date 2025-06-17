import os
import sys
import subprocess
import shlex
from enum import Enum


# Prohibits modification of class attributes after they are set.
class ConstMetaClass(type):
    def __setattr__(cls, key, value):
        if key in cls.__dict__:
            raise AttributeError(f"Cannot modify const member '{key}'")
        super().__setattr__(key, value)


class PrintColor(Enum):
    Red = "\033[91m"
    Green = "\033[92m"
    Yellow = "\033[93m"
    Blue = "\033[94m"
    Magenta = "\033[95m"
    Cyan = "\033[96m"
    White = "\033[97m"

def printColored(iText: str, iColor: PrintColor) -> None:
    """ Prints text in the specified color."""
    RESET_STR = "\033[0m"
    print(f"{iColor.value}{iText}{RESET_STR}")

def makeColored(iText: str, iColor: PrintColor) -> str:
    """ Returns text in the specified color."""
    RESET_STR = "\033[0m"
    return f"{iColor.value}{iText}{RESET_STR}"

def warning(iText: str) -> None:
    """ Prints a warning message in yellow color. Adds "Warning: " prefix."""
    printColored(f"Warning: {iText}", PrintColor.Yellow)

def error(iText: str) -> None:
    """ Prints an error message in red color and exits the program. Adds "Error: " prefix."""
    printColored(f"Error: {iText}", PrintColor.Red)
    sys.exit(1)

def status(iText: str) -> None:
    """ Prints an informational message in green color."""
    printColored(iText, PrintColor.Green)


def runCommand(iCommand: list[str]) -> None:
    print(makeColored("Running command: ", PrintColor.Cyan) + makeColored(f"{os.getcwd()}> ", PrintColor.Magenta) + makeColored(shlex.join(iCommand), PrintColor.Blue))
    subprocess.run(iCommand, check=True)