# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from .log import Log
from pathlib import Path
from typing import Literal, TypeAlias, overload
import os
import shlex
import shutil
import subprocess


PathLikeStr: TypeAlias = os.PathLike[str] | str


class Process:
    __cachedEnvironments: dict[tuple[str, tuple[str, ...]], dict[str, str]] = {}
    __cachedExecutables: dict[tuple[str, ...], str | None] = {}

    @staticmethod
    def applyEnvFromScript(iScriptPath: PathLikeStr, iArgs: list[str] | tuple[str, ...] | None = None) -> None:
        """
        Runs an environment setup script and imports the environment variables it sets into the current Python process.

        Supported formats:
        - Windows batch scripts (`.bat`, `.cmd`) on Windows
        - PowerShell scripts (`.ps1`) when `pwsh` or `powershell.exe` is available
        - POSIX shell scripts (`.sh`, `.bash`, `.zsh`, or shebang-based scripts) on POSIX systems
        """
        scriptPath = os.fspath(iScriptPath)
        args = tuple(iArgs) if iArgs is not None else tuple()
        cacheKey = (scriptPath, args)

        cachedEnv = Process.__cachedEnvironments.get(cacheKey)
        if cachedEnv is None:
            command, usesNullSeparatedOutput, runWithShell = Process._makeEnvImportInvocation(scriptPath, args)
            if runWithShell:
                completed = subprocess.run(
                    command,
                    check=True,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    shell=True,
                    executable=os.environ.get("ComSpec", "cmd.exe"),
                )
            else:
                completed = subprocess.run(
                    command,
                    check=True,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                )

            cachedEnv = Process._parseEnvironmentOutput(completed.stdout, usesNullSeparatedOutput)

            Process.__cachedEnvironments[cacheKey] = cachedEnv

        os.environ.update(cachedEnv)

    @staticmethod
    def _makeEnvImportInvocation(scriptPath: str, args: tuple[str, ...]) -> tuple[str | list[str], bool, bool]:
        """
        Builds the subprocess invocation for importing environment variables from a setup script.

        Returns a tuple of:
        - command: command string or argv list to pass to `subprocess.run`.
          Different script formats require different invocation styles.
        - usesNullSeparatedOutput: whether the command prints environment entries separated by `\\0`.
          This is needed because POSIX `env -0` output must be parsed differently from line-based output.
        - runWithShell: whether the command must be executed with `shell=True`.
          This is needed because shell syntax such as `call`, `&&`, and output redirection is required for batch scripts.
        """
        scriptSuffix = Path(scriptPath).suffix.lower()

        if scriptSuffix in (".bat", ".cmd"):
            if os.name != "nt":
                raise RuntimeError("Windows batch environment scripts are supported on Windows only.")

            quotedCommand = subprocess.list2cmdline([scriptPath, *args])
            return (
                f"call {quotedCommand} >nul && set",
                False,
                True,
            )

        if scriptSuffix == ".ps1":
            powerShellExecutable = Process._findPowerShellExecutable()
            if powerShellExecutable is None:
                raise RuntimeError("PowerShell environment scripts require `pwsh` or `powershell.exe` to be available.")

            powerShellCommand = (
                "$scriptPath = $args[0]; "
                "$scriptArgs = if ($args.Length -gt 1) { $args[1..($args.Length - 1)] } else { @() }; "
                "& $scriptPath @scriptArgs | Out-Null; "
                "Get-ChildItem Env: | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }"
            )
            return (
                [powerShellExecutable, "-NoLogo", "-NoProfile", "-Command", powerShellCommand, scriptPath, *args],
                False,
                False,
            )

        if os.name != "posix":
            raise RuntimeError(
                f"Unsupported environment script format for this platform: '{scriptPath}'. "
                "Use a Windows batch or PowerShell script on Windows."
            )

        shellExecutable = Process._resolvePosixShellExecutable(scriptPath)
        posixCommand = 'script_path="$1"; shift; . "$script_path" "$@" >/dev/null; env -0'
        return (
            [shellExecutable, "-c", posixCommand, shellExecutable, scriptPath, *args],
            True,
            False,
        )

    @staticmethod
    def _parseEnvironmentOutput(iOutput: str, iNullSeparated: bool) -> dict[str, str]:
        cachedEnv: dict[str, str] = {}
        entries = iOutput.split("\0") if iNullSeparated else iOutput.splitlines()
        for entry in entries:
            if "=" not in entry:
                continue
            key, value = entry.split("=", 1)
            cachedEnv[key] = value
        return cachedEnv

    @staticmethod
    def _findPowerShellExecutable() -> str | None:
        return Process.findFirstExecutable(("pwsh", "powershell.exe", "powershell"))

    @staticmethod
    def findExecutable(iExecutableName: str) -> str | None:
        cacheKey = (iExecutableName,)
        if cacheKey not in Process.__cachedExecutables:
            Process.__cachedExecutables[cacheKey] = shutil.which(iExecutableName)
        return Process.__cachedExecutables[cacheKey]

    @staticmethod
    def findFirstExecutable(iExecutableNames: tuple[str, ...]) -> str | None:
        if iExecutableNames not in Process.__cachedExecutables:
            resolvedExecutablePath: str | None = None
            for executableName in iExecutableNames:
                resolvedExecutablePath = Process.findExecutable(executableName)
                if resolvedExecutablePath is not None:
                    break
            Process.__cachedExecutables[iExecutableNames] = resolvedExecutablePath
        return Process.__cachedExecutables[iExecutableNames]

    @staticmethod
    def _resolvePosixShellExecutable(scriptPath: str) -> str:
        scriptSuffix = Path(scriptPath).suffix.lower()
        suffixToShell = {
            ".sh": "sh",
            ".bash": "bash",
            ".zsh": "zsh",
            ".ksh": "ksh",
        }

        shellName = suffixToShell.get(scriptSuffix)
        if shellName is None:
            shellName = Process._shellFromShebang(scriptPath) or "sh"

        return shellName

    @staticmethod
    def _shellFromShebang(scriptPath: str) -> str | None:
        try:
            with open(scriptPath, "r", encoding="utf-8", errors="replace") as scriptFile:
                firstLine = scriptFile.readline().strip()
        except OSError:
            return None

        if not firstLine.startswith("#!"):
            return None

        shebangTokens = shlex.split(firstLine[2:].strip(), posix=True)
        if not shebangTokens:
            return None

        executableToken = Path(shebangTokens[0]).name
        if executableToken == "env" and len(shebangTokens) > 1:
            return Path(shebangTokens[1]).name

        return executableToken

    @overload
    @staticmethod
    def runCommand(
            iCommand: list[str],
            iCWD: PathLikeStr | None = None,
            *,
            iCheck: bool = True,
            iCaptureOutput: Literal[False] = False
        ) -> None:
        ...

    @overload
    @staticmethod
    def runCommand(
            iCommand: list[str],
            iCWD: PathLikeStr | None = None,
            *,
            iCheck: bool = True,
            iCaptureOutput: Literal[True]
        ) -> subprocess.CompletedProcess[str]:
        ...

    @staticmethod
    def runCommand(
            iCommand: list[str],
            iCWD: PathLikeStr | None = None,
            *,
            iCheck: bool = True,
            iCaptureOutput: bool = False
        ) -> subprocess.CompletedProcess[str] | None:
        currentCWD = os.getcwd()
        if iCWD is not None:
            os.chdir(iCWD)

        print(
            Log.makeColored("Running command: ", Log.PrintColor.Cyan) + \
            Log.makeColored(f"{os.getcwd()}> ", Log.PrintColor.Magenta) + \
            Log.makeColored(shlex.join(iCommand), Log.PrintColor.Blue),
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
                env=os.environ.copy(),
            )
            assert process.stdout is not None # For type checker.

            capturedLines: list[str] = []
            for line in process.stdout:
                print(line, end='') # Print from the sub process `stdout` stream in real time. Each line already has a endline.
                if iCaptureOutput:
                    capturedLines.append(line) # Output is requested. Save captured lines and return them later as a batch placed inside a `CompletedProcess` entity.

            returnCode = process.wait()
            if iCheck and returnCode != 0:
                Log.printColored(f"{Log.LOG_MESSAGE_PREFIX}Command failed with error.", Log.PrintColor.Red)
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
