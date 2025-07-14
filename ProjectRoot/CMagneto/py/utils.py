# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from enum import Enum
from pathlib import Path
from typing import cast, NoReturn
import os
import re
import shlex
import shutil
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
    __CMAGNETO_FRAMEWORK_ROOT: Path = __PROJECT_ROOT / "CMagneto/"

    @staticmethod
    def projectRoot() -> Path:
        """Returns absolute path of this project root."""
        return Utils.__PROJECT_ROOT

    @staticmethod
    def CMagnetoFrameworkRoot() -> Path:
        """Returns absolute path of the CMagneto framework root inside this project."""
        return Utils.__CMAGNETO_FRAMEWORK_ROOT


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

    @staticmethod
    def prepareDir(iDir: Path) -> None:
        """Creates/cleans iDir."""
        if iDir.exists():
            shutil.rmtree(iDir)

        os.makedirs(iDir, exist_ok=True)

    @staticmethod
    def findInDirFileWithNameWE(iDir: Path, iFileNameWE: str) -> Path | None:
        """
        Returns fileName of a file with the iFileNameWE (name without extension), which is found first in the iDir (non-recursively).
        """
        for item in iDir.iterdir():
            if item.is_file() and iFileNameWE == item.stem:
                return Path(item.name)
        return None


    class PathType(Enum):
        Absolute = "absolute",
        Relative = "relative",
        DontCare = "absolute or relative"


    @staticmethod
    def getPathRelativeToBaseDir(iPath: Path, iBaseDir: Path, iPathType: PathType = PathType.DontCare, iRequirePathUnderBase: bool = True):
        """Does not check whether the files or directories actually exist on the file system."""
        pathIsAbsolute = iPath.is_absolute()

        if iPathType == Utils.PathType.Relative and pathIsAbsolute:
            Utils.error(f"iPath must be relative. iPath = `{iPath}`.")
        elif iPathType == Utils.PathType.Absolute and not pathIsAbsolute:
            Utils.error(f"iPath must be absolute. iPath = `{iPath}`.")

        if not pathIsAbsolute:
            if not iRequirePathUnderBase:
                return iPath
            iPath = (iBaseDir / iPath).resolve()

        iBaseDir = iBaseDir.resolve()

        try:
            return iPath.relative_to(iBaseDir)
        except ValueError:
            if iRequirePathUnderBase:
                Utils.error(f"iPath must be under iBaseDir\n:\tiPath = `{iPath}`\n\tiBaseDir = `{iBaseDir}`")
            return Path(os.path.relpath(iPath, iBaseDir))


    class GoodPath(metaclass=ConstMetaClass):
        """
        Behaves platform-independently.
        Uses posix '/' item separator. Prohibits any characters and substrings, which are prohibited on Windows and Unix.
        Treats 'p' and './p' relative paths on all platforms.
        Treats '/p' and 'C:/p' as absolute paths on all platforms.
        Treats 'p' as a file and 'p/' a as dir.
        Case sensitive on all platforms, except while comparing Windows drive descriptors.
        """

        class Platform(Enum):
            Unix = "Unix",
            Windows = "Windows",
            Relative = "Relative" # Impossible to distinguish.

        __WINDOWS_FORBIDDEN_PATH_CHARS_EXCEPT_CONTROL: set[str] = set('<>"|?*')
        # + Control chars: ASCII [0; 31] + ":" in item names (except drive descriptors).

        # Reserved Windows names (case-insensitive).
        __WINDOWS_RESERVED_NAMES = {
            "CON", "PRN", "AUX", "NUL",
            *(f"COM{i}" for i in range(1, 10)),
            *(f"LPT{i}" for i in range(1, 10)),
        }

        @staticmethod
        def getForbiddenSubstringsInName(iItemName: str) -> set[str]:
            """Returns set of forbidden substrings. Each string in the set may also contain explanation."""
            forbiddenSubstrings: set[str] = set()
            if iItemName == "" or iItemName.isspace():
                forbiddenSubstrings.add("item name is empty or whitespace")
                return forbiddenSubstrings
            if iItemName.upper() in Utils.GoodPath.__WINDOWS_RESERVED_NAMES:
                forbiddenSubstrings.add(f"reserved Windows item name `{iItemName}`")
                return forbiddenSubstrings
            if any(char in iItemName for char in ['\\', '/', ':', '\0']):
                forbiddenSubstrings.add(f"item name '{iItemName}' contains `/`, `\\`, `:` or null character (ASCII {ord('\0')})")
            forbiddenSubstrings.update({char for char in iItemName if char in Utils.GoodPath.__WINDOWS_FORBIDDEN_PATH_CHARS_EXCEPT_CONTROL})
            forbiddenSubstrings.update({f"ASCII {ord(char)}" for char in iItemName if ord(char) < 32})
            return forbiddenSubstrings

        @staticmethod
        def getForbiddenSubstringsInPath(iPath: str) -> set[str]:
            """Returns set of forbidden substrings. Each string in the set may also contain explanation."""
            # Split by either '\' or '/'
            itemNames = cast(list[str], re.split(r'[\\/]', iPath))

            forbiddenSubstrings: set[str] = set()
            for itemIndex, itemName in enumerate(itemNames):
                if (itemIndex == 0 or itemIndex == len(itemNames) - 1) and itemName == "": # '/p/' is split into '', 'p' and ''.
                    continue
                if itemIndex == 0 and ":" in itemName:
                    if not (len(itemName) == 2 and itemName[0].isalpha()):
                        forbiddenSubstrings.add(f"invalid drive descriptor: `{itemName}`")
                    continue
                forbiddenSubstrings.update(Utils.GoodPath.getForbiddenSubstringsInName(itemName))
            return forbiddenSubstrings

        def __init__(self, iRawPath: str):
            forbiddenSubstrings = Utils.GoodPath.getForbiddenSubstringsInPath(iRawPath)
            if len(forbiddenSubstrings) != 0:
                raise ValueError(f"iRawPath is not good. Issues:\n{Utils.makeIndented(';\n'.join(forbiddenSubstrings), '\t')}")

            self.__raw: str = iRawPath
            # Normalize Windows drive descriptor.
            iRawPath = iRawPath.replace('\\', '/')
            if iRawPath[-1] == ':':
                iRawPath += '/'
            itemNames = iRawPath.split('/') # Is not empty, because empty strings are prohibited by Utils.GoodPath.getForbiddenSubstringsInPath().
            if len(itemNames[0]) == 2 and itemNames[0][1] == ':':
                itemNames[0] = itemNames[0].upper()

            self.__posix = iRawPath
            self.__posixNormalized = os.path.normpath(self.__posix).replace('\\', '/') + ('/' if iRawPath.endswith('/') else '')

            if self.__posixNormalized.startswith('/'):
                self.__isAbsolute = True
                self.__platform = Utils.GoodPath.Platform.Unix
                self.__isRoot = len(self.__posixNormalized) == 1
            elif len(self.__posixNormalized) > 1 and self.__posixNormalized[1] == ':':
                self.__isAbsolute = True
                self.__platform = Utils.GoodPath.Platform.Windows
                self.__isRoot = len(self.__posixNormalized) == 3
            else:
                self.__isAbsolute = False
                self.__platform = Utils.GoodPath.Platform.Relative
                self.__isRoot = False

            self.__isDir = self.__posixNormalized[-1] == '/'
            self.__name = itemNames[-2] if self.__isDir else itemNames[-1] # The '/p/' is split into '', 'p', ''; '/p' is split into '', 'p'.

        def __str__(self):
            return str(self.__posixNormalized)

        def __repr__(self):
            return f"{self.__class__.__qualname__}(raw='{self.__raw}', posixNormalized={repr(self.__posixNormalized)})"

        @property
        def raw(self) -> str:
            return self.__raw

        @property
        def posix(self) -> str:
            return self.__posix

        @property
        def posixNormalized(self) -> str:
            return self.__posixNormalized

        @property
        def isAbsolute(self) -> bool:
            return self.__isAbsolute

        @property
        def isRelative(self) -> bool:
            return not self.__isAbsolute

        @property
        def platform(self) -> Utils.GoodPath.Platform:
            return self.__platform

        @property
        def isRoot(self) -> bool:
            return self.__isRoot

        @property
        def isDir(self) -> bool:
            return self.__isDir

        @property
        def name(self) -> str:
            return self.__name

        def __eq__(self, iOther) -> bool:
            if isinstance(iOther, Utils.GoodPath):
                return self.__posixNormalized == iOther.__posixNormalized
            if isinstance(iOther, str):
                iOther = Utils.GoodPath(iOther)
                return self.__posixNormalized == iOther.__posixNormalized
            raise ValueError(f"{self.__class__.__qualname__}: iOther is not instance of {self.__class__.__qualname__} or str.")

        def __truediv__(self, iOther: Utils.GoodPath | str) -> Utils.GoodPath:
            if not self.isDir:
                raise ValueError(f"{self.__class__.__qualname__}: self is file: '{self.raw}'")
            if isinstance(iOther, str):
                iOther = Utils.GoodPath(iOther)
            if iOther.isAbsolute:
                raise ValueError(f"{self.__class__.__qualname__}: iOther is absolute: '{iOther.raw}'")
            return Utils.GoodPath(self.posixNormalized + iOther.posixNormalized)

        def ext(self, iNumOfExtComponents: int = 1) -> str:
            """
            Returns:
            - 'p.tar.gz', iNumOfExtComponents < 1 --> ''
            - 'p.tar.gz', iNumOfExtComponents = 1 --> '.gz'
            - 'p.tar.gz', iNumOfExtComponents = 2 --> '.tar.gz'
            - 'p.tar.gz', iNumOfExtComponents > 2 --> 'p.tar.gz'
            - The same with dirs! The trailing '/' is discarded.
            """
            if iNumOfExtComponents < 1:
                return ''
            components = self.name.split(".")
            if len(components) <= iNumOfExtComponents:
                return self.name
            return '.'.join(components[-iNumOfExtComponents : ])

        def nameWE(self, iNumOfExtComponents: int = 1) -> str:
            """
            Returns name without extension:
            - 'p.tar.gz', iNumOfExtComponents < 1 --> 'p.tar.gz'
            - 'p.tar.gz', iNumOfExtComponents = 1 --> 'p.tar'
            - 'p.tar.gz', iNumOfExtComponents = 2 --> 'p'
            - 'p.tar.gz', iNumOfExtComponents > 2 --> ''
            - The same with dirs! The trailing '/' is discarded.
            """
            if iNumOfExtComponents < 1:
                return self.name
            components = self.name.split(".")
            if len(components) <= iNumOfExtComponents:
                return ''
            return '.'.join(components[ : len(components) - iNumOfExtComponents])

        def replaceExt(self, iNewExt: str, iNumOfExtComponentsToDiscard: int = 1) -> Utils.GoodPath:
            """Resulting path Platform depends on whether iNewWExt ends with '/'."""
            nameWEStr = self.nameWE(iNumOfExtComponentsToDiscard)
            newName = Utils.GoodPath(nameWEStr + (iNewExt if iNewExt.startswith('.') else '.' + iNewExt))
            parent = self.parent()
            if parent is not None:
                return parent / newName
            else:
                return newName

        def getRoot(self) -> Utils.GoodPath | None:
            if not self.isAbsolute:
                return None
            if self.isRoot:
                return self
            if self.platform == Utils.GoodPath.Platform.Unix:
                return Utils.GoodPath('/')
            elif self.platform == Utils.GoodPath.Platform.Windows:
                return Utils.GoodPath(self.posixNormalized[:3])

        def parent(self) -> Utils.GoodPath | None:
            if self.isRoot:
                return None
            itemNames = self.posixNormalized.split("/")
            if self.isDir:
                itemNames = itemNames[:-3] # The last is empty string.
            else:
                itemNames = itemNames[:-2]
            return Utils.GoodPath('/'.join(itemNames) + '/')

        def getRelativeTo(self, iOther: Utils.GoodPath | str, iAllowAscend: bool = False) -> Utils.GoodPath | None:
            """This relative to other."""
            if isinstance(iOther, str):
                iOther = Utils.GoodPath(iOther)
            if not iOther.isDir:
                return None
            if self.isAbsolute and iOther.isRelative:
                return None
            relPathStr = os.path.relpath(self.posixNormalized, iOther.posixNormalized)
            components = re.split(r'[\\/]', relPathStr)
            if not iAllowAscend and ".." in components:
                return None
            return Utils.GoodPath(relPathStr)

        def isRelativeTo(self, iOther: Utils.GoodPath | str, iAllowAscend: bool = False) -> bool:
            return self.getRelativeTo(iOther, iAllowAscend) != None

        def exists(self) -> bool:
            if not os.path.exists(self.posixNormalized):
                return False
            isDirInFS = os.path.isdir(self.posixNormalized)
            if self.isDir and isDirInFS:
                return True
            elif not self.isDir and not isDirInFS:
                return True
            else:
                return False # Item types differ.
