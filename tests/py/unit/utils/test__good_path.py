# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from pathlib import Path
import pytest
import sys

# Add seed project root to sys.path to enable importing "CMagneto.py.*".
CMAGNETO_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.insert(0, str(CMAGNETO_PROJECT_ROOT))
SEED_PROJECT_ROOT = CMAGNETO_PROJECT_ROOT / "ProjectRoot/"
sys.path.insert(0, str(SEED_PROJECT_ROOT))

from CMagneto.py.utils import Utils


@pytest.fixture(scope="module")
def dirCIAbs() -> Utils.GoodPath:
    """Returns the GoodPath instance for the absolute CI directory in the CMagneto project root."""
    return Utils.GoodPath(str(CMAGNETO_PROJECT_ROOT) + "/CI/")

def dirCIDotRel() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative dotted (stats with './') CI directory in the CMagneto project root."""
    return Utils.GoodPath("./CI/")

def dirCIRel() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative not-dotted (stats withot './') CI directory in the CMagneto project root."""
    return Utils.GoodPath("./CI/")

def test__dirCIAbsIsAbsolute(dirCIAbs: Utils.GoodPath):
    assert dirCIAbs.isAbsolute, f"Expected CI path to be absolute, got: {dirCIAbs.posixNormalized}"

def test__dirCIAbsIsDir(dirCIAbs: Utils.GoodPath):
    assert dirCIAbs.isDir, f"Expected CI to be treated as a directory: {dirCIAbs.posixNormalized}"

def test__dirCIAbsExists(dirCIAbs: Utils.GoodPath):
    assert dirCIAbs.exists(), f"CI directory should exist on disk: {dirCIAbs.posixNormalized}"

def test__dirCIAbsName(dirCIAbs: Utils.GoodPath):
    assert dirCIAbs.name == "CI", f"Expected CI name, got: {dirCIAbs.name}"

def test__dirCIAbsIsRelativeToCMagnetoProjectRoot(dirCIAbs: Utils.GoodPath):
    root = Utils.GoodPath(str(CMAGNETO_PROJECT_ROOT) + "/")
    rel = dirCIAbs.getRelativeTo(root)
    assert rel is not None, "CI should be relative to the project root"
    assert rel.posix == "CI", f"Expected relative path to be 'CI', got: {rel.posix}"