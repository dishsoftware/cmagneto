# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
Unit tests for `CMagneto.py.utils.process`.

This module verifies the platform-specific logic used by `Process.applyEnvFromScript`.
It focuses on command construction, environment-output parsing, and shell detection
without depending on real external setup scripts or shell executables.
"""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import uuid

import pytest


CMAGNETO_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
SEED_PROJECT_ROOT = CMAGNETO_PROJECT_ROOT / "SeedProject"

cmagnetoProjectRootStr = str(CMAGNETO_PROJECT_ROOT)
seedProjectRootStr = str(SEED_PROJECT_ROOT)

if cmagnetoProjectRootStr not in sys.path:
    sys.path.insert(0, cmagnetoProjectRootStr)

if seedProjectRootStr not in sys.path:
    sys.path.insert(0, seedProjectRootStr)

from CMagneto.py.utils import process as process_module
from CMagneto.py.utils.process import Process


@pytest.fixture(autouse=True)
def clear_process_env_cache() -> None:
    Process._Process__cachedEnvironments.clear()


def test__apply_env_from_batch_script__imports_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(process_module.os, "name", "nt", raising=False)
    monkeypatch.setenv("ComSpec", "cmd.exe")
    monkeypatch.delenv("CMAG_TEST_BATCH", raising=False)

    captured: dict[str, object] = {}

    def fake_run(command: str, **kwargs: object) -> subprocess.CompletedProcess[str]:
        captured["command"] = command
        captured["kwargs"] = kwargs
        return subprocess.CompletedProcess(args=command, returncode=0, stdout="CMAG_TEST_BATCH=enabled\n")

    monkeypatch.setattr(process_module.subprocess, "run", fake_run)

    Process.applyEnvFromScript("toolchain setup.bat", ["x64", "Debug Config"])

    assert os.environ["CMAG_TEST_BATCH"] == "enabled"
    assert isinstance(captured["command"], str)
    assert captured["command"] == 'call "toolchain setup.bat" x64 "Debug Config" >nul && set'
    assert captured["kwargs"] == {
        "check": True,
        "capture_output": True,
        "text": True,
        "encoding": "utf-8",
        "errors": "replace",
        "shell": True,
        "executable": "cmd.exe",
    }


def test__apply_env_from_posix_script__parses_null_separated_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(process_module.os, "name", "posix", raising=False)
    monkeypatch.delenv("CMAG_TEST_POSIX", raising=False)
    monkeypatch.delenv("CMAG_TEST_MULTILINE", raising=False)

    captured: dict[str, object] = {}

    def fake_run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
        captured["command"] = command
        captured["kwargs"] = kwargs
        return subprocess.CompletedProcess(
            args=command,
            returncode=0,
            stdout="CMAG_TEST_POSIX=enabled\0CMAG_TEST_MULTILINE=line1\nline2\0",
        )

    monkeypatch.setattr(process_module.subprocess, "run", fake_run)
    monkeypatch.setattr(Process, "_resolvePosixShellExecutable", lambda _: "bash")

    Process.applyEnvFromScript("/tmp/setup-env.sh", ["clang"])

    assert os.environ["CMAG_TEST_POSIX"] == "enabled"
    assert os.environ["CMAG_TEST_MULTILINE"] == "line1\nline2"
    assert captured["command"] == [
        "bash",
        "-c",
        'script_path="$1"; shift; . "$script_path" "$@" >/dev/null; env -0',
        "bash",
        "/tmp/setup-env.sh",
        "clang",
    ]
    assert captured["kwargs"] == {
        "check": True,
        "capture_output": True,
        "text": True,
        "encoding": "utf-8",
        "errors": "replace",
    }


def test__make_env_import_invocation__powershell_uses_detected_executable(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(Process, "_findPowerShellExecutable", lambda: "pwsh")

    command, isNullSeparated, runWithShell = Process._makeEnvImportInvocation("setup.ps1", ("x64",))

    assert command == [
        "pwsh",
        "-NoLogo",
        "-NoProfile",
        "-Command",
        "$scriptPath = $args[0]; $scriptArgs = if ($args.Length -gt 1) { $args[1..($args.Length - 1)] } else { @() }; & $scriptPath @scriptArgs | Out-Null; Get-ChildItem Env: | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }",
        "setup.ps1",
        "x64",
    ]
    assert isNullSeparated is False
    assert runWithShell is False


def test__resolve_posix_shell_executable__uses_shebang() -> None:
    tempDirPath = CMAGNETO_PROJECT_ROOT / "tests" / "testProjects" / "_tmp_process_tests"
    tempDirPath.mkdir(exist_ok=True)
    scriptPath = tempDirPath / f"setup-env-{uuid.uuid4().hex}"

    try:
        scriptPath.write_text("#!/usr/bin/env bash\nexport TEST=1\n", encoding="utf-8")
        assert Process._resolvePosixShellExecutable(str(scriptPath)) == "bash"
    finally:
        if scriptPath.exists():
            scriptPath.unlink()
