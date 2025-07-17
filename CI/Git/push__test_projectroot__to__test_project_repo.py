# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Add test project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent / "SeedProject"
import sys
sys.path.append(str(PROJECT_ROOT))


from CMagneto.py.utils import Utils
from dataclasses import dataclass
from itertools import chain
from typing import cast
import os
import shutil


@dataclass
class PushParams:
    # Name of a branch or a tag of CMagneto project repo, from where to copy files of a test project.
    # push__testProjectRoot__to__testProjectRepo will commit to a branch with such name (even if it is tag).
    sourceGitReference: str

    # Set to True, if sourceGitReference is a tag.
    sourceIsTag: bool

    # Dir inside the CMagneto project repo, from where to copy files of a test project.
    # E.g. './SeedProject/' or './tests/system/testProjects/ProjectA/'.
    testProjectRootRelToCMagnetoProjectRoot: str

    # Address of a GitLab project for the test project repo.
    # E.g. `git@gitlab.com:dishsoftware/cmagneto_testprojects/projectA.git`.
    testProjectRepoURL: str

    # Commit message for the test project repo.
    # Compose it as '{SourceCommitSHA}\n\n{SourceCommitMessage}'.
    # For GitLab CI/CD it should be '{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}'.
    testProjectRepoCommitMessage: str

    # Path to a python file in the CMagneto project repo relative to the CMagneto project root, with content:
    # # The paths in the following sets must be relative and lead to dirs and files under ther test project root.
    # # Dir structure of the test project repo and corresponding test project dir in CMagneto project repo must the same.

    # # These files and dirs won't be deleted during cleanup of the test project repo
    # # by `push__testProjectRoot__to__testProjectRepo`
    # EXISTING_ITEMS_TO_RETAIN: set[Utils.GoodPath] = { ... }

    # # These files and dirs won't be copied from a subdir of the test project inside the CMagneto project repo into the test project repo.
    # # by `push__testProjectRoot__to__testProjectRepo`
    # INCOMING_ITEMS_TO_IGNORE: set[Utils.GoodPath] = { ... }

    # # `./CI/GitLab/workflow.yml` is a special path in the test project repo: `push__testProjectRoot__to__testProjectRepo` always creates it with
    # # the content of './CI/GitLab/test_project__workflow_replacement.yml` in the repo of CMagneto project.
    specialItemSetsPyRelToCMagnetoProjectRoot: str | None


def push__testProjectRoot__to__testProjectRepo(
        iParams: PushParams
    ):
    """
    CMagneto project repo can contain, aside from the seed project under "./SeedProject/", directories with files of other test projects, e.g. for system tests.
    To test such a project a developer must:
        A) Create a GitLab project for a test project repo.
        B) Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to "CI/GitLab/workflow.yml.
        C) Register a public SSH key as publicly availaible deploy key with write (push) access in the GitLab test project.
        D) Add private counterpart of the key as a masked protected hidden CI/CD variable.
        E) During a CI job in a pipeline of the CMagneto project, add the private to an SSH-agent.
        D) Call this function, to mirror tag or last commit of the trigger-branch to the test project repo.
        F) Wait in the pipeline of CMagneto project until a pipeline of the test project finishes.

    0) The script is meant to be executed under conditions:
        A) CMagneto project repo is already cloned;
        B) `cwd` is the root of the cloned CMagneto project repo.
    1) Clones a test project repo. Requires to Git LFS be installed on the machine/container.
    2) Replaces its content with content of {iParams.testProjectRootRelToCMagnetoProjectRoot} of CMagneto project repo.
    3) Copies `./CI/GitLab/test_project__workflow_replacement.yml` from the repo of CMagneto project
       into `./CI/GitLab/workflow.yml` of the cloned test project repo dir.
    4) Pushes the changes into the test project repo into {iParams.sourceGitReference} branch
       with commit message {iParams.testProjectRepoCommitMessage}.
    6) If {iParams.sourceIsTag}, pushes the tag {iParams.sourceGitReference} (the same name as branch) on the test project repo commit.
    """

    CMagnetoProjectRoot = Utils.GoodPath(__file__, iForceDir=True).getAscendant(3)
    if CMagnetoProjectRoot is None:
        Utils.error(f"Probably error in logic of '{__file__}'. CMagneto project root is resolved above FS root.")

    CMagnetoProjectRootParent = CMagnetoProjectRoot.getParent()
    if CMagnetoProjectRootParent is None:
        Utils.error(f"CMagneto project root is in FS root. Nest the CMagneto project at least on level deeper.")

    testProjectRootRelToCMagnetoProjectRoot = Utils.GoodPath(iParams.testProjectRootRelToCMagnetoProjectRoot, iForceDir=True)
    testProjectRootRelToCMagnetoProjectRoot.checkIfRelativeAndDescendantAndGetAbsPath(
        "iTestProjectRelPathSrcStr",
        CMagnetoProjectRoot,
        "the CMagneto project root",
        iExitNotRaise=True
    )

    testProjectRootSrc  = CMagnetoProjectRoot       /                    testProjectRootRelToCMagnetoProjectRoot
    testProjectRootDest = CMagnetoProjectRootParent / ("TestProjects/" + testProjectRootRelToCMagnetoProjectRoot.posixNormalized)

    if not testProjectRootSrc.exists():
        Utils.error(f"Test project root does not exist: '{testProjectRootSrc}'.")

    specItemsPySrc: Utils.GoodPath | None = None
    if iParams.specialItemSetsPyRelToCMagnetoProjectRoot is not None:
        specialItemSetsPyRelToCMagnetoProjectRoot = Utils.GoodPath(iParams.specialItemSetsPyRelToCMagnetoProjectRoot)
        specItemsPySrc = specialItemSetsPyRelToCMagnetoProjectRoot.checkIfRelativeAndDescendantAndGetAbsPath(
            "Special items py-file path",
            CMagnetoProjectRoot,
            "the CMagneto project root",
            iExitNotRaise=True
        )

    # Configuration.
    CMagneto__CI_BOT__GIT_NAME  = "CMagneto CI Bot"
    CMagneto__CI_BOT__GIT_EMAIL = "CMagneto-CI-Bot@dishsoftware.org"

    # Install Git LFS in CMagneto repo. "--force" to prevent conflict after "git lfs install --system".
    Utils.runCommand(["git", "lfs", "install", "--local", "--force"])
    Utils.runCommand(["git", "lfs", "pull"])  # Pull Git LFS-managed files of CMagneto repo.

    # Clone the test project repo.
    Utils.status(f"Cloning test project repo '{iParams.testProjectRepoURL}' into '{testProjectRootDest}'...")
    os.environ["GIT_CLONE_PROTECTION_ACTIVE"] = "false" # Let Git LFS do its job in test project repo.
    Utils.runCommand(["git", "clone", "--depth=1", iParams.testProjectRepoURL, str(testProjectRootDest)])

    ## Install Git LFS in test project repo. "--force" to prevent conflict after "git lfs install --system".
    Utils.runCommand(["git", "lfs", "install", "--local", "--force"], testProjectRootDest)
    Utils.runCommand(["git", "lfs", "pull"], testProjectRootDest)  # Pull Git LFS-managed files of test project repo.

    ## Setup Git user in the test project repo.
    Utils.runCommand(["git", "config", "user.email", CMagneto__CI_BOT__GIT_EMAIL], testProjectRootDest)
    Utils.runCommand(["git", "config", "user.name", CMagneto__CI_BOT__GIT_NAME],   testProjectRootDest)

    ## Checkout/create branch (in the test project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Utils.status(f"Creating/checking-out branch \"{iParams.sourceGitReference}\" in the test project repo '{testProjectRootDest}'...")
    Utils.runCommand(["git", "checkout", "-B", iParams.sourceGitReference],     testProjectRootDest)
    Utils.runCommand(["git", "remote", "set-url", "origin", iParams.testProjectRepoURL], testProjectRootDest)
    Utils.runCommand(["git", "config", "lfs.locksverify", "false"], testProjectRootDest) # Don't inform that locking is available.

    # Get special item sets.
    INCOMING_ITEMS_TO_IGNORE: set[Utils.GoodPath] = set()
    EXISTING_ITEMS_TO_RETAIN: set[Utils.GoodPath] = set()
    if specItemsPySrc is not None:
        Utils.status(f"Importing INCOMING_ITEMS_TO_IGNORE and EXISTING_ITEMS_TO_RETAIN sets from '{specItemsPySrc}'...")
        sys.path.append(str(specItemsPySrc))

        modulePath = str(specItemsPySrc)
        moduleName = str(specItemsPySrc.nameWE())  # module name without extension

        import importlib.util
        spec = importlib.util.spec_from_file_location(moduleName, modulePath)
        if (spec is None or spec.loader is None):
            Utils.error(f"Can't load special items py file `{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}`.")

        module = importlib.util.module_from_spec(spec)
        sys.modules[moduleName] = module
        spec.loader.exec_module(module)

        isSetOfPaths = lambda iInstance: isinstance(iInstance, set) and all(isinstance(setIem, Utils.GoodPath) for setIem in iInstance)

        if not isSetOfPaths(module.EXISTING_ITEMS_TO_RETAIN):
            Utils.error(f"`{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable EXISTING_ITEMS_TO_RETAIN. It must be of type `set[Utils.GoodPath]`.")

        if not isSetOfPaths(module.INCOMING_ITEMS_TO_IGNORE):
            Utils.error(f"`{iParams.specialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable INCOMING_ITEMS_TO_IGNORE. It must be of type `set[Utils.GoodPath]`.")

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
    Utils.status(f"Deleting old content from the cloned repo '{testProjectRootDest}' of the test project...")
    for itemDest in testProjectRootDest.iterdir():
        itemRel = cast(Utils.GoodPath, itemDest.getRelativeTo(testProjectRootDest))
        if itemRel == ".git/" or isPathUnderPathFromSet(itemRel, EXISTING_ITEMS_TO_RETAIN):
            continue # TODO Don't check content under skipped path.
        itemDest.delete()

    # Copy from dir with the test project inside CMagneto project repo into the test project repo root.
    Utils.status(f"Copying content of '{testProjectRootSrc}' of the CMagneto project repo into the cloned repo '{testProjectRootDest}' of the test project...")
    for itemSrc in testProjectRootSrc.rglob("*"): # Recursively walk all files and dirs.
        itemRel = cast(Utils.GoodPath, itemSrc.getRelativeTo(testProjectRootSrc))
        if isPathUnderPathFromSet(itemRel, INCOMING_ITEMS_TO_IGNORE):
            continue # TODO Don't check content under skipped path.

        itemDest = testProjectRootDest / itemRel

        if itemSrc.isDir:
            itemDest.create(iExistsOk=True)
        elif itemSrc.isFile():
            cast(Utils.GoodPath, itemDest.getParent()).create(iExistsOk=True)
            shutil.copy2(itemSrc, itemDest)
        elif itemSrc.isSymLink():
            cast(Utils.GoodPath, itemDest.getParent()).create(iExistsOk=True)
            if itemDest.exists() or itemDest.isSymLink():
                itemDest.delete()
            target = os.readlink(itemSrc)
            os.symlink(target, itemDest)

    # Copy `./__thisScriptNameWE__/push__testProjectRoot__to__testProjectRepo.yml` (located relative to this script in CMagneto repo dir)
    # into `./CI/GitLab/workflow.yml` of the test project root.
    workflowReplacementSrc = Path(__file__).parent.parent / "GitLab/test_project__workflow_replacement.yml"
    workflowDest = testProjectRootDest / "CI/" / "GitLab/" / "workflow.yml"
    cast(Utils.GoodPath, workflowDest.getParent()).create(iExistsOk=True)
    shutil.copy2(workflowReplacementSrc, workflowDest)
    Utils.status(f"Copied '{workflowReplacementSrc}' into '{workflowDest}'.")

    # Commit and push to the test project repo.
    Utils.status(
f"Commiting and pushing into '{iParams.testProjectRepoURL}' into branch '{iParams.sourceGitReference}' with message:\n\
\"{iParams.testProjectRepoCommitMessage}\"\n..."
    )
    Utils.runCommand(["git", "add", "."], testProjectRootDest)
    Utils.runCommand(["git", "commit", "--allow-empty", "-m", f"{iParams.testProjectRepoCommitMessage}"], testProjectRootDest)
    Utils.runCommand(["git", "push", "--force", iParams.testProjectRepoURL, f"HEAD:{iParams.sourceGitReference}"], testProjectRootDest)

    # Tag the test project repo commit, if the CMagneto pipeline trigger was a tag push.
    if iParams.sourceIsTag:
        Utils.status(f"Pushing tag '{iParams.sourceGitReference}'...")
        Utils.runCommand(["git", "tag", iParams.sourceGitReference], testProjectRootDest)
        Utils.runCommand(["git", "push", iParams.testProjectRepoURL, iParams.sourceGitReference], testProjectRootDest)

    Utils.status(f"Function '{push__testProjectRoot__to__testProjectRepo.__name__}' succeded.\n")
