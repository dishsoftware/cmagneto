# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

from .log import Log
import os
import shlex
import subprocess


class Process:
    @staticmethod
    def runCommand(iCommand: list[str], iCWD: os.PathLike | str | None = None, *, iCheck: bool = True, iCaptureOutput: bool = False) -> subprocess.CompletedProcess | None:
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
            )
            assert process.stdout is not None # For type checker.

            capturedLines = []
            for line in process.stdout:
                print(line, end='') # Print from the sub process `stdout` stream in real time. Each line already has a endline.
                if iCaptureOutput:
                    capturedLines.append(line) # Output is requested. Save captured lines and return them later as a batch placed inside a `CompletedProcess` entity.

            returnCode = process.wait()
            if iCheck and returnCode != 0:
                Log.printColored(f"{Log.__LOG_MESSAGE_PREFIX}Command failed with error.", Log.PrintColor.Red)
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