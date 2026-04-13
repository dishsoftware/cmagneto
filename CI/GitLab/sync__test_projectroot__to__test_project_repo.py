# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Add these paths to `sys.path`
# to be able to import python scripts from CMagneto Project repo.
from pathlib import Path
CMAGNETO_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
SEED_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent / "SeedProject"
import sys
if str(CMAGNETO_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(CMAGNETO_PROJECT_ROOT))
if str(SEED_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(SEED_PROJECT_ROOT))

from CI.Git.push__test_projectroot__to__test_project_repo import push__testProjectRoot__to__testProjectRepo, PushParams
from CMagneto.py.utils.log import Log
import os


def sync__testProjectRoot__to__testProjectRepo(
        iTestProjectRootRelToCMagnetoProjectRoot: str,
        iTestProjectRepoURL: str,
        iSpecialItemSetsPyRelToCMagnetoProjectRoot: str | None = None
    ):
    """
    Gets GitLab CI/CD variables and passes them to the function `push__testProjectRoot__to__testProjectRepo`.
    Look into doc of the function and the PushParams dataclass in the same py file.
    """

    # GitLab CI/CD variables.
    CMagneto__CI_COMMIT_SHA = os.environ["CI_COMMIT_SHA"]
    CMagneto__CI_COMMIT_MESSAGE = os.environ["CI_COMMIT_MESSAGE"]
    CMagneto__CI_COMMIT_REF_NAME = os.environ["CI_COMMIT_REF_NAME"]
    CMagneto__CI_COMMIT_TAG = os.environ.get("CI_COMMIT_TAG")  # May be not set.

    params = PushParams(
        sourceGitReference = CMagneto__CI_COMMIT_REF_NAME,
        sourceIsTag = CMagneto__CI_COMMIT_TAG is not None and CMagneto__CI_COMMIT_TAG != "",
        testProjectRootRelToCMagnetoProjectRoot = iTestProjectRootRelToCMagnetoProjectRoot,
        testProjectRepoURL = iTestProjectRepoURL,
        testProjectRepoCommitMessage = f"{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}",
        specialItemSetsPyRelToCMagnetoProjectRoot = iSpecialItemSetsPyRelToCMagnetoProjectRoot
    )

    # Sync the test project repo.
    push__testProjectRoot__to__testProjectRepo(params)


if __name__ == "__main__":
    USAGE = \
f"Usage: {__name__} \\\n\
    <iTestProjectRootRelToCMagnetoProjectRoot> \\\n\
    <iTestProjectRepoURL> \\\n\
    [<iSpecialItemSetsPyRelToCMagnetoProjectRoot>]"

    import sys
    if len(sys.argv) < 3:
        Log.error(USAGE)
    if len(sys.argv) > 4:
        Log.warning(USAGE + f"\nIgnored extra args: {" ".join(sys.argv[4:])}.")

    pathArg = sys.argv[1]
    sync__testProjectRoot__to__testProjectRepo(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)