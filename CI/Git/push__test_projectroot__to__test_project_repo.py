# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Add seed project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
SEED_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent / "SeedProject"
import sys
if str(SEED_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(SEED_PROJECT_ROOT))

from CMagneto.py.utils.good_path import GoodPath
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process
from dataclasses import dataclass
from itertools import chain
from typing import cast
import os
import shutil


@dataclass
class PushParams:
    # Name of a branch or a tag of CMagneto Project repo, from where to copy files of a test project.
    # push__testProjectRoot__to__testProjectRepo will commit to a branch with such name (even if it is tag).
    sourceGitReference: str

    # Set to True, if sourceGitReference is a tag.
    sourceIsTag: bool

    # Dir inside the CMagneto Project repo, from where to copy files of a test project.
    # E.g. './SeedProject/' or './tests/system/testProjects/ProjectA/'.
    testProjectRootRelToCMagnetoProjectRoot: str

    # Address of a GitLab project for the test project repo.
    # E.g. `git@gitlab.com:dishsoftware/cmagneto_testprojects/projectA.git`.
    testProjectRepoURL: str

    # Commit message for the test project repo.
    # Compose it as '{SourceCommitSHA}\n\n{SourceCommitMessage}'.
    # For GitLab CI/CD it should be '{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}'.
    testProjectRepoCommitMessage: str

    # Path to a python file in the CMagneto Project repo relative to the CMagneto Project root, with content:
    # # The paths in the following sets must be relative and lead to dirs and files under ther test project root.
    # # Dir structure of the test project repo and corresponding test project dir in CMagneto Project repo must the same.

    # # These files and dirs won't be deleted during cleanup of the test project repo
    # # by `push__testProjectRoot__to__testProjectRepo`
    # EXISTING_ITEMS_TO_RETAIN: set[GoodPath] = { ... }

    # # These files and dirs won't be copied from a subdir of the test project inside the CMagneto Project repo into the test project repo.
    # # by `push__testProjectRoot__to__testProjectRepo`
    # INCOMING_ITEMS_TO_IGNORE: set[GoodPath] = { ... }

    # # `./CI/GitLab/workflow.yml` is a special path in the test project repo: `push__testProjectRoot__to__testProjectRepo` always creates it with
    # # the content of './CI/GitLab/test_project__workflow_replacement.yml` in the repo of CMagneto Project.
    specialItemSetsPyRelToCMagnetoProjectRoot: str | None


def push__testProjectRoot__to__testProjectRepo(
        iParams: PushParams
    ):
    """
    CMagneto Project repo can contain, aside from the seed project under "./SeedProject/", directories with files of other test projects, e.g. for system tests.
    To test such a project a developer must:
        A) Create a GitLab project for a test project repo.
        B) Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to "CI/GitLab/workflow.yml.
        C) Register a public SSH key as publicly availaible deploy key with write (push) access in the GitLab test project.
        D) Add private counterpart of the key as a masked protected hidden CI/CD variable.
        E) During a CI job in a pipeline of the CMagneto Project, add the private to an SSH-agent.
        D) Call this function, to mirror tag or last commit of the trigger-branch to the test project repo.
        F) Wait in the pipeline of CMagneto Project until a pipeline of the test project finishes.

    0) The script is meant to be executed under conditions:
        A) CMagneto Project repo is already cloned;
        B) `cwd` is the root of the cloned CMagneto Project repo.
    1) Clones a test project repo. Requires to Git LFS be installed on the machine/container.
    2) Replaces its content with content of {iParams.testProjectRootRelToCMagnetoProjectRoot} of CMagneto Project repo.
    3) Copies `./CI/GitLab/test_project__workflow_replacement.yml` from the repo of CMagneto Project
       into `./CI/GitLab/workflow.yml` of the cloned test project repo dir.
    4) Pushes the changes into the test project repo into {iParams.sourceGitReference} branch
       with commit message {iParams.testProjectRepoCommitMessage}.
    6) If {iParams.sourceIsTag}, pushes the tag {iParams.sourceGitReference} (the same name as branch) on the test project repo commit.
    """

    CMagnetoProjectRoot = GoodPath(__file__, iForceDir=True).getAscendant(3)
    if CMagnetoProjectRoot is None:
        Log.error(f"Probably error in logic of '{__file__}'. CMagneto Project root is resolved above FS root.")

    CMagnetoProjectRootParent = CMagnetoProjectRoot.getParent()
    if CMagnetoProjectRootParent is None:
        Log.error(f"CMagneto Project root is in FS root. Nest the CMagneto Project at least on level deeper.")

    testProjectRootRelToCMagnetoProjectRoot = GoodPath(iParams.testProjectRootRelToCMagnetoProjectRoot, iForceDir=True)
    testProjectRootRelToCMagnetoProjectRoot.checkIfRelativeAndDescendantAndGetAbsPath(
        "iTestProjectRelPathSrcStr",
        CMagnetoProjectRoot,
        "the CMagneto Project root",
        iExitNotRaise=True
    )

    testProjectRootSrc  = CMagnetoProjectRoot       /                    testProjectRootRelToCMagnetoProjectRoot
    testProjectRootDest = CMagnetoProjectRootParent / ("TestProjects/" + testProjectRootRelToCMagnetoProjectRoot.posixNormalized)

    if not testProjectRootSrc.exists():
        Log.error(f"Test project root does not exist: '{testProjectRootSrc}'.")

    specItemsPySrc: GoodPath | None = None
    if iParams.specialItemSetsPyRelToCMagnetoProjectRoot is not None:
        specialItemSetsPyRelToCMagnetoProjectRoot = GoodPath(iParams.specialItemSetsPyRelToCMagnetoProjectRoot)
        specItemsPySrc = specialItemSetsPyRelToCMagnetoProjectRoot.checkIfRelativeAndDescendantAndGetAbsPath(
            "Special items py-file path",
            CMagnetoProjectRoot,
            "the CMagneto Project root",
            iExitNotRaise=True
        )

    # Configuration.
    CMagneto__CI_BOT__GIT_NAME  = "CMagneto CI Bot"
    CMagneto__CI_BOT__GIT_EMAIL = "CMagneto-CI-Bot@dishsoftware.org"

    # Install Git LFS in CMagneto repo. "--force" to prevent conflict after "git lfs install --system".
    Process.runCommand(["git", "lfs", "install", "--local", "--force"])
    Process.runCommand(["git", "lfs", "pull"])  # Pull Git LFS-managed files of CMagneto repo.

    # Clone the test project repo.
    Log.status(f"Cloning test project repo '{iParams.testProjectRepoURL}' into '{testProjectRootDest}'...")
    os.environ["GIT_CLONE_PROTECTION_ACTIVE"] = "false" # Let Git LFS do its job in test project repo.
    Process.runCommand(["git", "clone", "--depth=1", iParams.testProjectRepoURL, str(testProjectRootDest)])

    ## Install Git LFS in test project repo. "--force" to prevent conflict after "git lfs install --system".
    Process.runCommand(["git", "lfs", "install", "--local", "--force"], testProjectRootDest)
    Process.runCommand(["git", "lfs", "pull"], testProjectRootDest)  # Pull Git LFS-managed files of test project repo.

    ## Setup Git user in the test project repo.
    Process.runCommand(["git", "config", "user.email", CMagneto__CI_BOT__GIT_EMAIL], testProjectRootDest)
    Process.runCommand(["git", "config", "user.name", CMagneto__CI_BOT__GIT_NAME],   testProjectRootDest)

    ## Checkout/create branch (in the test project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Log.status(f"Creating/checking-out branch \"{iParams.sourceGitReference}\" in the test project repo '{testProjectRootDest}'...")
    Process.runCommand(["git", "checkout", "-B", iParams.sourceGitReference],     testProjectRootDest)
    Process.runCommand(["git", "remote", "set-url", "origin", iParams.testProjectRepoURL], testProjectRootDest)
    Process.runCommand(["git", "config", "lfs.locksverify", "false"], testProjectRootDest) # Don't inform that locking is available.

    # Get special item sets.
    INCOMING_ITEMS_TO_IGNORE: set[GoodPath] = set()
    EXISTING_ITEMS_TO_RETAIN: set[GoodPath] = set()
    if specItemsPySrc is not None:
        Log.status(f"Importing INCOMING_ITEMS_TO_IGNORE and EXISTING_ITEMS_TO_RETAIN sets from '{specItemsPySrc}'...")
        sys.path.insert(0, str(specItemsPySrc))

        modulePath = str(specItemsPySrc)
        moduleName = str(specItemsPySrc.nameWE())  # module name without extension

        import importlib.util
        spec = importlib.util.spec_from_file_location(moduleName, modulePath)
        if (spec is None or spec.loader is None):
            Log.error(f"Can't load special items py file `{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}`.")

        module = importlib.util.module_from_spec(spec)
        sys.modules[moduleName] = module
        spec.loader.exec_module(module)

        isSetOfPaths = lambda iInstance: isinstance(iInstance, set) and all(isinstance(setIem, GoodPath) for setIem in iInstance)

        if not isSetOfPaths(module.EXISTING_ITEMS_TO_RETAIN):
            Log.error(f"`{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable EXISTING_ITEMS_TO_RETAIN. It must be of type `set[GoodPath]`.")

        if not isSetOfPaths(module.INCOMING_ITEMS_TO_IGNORE):
            Log.error(f"`{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable INCOMING_ITEMS_TO_IGNORE. It must be of type `set[GoodPath]`.")

        EXISTING_ITEMS_TO_RETAIN = module.EXISTING_ITEMS_TO_RETAIN
        INCOMING_ITEMS_TO_IGNORE = module.INCOMING_ITEMS_TO_IGNORE

        # Fail, if a special item path is not relative or not under test project root.
        for item in chain(EXISTING_ITEMS_TO_RETAIN, INCOMING_ITEMS_TO_IGNORE):
            item.checkIfRelativeAndDescendantAndGetAbsPath(
                "Special item path",
                testProjectRootSrc,
                "the test project root",
                iExitNotRaise=True
            )

    isPathUnderPathFromSet = lambda iPath, iBases: any(iPath.isDescendant(base) for base in iBases)

    # Delete all content of the test project root, except `.git/` and EXISTING_ITEMS_TO_RETAIN.
    Log.status(f"Deleting old content from the cloned repo '{testProjectRootDest}' of the test project...")
    for itemDest in testProjectRootDest.iterdir():
        itemRel = cast(GoodPath, itemDest.getRelativeTo(testProjectRootDest))
        if itemRel == ".git/" or isPathUnderPathFromSet(itemRel, EXISTING_ITEMS_TO_RETAIN):
            continue # TODO Don't check content under skipped path.
        itemDest.delete()

    # Copy from dir with the test project inside CMagneto Project repo into the test project repo root.
    Log.status(f"Copying content of '{testProjectRootSrc}' of the CMagneto Project repo into the cloned repo '{testProjectRootDest}' of the test project...")
    for itemSrc in testProjectRootSrc.rglob("*"): # Recursively walk all files and dirs.
        itemRel = cast(GoodPath, itemSrc.getRelativeTo(testProjectRootSrc))
        if isPathUnderPathFromSet(itemRel, INCOMING_ITEMS_TO_IGNORE):
            continue # TODO Don't check content under skipped path.

        itemDest = testProjectRootDest / itemRel

        if itemSrc.isDir:
            itemDest.create(iExistsOk=True)
        elif itemSrc.isFile():
            cast(GoodPath, itemDest.getParent()).create(iExistsOk=True)
            shutil.copy2(itemSrc, itemDest)
        elif itemSrc.isSymLink():
            cast(GoodPath, itemDest.getParent()).create(iExistsOk=True)
            if itemDest.exists() or itemDest.isSymLink():
                itemDest.delete()
            target = os.readlink(itemSrc)
            os.symlink(target, itemDest)

    # Copy `./__thisScriptNameWE__/push__testProjectRoot__to__testProjectRepo.yml` (located relative to this script in CMagneto repo dir)
    # into `./CI/GitLab/workflow.yml` of the test project root.
    workflowReplacementSrc = Path(__file__).parent.parent / "GitLab/test_project__workflow_replacement.yml"
    workflowDest = testProjectRootDest / "CI/" / "GitLab/" / "workflow.yml"
    cast(GoodPath, workflowDest.getParent()).create(iExistsOk=True)
    shutil.copy2(workflowReplacementSrc, workflowDest)
    Log.status(f"Copied '{workflowReplacementSrc}' into '{workflowDest}'.")

    # Commit and push to the test project repo.
    Log.status(
f"Commiting and pushing into '{iParams.testProjectRepoURL}' into branch '{iParams.sourceGitReference}' with message:\n\
\"{iParams.testProjectRepoCommitMessage}\"\n..."
    )
    Process.runCommand(["git", "add", "."], testProjectRootDest)
    Process.runCommand(["git", "commit", "--allow-empty", "-m", f"{iParams.testProjectRepoCommitMessage}"], testProjectRootDest)
    Process.runCommand(["git", "push", "--force", iParams.testProjectRepoURL, f"HEAD:{iParams.sourceGitReference}"], testProjectRootDest)

    # Tag the test project repo commit, if the CMagneto pipeline trigger was a tag push.
    if iParams.sourceIsTag:
        Log.status(f"Pushing tag '{iParams.sourceGitReference}'...")
        Process.runCommand(["git", "tag", iParams.sourceGitReference], testProjectRootDest)
        Process.runCommand(["git", "push", iParams.testProjectRepoURL, iParams.sourceGitReference], testProjectRootDest)

    Log.status(f"Function '{push__testProjectRoot__to__testProjectRepo.__name__}' succeded.\n")
