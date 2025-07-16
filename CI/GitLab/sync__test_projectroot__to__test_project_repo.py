# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Add these paths to `sys.path`
# to be able to import python scripts from CMagneto project repo.
from pathlib import Path
CMAGNETO_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
SEED_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent / "ProjectRoot"
import sys
sys.path.append(str(CMAGNETO_PROJECT_ROOT))
sys.path.append(str(SEED_PROJECT_ROOT))

from CI.Git.push__test_projectroot__to__test_project_repo import push__testProjectRoot__to__testProjectRepo, PushParams
from CMagneto.py.utils import Utils
import os
import subprocess


def sync__testProjectRoot__to__testProjectRepo(
        iTestProjectRootRelToCMagnetoProjectRoot: str,
        iTestProjectRepoURL: str,
        iCMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME: str,
        iSpecialItemSetsPyRelToCMagnetoProjectRoot: str | None = None
    ):
    """
    Runs './add__test_project__private_key__to_ssh_agent.sh' script,
    then calls the function `push__testProjectRoot__to__testProjectRepo`.

    The `push__testProjectRoot__to__testProjectRepo` function pushes content of the a test project root from the CMagneto project repo
    into the repo of the corresponding test GitLab project, what triggers pipeline of the test project.
    And, while triggering the pipeline can be permitted just by adding CMagneto GitLab page address
    to the list of "CI/CD job token allowlist" of the test project,
    pushing into the repo requires:
      1) Using a `Project access token` issued in the test project, but the `Project access tokens` feature is only available on paid GitLab plans;
      2) Using an SSH deploy key, registred in the test project.
    The second option was chosen.

    Look into doc of the script, of the function and the PushParams dataclass in the same py file.
    """

    # GitLab CI/CD variables.
    CMagneto__CI_COMMIT_SHA = os.environ["CI_COMMIT_SHA"]
    CMagneto__CI_COMMIT_MESSAGE = os.environ["CI_COMMIT_MESSAGE"]
    CMagneto__CI_COMMIT_REF_NAME = os.environ["CI_COMMIT_REF_NAME"]
    CMagneto__CI_COMMIT_TAG = os.environ.get("CI_COMMIT_TAG")  # May be not set.

    # Add a deploy key with write repo access for the test GitLab project to SSH-agent
    # in order to clone (if the test project is private) and push into the test project repo.\
    shScriptPath = Path(__file__).parent / "add__test_project__private_key__to_ssh_agent.sh"
    subprocess.run([shScriptPath.as_posix(), iCMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME], check=True)

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
    <iCMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME> \\\n\
    [<iSpecialItemSetsPyRelToCMagnetoProjectRoot>]"

    import sys
    if len(sys.argv) < 4:
        Utils.error(USAGE)
    if len(sys.argv) > 5:
        Utils.warning(USAGE + "\nIgnored extra args: {" ".join(sys.argv[4:])}.")

    pathArg = sys.argv[1]
    sync__testProjectRoot__to__testProjectRepo(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)