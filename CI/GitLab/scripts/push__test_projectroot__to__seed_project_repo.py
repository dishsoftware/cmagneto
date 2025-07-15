# Add test project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent / "ProjectRoot"
import sys
sys.path.append(str(PROJECT_ROOT))


from CMagneto.py.utils import Utils
from itertools import chain
from typing import cast
import os
import shutil


def push__test_projectroot__to__test_project_repo(
        iTestProjectRootRelToCMagnetoProjectRoot: str,
        iTestProjectRepoURL: str,
        iSpecialItemSetsPyRelToCMagnetoProjectRoot: str | None = None
    ):
    """
    CMagneto project repo can contain, aside from the seed project under "./ProjectRoot/", directories with files of other test projects, e.g. for system tests.
    To test such a project a developer must:
        A) Create a GitLab project for a test project repo.
        B) Go to `GitLab Project Page` → `Settings` → `CI/CD` → `General Pipelines` and set `CI/CD configuration file` to "CI/GitLab/workflow.yml.
        C) Register a public SSH key as publicly availaible deploy key with write (push) access in the GitLab test project.
        D) Add private counterpart of the key as a masked protected hidden CI/CD variable.
        E) During a CI job in a pipeline of the CMagneto project, add the private to an ssh-agent.
        D) Call this function, to mirror tag or last commit of the trigger-branch to the test project repo.
        F) Wait in the pipeline of CMagneto project until a pipeline of the test project finishes.

    0) The script is meant to be executed on a CI job runner of CMagneto project.
       Thus, `cwd` in the script is the root of a cloned CMagneto project repo.
    1) Clones a test project repo.
    2) Replaces its content with content of `./iTestProjectPath/` of CMagneto project repo.
    3) Overrides `./CI/GitLab/scripts/workflow.yml` in the cloned test project repo dir
       with `test_project__workflow_replacement.yml`, located in the
       eponymous with this script dir alongside this script in the repo of CMagneto project.
    4) Pushes the changes into the test project repo into an eponymous branch.
    5) The test project repo commit's message is composed as "{CI_COMMIT_SHA}\n\n{CI_COMMIT_MESSAGE}",
       where CI_COMMIT_SHA and CI_COMMIT_MESSAGE are GitLab CI vars of the CMagneto project pipeline.
    6) If the CMagneto project pipeline trigger was a tag push, pushes the same tag on the test project repo commit.

    Args:
        iTestProjectRootRelToCMagnetoProjectRoot (str): path to the test project in the CMagneto project repo relative to the CMagneto project root.
        iTestProjectRepoURL (str): SSH URL, used to clone the test project repo. E.g. `git@gitlab.com:dishsoftware/contactholder.git`.
        iSpecialItemSetsPyRelToCMagnetoProjectRoot (str | None): path to a python file in the CMagneto project repo relative to the CMagneto project root, with content:
        ```python
        # special_item_sets.py

        # The paths in the following sets must be relative to test project root and lead to dirs and files under ther test project root.
        # Dir structure of the test project repo and corresponding test project dir in CMagneto project repo must the same.

        # These files and dirs won't be deleted during cleanup of the test project repo
        # by `push__test_projectroot__to__test_project_repo`
        EXISTING_ITEMS_TO_RETAIN: set[Utils.GoodPath] = { ... }

        # These files and dirs won't be copied from a subdir of a test project inside the CMagneto project repo into a test project repo.
        # by `push__test_projectroot__to__test_project_repo`
        INCOMING_ITEMS_TO_IGNORE: set[Utils.GoodPath] = { ... }

        # `./CI/GitLab/workflow.yml` is a special path: `push__test_projectroot__to__test_project_repo` always replaces (creates) it with
        # the content of `test_project__workflow_replacement.yml`, located in the subdir `push__test_projectroot__to__seed_project_repo` in the repo of CMagneto project.
        ```
    """
    CMagnetoProjectRoot = Utils.GoodPath(__file__, iForceDir=True).getAscendant(4)
    if CMagnetoProjectRoot is None:
        Utils.error(f"Probably error in logic of '{__file__}'. CMagneto project root is resolved above FS root.")

    CMagnetoProjectRootParent = CMagnetoProjectRoot.getParent()
    if CMagnetoProjectRootParent is None:
        Utils.error(f"CMagneto project root is in FS root. Nest the CMagneto project at least on level deeper.")

    testProjectRootRelToCMagnetoProjectRoot = Utils.GoodPath(iTestProjectRootRelToCMagnetoProjectRoot, iForceDir=True)
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
    if iSpecialItemSetsPyRelToCMagnetoProjectRoot is not None:
        specialItemSetsPyRelToCMagnetoProjectRoot = Utils.GoodPath(iSpecialItemSetsPyRelToCMagnetoProjectRoot)
        specItemsPySrc = specialItemSetsPyRelToCMagnetoProjectRoot.checkIfRelativeAndDescendantAndGetAbsPath(
            "Special items py-file path",
            CMagnetoProjectRoot,
            "the CMagneto project root",
            iExitNotRaise=True
        )

    # Configuration.
    CMagneto__CI_BOT__GIT_NAME  = "CMagneto CI Bot"
    CMagneto__CI_BOT__GIT_EMAIL = "CMagneto-CI-Bot@dishsoftware.org"
    # GitLab CI variables.
    CMagneto__CI_COMMIT_SHA = os.environ["CI_COMMIT_SHA"]
    CMagneto__CI_COMMIT_MESSAGE = os.environ["CI_COMMIT_MESSAGE"]
    CMagneto__CI_COMMIT_REF_NAME = os.environ["CI_COMMIT_REF_NAME"]
    CMagneto__CI_COMMIT_TAG = os.environ.get("CI_COMMIT_TAG")  # May be not set.

    statusText = f"Synching branch/tag \"{CMagneto__CI_COMMIT_REF_NAME}\" into ContactHolder test project repo"
    Utils.status(statusText + "...")

    # Clone the test project repo.
    Utils.runCommand(["git", "clone", "--depth=1", iTestProjectRepoURL, str(testProjectRootDest)])

    # Setup Git user in the test project repo.
    Utils.runCommand(["git", "config", "user.email", CMagneto__CI_BOT__GIT_EMAIL], testProjectRootDest)
    Utils.runCommand(["git", "config", "user.name", CMagneto__CI_BOT__GIT_NAME],   testProjectRootDest)

    # Checkout/create branch (in the test project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Utils.runCommand(["git", "checkout", "-B", CMagneto__CI_COMMIT_REF_NAME],     testProjectRootDest)
    Utils.runCommand(["git", "remote", "set-url", "origin", iTestProjectRepoURL], testProjectRootDest)

    # Get special item sets.
    INCOMING_ITEMS_TO_IGNORE: set[Utils.GoodPath] = set()
    EXISTING_ITEMS_TO_RETAIN: set[Utils.GoodPath] = set()
    if specItemsPySrc is not None:
        sys.path.append(str(specItemsPySrc))

        modulePath = str(specItemsPySrc)
        moduleName = str(specItemsPySrc.nameWE())  # module name without extension

        import importlib.util
        spec = importlib.util.spec_from_file_location(moduleName, modulePath)
        if (spec is None or spec.loader is None):
            Utils.error(f"Can't load special items py file `{iSpecialItemSetsPyRelToCMagnetoProjectRoot}`.")

        module = importlib.util.module_from_spec(spec)
        sys.modules[moduleName] = module
        spec.loader.exec_module(module)

        isSetOfPaths = lambda iInstance: isinstance(iInstance, set) and all(isinstance(setIem, Utils.GoodPath) for setIem in iInstance)

        if not isSetOfPaths(module.EXISTING_ITEMS_TO_RETAIN):
            Utils.error(f"`{iSpecialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable EXISTING_ITEMS_TO_RETAIN. It must be of type `set[Utils.GoodPath]`.")

        if not isSetOfPaths(module.INCOMING_ITEMS_TO_IGNORE):
            Utils.error(f"`{iSpecialItemSetsPyRelToCMagnetoProjectRoot}` contains invalid variable INCOMING_ITEMS_TO_IGNORE. It must be of type `set[Utils.GoodPath]`.")

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
    for itemDest in testProjectRootDest.iterdir():
        itemRel = cast(Utils.GoodPath, itemDest.getRelativeTo(testProjectRootDest))
        if itemRel == ".git/" or isPathUnderPathFromSet(itemRel, EXISTING_ITEMS_TO_RETAIN):
            continue # TODO Don't check content under skipped path.
        itemDest.delete()

    # Copy from dir with the test project inside CMagneto project repo into the test project repo root.
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

    # Copy `./__thisScriptNameWE__/test_project__workflow_replacement.yml` (located relative to this script in CMagneto repo dir)
    # into `./CI/GitLab/workflow.yml` of the test project root.
    workflowReplacementSrc = Path(__file__).resolve().with_suffix('') / "test_project__workflow_replacement.yml"
    workflowDest = testProjectRootDest / "CI/" / "GitLab/" / "workflow.yml"
    cast(Utils.GoodPath, workflowDest.getParent()).create(iExistsOk=True)
    shutil.copy2(workflowReplacementSrc, workflowDest)

    # Commit and push to the test project repo.
    Utils.runCommand(["git", "add", "."], testProjectRootDest)
    Utils.runCommand(["git", "commit", "-m", f"{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}"], testProjectRootDest)
    Utils.runCommand(["git", "push", "--force", iTestProjectRepoURL, f"HEAD:{CMagneto__CI_COMMIT_REF_NAME}"], testProjectRootDest)

    # Tag the test project repo commit, if the CMagneto pipeline trigger was a tag push.
    if CMagneto__CI_COMMIT_TAG:
        Utils.runCommand(["git", "tag", CMagneto__CI_COMMIT_TAG], testProjectRootDest)
        Utils.runCommand(["git", "push", iTestProjectRepoURL, CMagneto__CI_COMMIT_TAG], testProjectRootDest)

    Utils.status(statusText + " finished.\n")


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        Utils.error("Usage: python push__test_projectroot__to__test_project_repo.py <iTestProjectPathSrcStr> <iTestProjectRepoURL> [iPathToSpecialItemSetsPy]")
    if len(sys.argv) > 4:
        Utils.warning(f"Usage: python push__test_projectroot__to__test_project_repo.py <iTestProjectPathSrcStr> <iTestProjectRepoURL> [iPathToSpecialItemSetsPy].\n\
                      \tIgnored extra args: {" ".join(sys.argv[4:])}.")

    pathArg = sys.argv[1]
    push__test_projectroot__to__test_project_repo(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
