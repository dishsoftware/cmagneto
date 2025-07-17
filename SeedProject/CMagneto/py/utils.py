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
from enum import Enum
from pathlib import Path
from typing import cast, Iterator, NoReturn
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
    def runCommand(iCommand: list[str], iCWD: os.PathLike | str | None = None, *, iCheck: bool = True, iCaptureOutput: bool = False) -> subprocess.CompletedProcess | None:
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
                nullCharASCINum = ord('\0')
                forbiddenSubstrings.add(
                    f"item name '{iItemName}' contains `/`, `\\`, `:` or null character (ASCII {nullCharASCINum})"
                )
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
                if itemName == "": # '/p//' is split into '', 'p', '' and ''. # Allow consecutive '/'.
                    continue
                if itemIndex == 0 and ":" in itemName:
                    if not (len(itemName) == 2 and itemName[0].isalpha()):
                        forbiddenSubstrings.add(f"invalid drive descriptor: `{itemName}`")
                    continue
                forbiddenSubstrings.update(Utils.GoodPath.getForbiddenSubstringsInName(itemName))
            return forbiddenSubstrings

        @staticmethod
        def getCWD() -> Utils.GoodPath:
            return Utils.GoodPath(os.getcwd(), iForceDir=True)

        @staticmethod
        def fromPath(iPath: Path, iIsDir: bool) -> Utils.GoodPath:
            """
            Caution:
                Path classifies path string system-depently. E.g.:
                - '/a' is a relative path on Windows;
                - trailing path separator is discarded on Path.normalize();
                - etc.
            """
            return Utils.GoodPath(str(iPath), iIsDir)

        def __init__(self, iPath: str | Utils.GoodPath, iForceDir: bool = False):
            if isinstance(iPath, Utils.GoodPath):
                iPath = iPath.raw

            """If iForceDir, creates a dir path, even if trailing '/' is missing."""
            if iForceDir:
                if len(iPath) > 0 and iPath[-1] != '/':
                    iPath += '/'

            forbiddenSubstrings = Utils.GoodPath.getForbiddenSubstringsInPath(iPath)
            if len(forbiddenSubstrings) != 0:
                msg = Utils.makeIndented(';\n'.join(forbiddenSubstrings), '\t')
                raise ValueError(f"iRawPath '{iPath}' is not good. Issues:\n{msg}")
            self.__raw: str = iPath

            # Normalize '\' with '/'.
            rawPath = iPath.replace('\\', '/')
            # Replace consecutive '/' with sigular '/'.
            rawPath = re.sub(r"/+", "/", rawPath)

            if rawPath.endswith(':'): # Allow such a mistake.
                pawPath += '/'

            itemNames = rawPath.split('/') # Is not empty, because empty strings are prohibited by Utils.GoodPath.getForbiddenSubstringsInPath().
            if len(itemNames[0]) == 2 and itemNames[0][1] == ':':
                itemNames[0] = itemNames[0].upper()

            posixPath = '/'.join(itemNames)
            self.__posix = posixPath

            posixNormPath = os.path.normpath(self.__posix).replace('\\', '/') # TODO Get rid of os.path dependency. Does it check if path is above anchor (FS root)?
            posixNormPath += ('/' if self.__posix.endswith('/') and not posixNormPath.endswith('/') else '')
            self.__posixNormalized = posixNormPath

            if self.__posixNormalized.startswith('/'):
                self.__isAbsolute = True
                self.__platform = Utils.GoodPath.Platform.Unix
                self.__isAnchor = len(self.__posixNormalized) == 1
            elif len(self.__posixNormalized) > 1 and self.__posixNormalized[1] == ':':
                self.__isAbsolute = True
                self.__platform = Utils.GoodPath.Platform.Windows
                self.__isAnchor = len(self.__posixNormalized) == 3
            else:
                self.__isAbsolute = False
                self.__platform = Utils.GoodPath.Platform.Relative
                self.__isAnchor = False

            self.__isDir = self.__posixNormalized[-1] == '/'
            self.__name = itemNames[-2] if self.__isDir else itemNames[-1] # The '/p/' is split into '', 'p', ''; '/p' is split into '', 'p'.

        def __fspath__(self) -> str:
            return self.__posixNormalized

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
        def isAnchor(self) -> bool:
            """FS root."""
            return self.__isAnchor

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
            return False

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
            parent = self.getParent()
            if parent is not None:
                return parent / newName
            else:
                return newName

        def getAnchor(self) -> Utils.GoodPath | None:
            if not self.isAbsolute:
                return None
            if self.isAnchor:
                return self
            if self.platform == Utils.GoodPath.Platform.Unix:
                return Utils.GoodPath('/')
            elif self.platform == Utils.GoodPath.Platform.Windows:
                return Utils.GoodPath(self.posixNormalized[:3])

        def getParent(self) -> Utils.GoodPath | None:
            if self.isAnchor:
                return None
            itemNames = self.posixNormalized.split("/")
            if self.isDir:
                itemNames = itemNames[:-2] # The last is empty string.
            else:
                itemNames = itemNames[:-1]
            return Utils.GoodPath('/'.join(itemNames) + '/')

        def getRelativeTo(self, iOther: Utils.GoodPath | str, iAllowAscend: bool = False) -> Utils.GoodPath | None:
            """
            This relative to other.
            Relative self is relative to any dir.
            Does not take into account CWD.
            """
            if isinstance(iOther, str):
                iOther = Utils.GoodPath(iOther)
            if not iOther.isDir:
                return None
            if self.isAbsolute and iOther.isRelative:
                return None
            if self.isAbsolute and iOther.isAbsolute and self.getAnchor() != iOther.getAnchor():
                return None
            # TODO If both are relative, how does the os.path.relpath behaves?
            relPathStr = None
            if self.isRelative:
                relPathStr = self.posixNormalized
            else:
                # TODO Get rid of os.path dependency.
                relPathStr = os.path.relpath(self.posixNormalized, iOther.posixNormalized) # If seld.isRelative, treats self.posixNormalized relative to CWD.
            components = re.split(r'[\\/]', relPathStr)
            if not iAllowAscend and ".." in components:
                return None
            if self.isDir and relPathStr[-1] != '/':
                relPathStr += '/'
            return Utils.GoodPath(relPathStr)

        def isRelativeTo(self, iOther: Utils.GoodPath | str, iAllowAscend: bool = False) -> bool:
            """
            This relative to other.
            Relative self is relative to any dir.
            Does not take into account CWD.
            """
            return self.getRelativeTo(iOther, iAllowAscend) != None

        def isDescendant(self, iOther: Utils.GoodPath | str) -> bool:
            """
            This relative to other.
            Relative self is relative to any dir.
            Does not take into account CWD.
            """
            return self.getRelativeTo(iOther, iAllowAscend=False) != None

        def checkIfRelativeAndDescendantAndGetAbsPath(self, iSelfDescription: str, iOther: Utils.GoodPath | str, iOtherDescription: str, iExitNotRaise = True) -> Utils.GoodPath:
            res = self.getRelativeTo(iOther, iAllowAscend=False)
            if res is not None:
                return res
            msg = f"{iSelfDescription} '{self}' must be relative and descendant of {iOtherDescription} '{iOther}'."
            if iExitNotRaise:
                Utils.error(msg)
            else:
                raise ValueError(msg)

        def getAscendant(self, iNumOfAscends: int = 1) -> Utils.GoodPath | None:
            if (iNumOfAscends < 0):
                raise ValueError(f"iNumOfAscends must not be negative.")
            if iNumOfAscends == 0:
                return Utils.GoodPath(self)
            parent = self.getParent()
            if parent is None:
                return None
            if iNumOfAscends == 1:
                return parent
            return Utils.GoodPath(parent.posixNormalized + "../" * (iNumOfAscends - 1))

        def exists(self) -> bool | None:
            """
            CWD is not taken into account, thus
            if self is relative, returns None.
            """
            if self.isRelative:
                return None
            if not os.path.exists(self.posixNormalized):
                return False
            isDirInFS = os.path.isdir(self.posixNormalized)
            if self.isDir and isDirInFS:
                return True
            elif not self.isDir and not isDirInFS:
                return True
            else:
                return False # Item types differ.

        def iterdir(self) -> Iterator[Utils.GoodPath]:
            if not self.isDir or self.isRelative:
                raise NotADirectoryError(f"'{self.raw}' is not an absolute directory.")
            return (Utils.GoodPath(child.as_posix(), child.is_dir()) for child in Path(self).iterdir())

        def rglob(self, iPattern: str) -> Iterator[Utils.GoodPath]:
            """Recursively yield GoodPath objects matching the pattern."""
            if not self.isDir:
                raise NotADirectoryError(f"`{self.raw}` is not a directory")

            for matchedDescendant in Path(self).rglob(iPattern):
                yield Utils.GoodPath(matchedDescendant.as_posix(), matchedDescendant.is_dir())

        def delete(self) -> None:
            if self.isRelative:
                raise FileNotFoundError(f"'{self.raw}' is relative path.")
            if self.isDir:
                shutil.rmtree(self)
            else:
                Path(self).unlink()

        def create(self, iExistsOk: bool = True) -> None:
            if self.isRelative:
                raise FileNotFoundError(f"'{self.raw}' is relative path.")
            if self.isDir:
                Path(self).mkdir(exist_ok=iExistsOk, parents=True)
            else:
                parent = self.getParent()
                if parent is None:
                    return
                parent.create(iExistsOk)  # Ensure parent dirs exist.
                Path(self).touch(exist_ok=iExistsOk)  # Create the file if it doesn't exist.

        def isFile(self) -> bool:
            if self.isRelative:
                raise FileNotFoundError(f"'{self.raw}' is relative path.")
            return Path(self).is_file()

        def isSymLink(self) -> bool:
            if self.isRelative:
                raise FileNotFoundError(f"'{self.raw}' is relative path.")
            return Path(self).is_symlink()

        @staticmethod
        def prepareDir(iDir: Path) -> None:
            """Creates/cleans iDir."""
            if iDir.exists():
                shutil.rmtree(iDir)
            os.makedirs(iDir, exist_ok=True)

        @staticmethod
        def findInDirFileWithNameWE(iDir: Utils.GoodPath | Path, iFileNameWE: str) -> Path | None:
            """
            Returns fileName of a file with the iFileNameWE (name without extension), which is found first in the iDir (non-recursively).
            """
            if isinstance(iDir, Utils.GoodPath):
                iDir = Path(iDir)
            for item in iDir.iterdir():
                if item.is_file() and iFileNameWE == item.stem:
                    return Path(item.name)
            return None
