# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import annotations
from valid_fixtures import *
import pytest


@pytest.mark.parametrize(
    #                             |           |       |       |                            |                           | '..' allowed in the resulting relative path.  |                       | '..' allowed in the resulting relative path.| '..' allowed in the resulting relative path.|
    #                             |           |       |       |                            |                           | Relative path is appended to any dir path.    |                       | Relative path is appended to any dir path.  | Relative path to relative dir './CI/'.      |
    #                             |           |       |       |                            |                           | CWD is not taken into account.                |                       | CWD is not taken into account.              | CWD is not taken into account.              |
    #                             |           |       |       |                            |                           |                                               |                       |                                             |                                             |
    "pathFixtureName              , isAbsolute, isDir , exists, name                       , isUnderCMagnetoProjectRoot, relPathToCMagnetoProjectRoot                  , isUnderSeedProjectRoot, relPathToSeedProjectRoot                    , relPathToRelDirCI                           ",
    [
        ("dirCMagnetoProjectRoot" , True      , True  , True  , CMAGNETO_PROJECT_ROOT.name , True                      , "./"                                          , False                 , "../"                                       , None                                        ),
        ("dirSeedProjectRoot"     , True      , True  , True  , "ProjectRoot"              , True                      , "ProjectRoot/"                                , True                  , "./"                                        , None                                        ),
        ("dirCIAbs"               , True      , True  , True  , "CI"                       , True                      , "ProjectRoot/CI/"                             , True                  , "CI/"                                       , None                                        ),
        ("dirCIRel"               , False     , True  , None  , "CI"                       , True                      , "CI/"                                         , True                  , "CI/"                                       , "./"                                        ),
        ("dirCIRelDot"            , False     , True  , None  , "CI"                       , True                      , "CI/"                                         , True                  , "CI/"                                       , "./"                                        ),
        ("filePipelineAbs"        , True      , False , True  , "pipeline.yml"             , True                      , "ProjectRoot/CI/GitLab/pipeline.yml"          , True                  , "CI/GitLab/pipeline.yml"                    , None                                        ),
        ("filePipelineRel"        , False     , False , None  , "pipeline.yml"             , True                      , "CI/GitLab/pipeline.yml"                      , True                  , "CI/GitLab/pipeline.yml"                    , "GitLab/pipeline.yml"                       ),
        ("filePipelineRelDot"     , False     , False , None  , "pipeline.yml"             , True                      , "CI/GitLab/pipeline.yml"                      , True                  , "CI/GitLab/pipeline.yml"                    , "GitLab/pipeline.yml"                       ),
        ("dirNonexistentAAbs"     , True      , True  , False , "nonexistentA"             , False                     , dirNonexistentAAbs_relTo_CMagnetoProjectRoot(), False                 , dirNonexistentAAbs_relTo_SeedProjectRoot()  , None                                        ),
        ("dirNonexistentBAbs"     , True      , True  , False , "nonexistentB"             , False                     , dirNonexistentBAbs_relTo_CMagnetoProjectRoot(), False                 , dirNonexistentBAbs_relTo_SeedProjectRoot()  , None                                        ),
    ],
)
def test__validFixtures(request: pytest.FixtureRequest,
        pathFixtureName: str,
        isAbsolute: bool,
        isDir: bool,
        exists: bool | None,
        name: str,
        isUnderCMagnetoProjectRoot: bool,
        relPathToCMagnetoProjectRoot: str | None,
        isUnderSeedProjectRoot: bool,
        relPathToSeedProjectRoot: str | None,
        relPathToRelDirCI: str | None
    ):
    iPath: Utils.GoodPath = request.getfixturevalue(pathFixtureName)

    assert iPath.isAbsolute == isAbsolute, \
        f"{iPath.raw} → Expected isAbsolute={isAbsolute}, got {iPath.isAbsolute}"

    assert iPath.isDir == isDir, \
        f"{iPath.raw} → Expected isDir={isDir}, got {iPath.isDir}"

    assert iPath.exists() == exists, \
        f"{iPath.raw} → Expected exists={exists}, got {iPath.exists()}"

    assert iPath.name == name, \
        f"{iPath.raw} → Expected name={name}, got {iPath.name}"

    dir_dirName_pathIsUnder_tuples: list[tuple[str, str, bool]] = [
        (CMAGNETO_PROJECT_ROOT_STR, "CMagneto project root", isUnderCMagnetoProjectRoot),
        (SEED_PROJECT_ROOT_STR    , "seed project root"    , isUnderSeedProjectRoot    )
    ]

    dir_dirName_expRelPath_tuples: list[tuple[str, str, str | None]] = [
        (CMAGNETO_PROJECT_ROOT_STR, "CMagneto project root", relPathToCMagnetoProjectRoot),
        (SEED_PROJECT_ROOT_STR    , "seed project root"    , relPathToSeedProjectRoot    ),
        ("./CI/"                  , "'./CI/'"              , relPathToRelDirCI           )
    ]

    for tuple in dir_dirName_pathIsUnder_tuples:
        assert iPath.isRelativeTo(tuple[0], iAllowAscend=False) == tuple[2], \
            f"{iPath.raw} → Expected `{pathFixtureName} is under {tuple[1]}` = {tuple[2]}"

    for tuple in dir_dirName_expRelPath_tuples:
        resRelPath = iPath.getRelativeTo(tuple[0], iAllowAscend=True)
        assert (resRelPath is not None) == (tuple[2] is not None), \
            f"{iPath.raw} → Expected relative path to {tuple[1]} exists ('..' are allowed)` = {tuple[2] is not None}; got '{resRelPath}'."