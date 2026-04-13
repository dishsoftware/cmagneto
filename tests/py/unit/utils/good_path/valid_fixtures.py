# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from cmagneto_project_root import *
from CMagneto.py.utils.good_path import GoodPath
import os
import pytest


@pytest.fixture(scope="module")
def dirCMagnetoProjectRoot() -> GoodPath:
    """Returns the absolute path to the CMagneto project root."""
    return GoodPath(CMAGNETO_PROJECT_ROOT_STR)

@pytest.fixture(scope="module")
def dirSeedProjectRoot() -> GoodPath:
    """Returns the absolute path to the seed project root."""
    return GoodPath(SEED_PROJECT_ROOT_STR)

@pytest.fixture(scope="module")
def dirCIAbs() -> GoodPath:
    """Returns the GoodPath instance for the absolute 'CI' directory in the seed project root."""
    return GoodPath(SEED_PROJECT_ROOT_STR + "CI/")

@pytest.fixture(scope="module")
def dirCIRel() -> GoodPath:
    """Returns the GoodPath instance for the relative not-dotted (stats without './') 'CI' directory."""
    return GoodPath("CI/")

@pytest.fixture(scope="module")
def dirCIRelDot() -> GoodPath:
    """Returns the GoodPath instance for the relative dotted     (stats with './'   ) 'CI' directory."""
    return GoodPath("./CI/")

@pytest.fixture(scope="module")
def filePipelineAbs() -> GoodPath:
    """Returns the GoodPath instance for the absolute file 'pipeline.yml' in the './CI/GitLab/' relative to the seed project root."""
    return GoodPath(SEED_PROJECT_ROOT_STR + "CI/GitLab/pipeline.yml")

@pytest.fixture(scope="module")
def filePipelineRel() -> GoodPath:
    """Returns the GoodPath instance for the relative not-dotted (stats without './') file 'pipeline.yml' in the './CI/GitLab/'."""
    return GoodPath("CI/GitLab/pipeline.yml")

@pytest.fixture(scope="module")
def filePipelineRelDot() -> GoodPath:
    """Returns the GoodPath instance for the relative dotted     (stats with './'   ) file 'pipeline.yml' in the './CI/GitLab/'."""
    return GoodPath("./CI/GitLab/pipeline.yml")

NONEXISTENT_A = "C:/nonexistentA/"

@pytest.fixture(scope="module")
def dirNonexistentAAbs() -> GoodPath:
    """Returns the GoodPath instance for the absolute dir 'C:/nonexistentA/`."""
    return GoodPath(NONEXISTENT_A)

def dirNonexistentAAbs_relTo_CMagnetoProjectRoot() -> str | None:
    if os.name != "nt": # Path("C:/a").anchor == '/' on Linux!
        return None
    if str(CMAGNETO_PROJECT_ROOT.anchor)[0] != 'C':
        return None
    return os.path.relpath(NONEXISTENT_A, CMAGNETO_PROJECT_ROOT_STR) + "/"

def dirNonexistentAAbs_relTo_SeedProjectRoot() -> str | None:
    if os.name != "nt": # Path("C:/a").anchor == '/' on Linux!
        return None
    if str(SEED_PROJECT_ROOT.anchor)[0] != 'C':
        return None
    return os.path.relpath(NONEXISTENT_A, SEED_PROJECT_ROOT_STR) + "/"

NONEXISTENT_B = "/nonexistentB/"

@pytest.fixture(scope="module")
def dirNonexistentBAbs() -> GoodPath:
    """Returns the GoodPath instance for the absolute dir '/nonexistentB/`."""
    return GoodPath(NONEXISTENT_B)

def dirNonexistentBAbs_relTo_CMagnetoProjectRoot() -> str | None:
    if os.name == "nt":
        return None
    if str(CMAGNETO_PROJECT_ROOT.anchor)[0] != '/':
        return None
    return os.path.relpath(NONEXISTENT_B, CMAGNETO_PROJECT_ROOT_STR) + "/"

def dirNonexistentBAbs_relTo_SeedProjectRoot() -> str | None:
    if os.name == "nt":
        return None
    if str(SEED_PROJECT_ROOT.anchor)[0] != '/':
        return None
    return os.path.relpath(NONEXISTENT_B, SEED_PROJECT_ROOT_STR) + "/"