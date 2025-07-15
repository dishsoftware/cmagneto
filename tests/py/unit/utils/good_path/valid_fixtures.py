# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from cmagneto_project_root import *
from CMagneto.py.utils import Utils
import os
import pytest


@pytest.fixture(scope="module")
def dirCMagnetoProjectRoot() -> Utils.GoodPath:
    """Returns the absolute path to the CMagneto project root."""
    return Utils.GoodPath(CMAGNETO_PROJECT_ROOT_STR)

@pytest.fixture(scope="module")
def dirSeedProjectRoot() -> Utils.GoodPath:
    """Returns the absolute path to the seed project root."""
    return Utils.GoodPath(SEED_PROJECT_ROOT_STR)

@pytest.fixture(scope="module")
def dirCIAbs() -> Utils.GoodPath:
    """Returns the GoodPath instance for the absolute 'CI' directory in the seed project root."""
    return Utils.GoodPath(SEED_PROJECT_ROOT_STR + "CI/")

@pytest.fixture(scope="module")
def dirCIRel() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative not-dotted (stats without './') 'CI' directory."""
    return Utils.GoodPath("CI/")

@pytest.fixture(scope="module")
def dirCIRelDot() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative dotted     (stats with './'   ) 'CI' directory."""
    return Utils.GoodPath("./CI/")

@pytest.fixture(scope="module")
def filePipelineAbs() -> Utils.GoodPath:
    """Returns the GoodPath instance for the absolute file 'pipeline.yml' in the './CI/GitLab/' relative to the seed project root."""
    return Utils.GoodPath(SEED_PROJECT_ROOT_STR + "CI/GitLab/pipeline.yml")

@pytest.fixture(scope="module")
def filePipelineRel() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative not-dotted (stats without './') file 'pipeline.yml' in the './CI/GitLab/'."""
    return Utils.GoodPath("CI/GitLab/pipeline.yml")

@pytest.fixture(scope="module")
def filePipelineRelDot() -> Utils.GoodPath:
    """Returns the GoodPath instance for the relative dotted     (stats with './'   ) file 'pipeline.yml' in the './CI/GitLab/'."""
    return Utils.GoodPath("./CI/GitLab/pipeline.yml")

@pytest.fixture(scope="module")
def dirNonexistentAAbs() -> Utils.GoodPath:
    """Returns the GoodPath instance for the absolute dir 'C:/nonexistentA/`."""
    return Utils.GoodPath("C:/nonexistentA/")

def dirNonexistentAAbs_relTo_CMagnetoProjectRoot() -> str | None:
    if str(CMAGNETO_PROJECT_ROOT.anchor)[0] != 'C':
        return None
    return os.path.relpath("C:/nonexistentA/", CMAGNETO_PROJECT_ROOT_STR) + "/"

def dirNonexistentAAbs_relTo_SeedProjectRoot() -> str | None:
    if str(SEED_PROJECT_ROOT.anchor)[0] != 'C':
        return None
    return os.path.relpath("C:/nonexistentA/", SEED_PROJECT_ROOT_STR) + "/"

@pytest.fixture(scope="module")
def dirNonexistentBAbs() -> Utils.GoodPath:
    """Returns the GoodPath instance for the absolute dir '/nonexistentB/`."""
    return Utils.GoodPath("/nonexistentB/")

def dirNonexistentBAbs_relTo_CMagnetoProjectRoot() -> str | None:
    if str(CMAGNETO_PROJECT_ROOT.anchor)[0] != '/':
        return None
    relPath = os.path.relpath("C:/nonexistentB/", CMAGNETO_PROJECT_ROOT_STR) + "/"
    print(f"{relPath}")

def dirNonexistentBAbs_relTo_SeedProjectRoot() -> str | None:
    if str(SEED_PROJECT_ROOT.anchor)[0] != '/':
        return None
    relPath = os.path.relpath("C:/nonexistentB/", SEED_PROJECT_ROOT_STR) + "/"
    print(f"{relPath}")