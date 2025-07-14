# Add test project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent / "ProjectRoot"
import sys
sys.path.append(str(PROJECT_ROOT))


from CMagneto.py.utils import Utils
from itertools import chain
import os
import shutil


def push__test_projectroot__to__test_project_repo(iTestProjectPathSrcStr: str, iTestProjectRepoURL: str, iPathToSpecialItemSetsPy: str | None = None):
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
        iTestProjectPath (str): path to the test project in the CMagneto project repo relative to the CMagneto project root.
        iTestProjectRepoURL (str): SSH URL, used to clone the test project repo. E.g. `git@gitlab.com:dishsoftware/contactholder.git`.
        iPathToSpecialItemSetsPy (str | None): path to a python file in the CMagneto project repo relative to the CMagneto project root, with content:
        ```python
        # special_item_sets.py

        # The paths in the following sets must be relative to test project root and lead to dirs and files under ther test project root.
        # Dir structure of the test project repo and corresponding test project dir in CMagneto project repo must the same.

        # These files and dirs won't be deleted during cleanup of the test project repo
        # by `push__test_projectroot__to__test_project_repo`
        EXISTING_ITEMS_TO_RETAIN: set[Path] = { ... }

        # These files and dirs won't be copied from a subdir of a test project inside the CMagneto project repo into a test project repo.
        # by `push__test_projectroot__to__test_project_repo`
        INCOMING_ITEMS_TO_IGNORE: set[Path] = { ... }

        # `./CI/GitLab/workflow.yml` is a special path: `push__test_projectroot__to__test_project_repo` always replaces (creates) it with
        # the content of `test_project__workflow_replacement.yml`, located in the subdir `push__test_projectroot__to__seed_project_repo` in the repo of CMagneto project.
        ```
    """
    CMagnetoProjectRoot = Path(__file__).parent.parent.parent.parent
    testProjectRootSrcRelativeToCMagnetoProjectRoot = Utils.getPathRelativeToBaseDir(
        Path(iTestProjectPathSrcStr),
        CMagnetoProjectRoot,
        iPathType=Utils.PathType.Relative,
        iRequirePathUnderBase=True
    )
    testProjectRootSrc  = (CMagnetoProjectRoot                         / testProjectRootSrcRelativeToCMagnetoProjectRoot).resolve()
    testProjectRootDest = (CMagnetoProjectRoot.parent / "TestProjects" / testProjectRootSrcRelativeToCMagnetoProjectRoot).resolve()

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
    Utils.runCommand(["git", "config", "user.name", CMagneto__CI_BOT__GIT_NAME], testProjectRootDest)

    # Checkout/create branch (in the test project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Utils.runCommand(["git", "checkout", "-B", CMagneto__CI_COMMIT_REF_NAME], testProjectRootDest)
    Utils.runCommand(["git", "remote", "set-url", "origin", iTestProjectRepoURL], testProjectRootDest)

    # Get special item sets.
    INCOMING_ITEMS_TO_IGNORE: set[Path] = set()
    EXISTING_ITEMS_TO_RETAIN: set[Path] = set()
    if iPathToSpecialItemSetsPy is not None:
        import importlib.util

        pathToSpecialItemSetsPyRelToCMagnetoProjectRoot = Utils.getPathRelativeToBaseDir(
            Path(iPathToSpecialItemSetsPy),
            CMagnetoProjectRoot,
            iPathType=Utils.PathType.Relative,
            iRequirePathUnderBase=True
        )
        sys.path.append(str((CMagnetoProjectRoot / pathToSpecialItemSetsPyRelToCMagnetoProjectRoot).resolve()))

        modulePath = (CMagnetoProjectRoot / pathToSpecialItemSetsPyRelToCMagnetoProjectRoot).resolve()
        moduleName = pathToSpecialItemSetsPyRelToCMagnetoProjectRoot.stem  # module name without extension

        spec = importlib.util.spec_from_file_location(moduleName, modulePath)
        if (spec is None or spec.loader is None):
            Utils.error(f"Can't load special items py file `{iPathToSpecialItemSetsPy}`.")

        module = importlib.util.module_from_spec(spec)
        sys.modules[moduleName] = module
        spec.loader.exec_module(module)

        isSetOfPaths = lambda iInstance: isinstance(iInstance, set) and all(isinstance(setIem, Path) for setIem in iInstance)

        if not isSetOfPaths(module.EXISTING_ITEMS_TO_RETAIN):
            Utils.error(f"`{iPathToSpecialItemSetsPy}` contains invalid variable EXISTING_ITEMS_TO_RETAIN. It must be of type `set[Path]`.")

        if not isSetOfPaths(module.INCOMING_ITEMS_TO_IGNORE):
            Utils.error(f"`{iPathToSpecialItemSetsPy}` contains invalid variable INCOMING_ITEMS_TO_IGNORE. It must be of type `set[Path]`.")

        EXISTING_ITEMS_TO_RETAIN = module.EXISTING_ITEMS_TO_RETAIN
        INCOMING_ITEMS_TO_IGNORE = module.INCOMING_ITEMS_TO_IGNORE

        # Fail, if a special item path is not relative or not under test project root.
        for item in chain(EXISTING_ITEMS_TO_RETAIN, INCOMING_ITEMS_TO_IGNORE):
            Utils.getPathRelativeToBaseDir(
                item,
                # Does not matter testProjectRootSrc or testProjectRootDest. Dir structure of a test project repo and a test project dir in CMagneto project repo must be the same.
                testProjectRootSrc,
                iPathType=Utils.PathType.Relative,
                iRequirePathUnderBase=True
            )

    isPathUnderPathFromSet = lambda iPath, iBases: any(iPath.is_relative_to(base) for base in iBases)

    # Delete all content of the test project root, except `.git/` and EXISTING_ITEMS_TO_RETAIN.
    for itemDest in testProjectRootDest.iterdir():
        itemRel = itemDest.relative_to(testProjectRootDest)
        if itemRel == Path(".git/") or isPathUnderPathFromSet(itemRel, EXISTING_ITEMS_TO_RETAIN):
            continue # TODO Don't check content under skipped path.
        if itemDest.is_dir():
            shutil.rmtree(itemDest)
        else:
            itemDest.unlink()

    # Copy from dir with the test project inside CMagneto project repo into the test project repo root.
    for itemSrc in testProjectRootSrc.rglob("*"): # Recursively walk all files and dirs.
        itemRel = itemSrc.relative_to(testProjectRootSrc)
        if isPathUnderPathFromSet(itemRel, INCOMING_ITEMS_TO_IGNORE):
            continue # TODO Don't check content under skipped path.

        itemDest = testProjectRootDest / itemRel

        if itemSrc.is_dir():
            itemDest.mkdir(parents=True, exist_ok=True)
        elif itemSrc.is_file():
            itemDest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(itemSrc, itemDest)
        elif itemSrc.is_symlink():
            itemDest.parent.mkdir(parents=True, exist_ok=True)
            if itemDest.exists() or itemDest.is_symlink():
                itemDest.unlink()
            target = os.readlink(itemSrc)
            os.symlink(target, itemDest)

    # Copy `./__thisScriptNameWE__/test_project__workflow_replacement.yml` (located relative to this script in CMagneto repo dir)
    # into `./CI/GitLab/workflow.yml` of the test project root.
    workflowReplacementSrc = Path(__file__).resolve().with_suffix('') / "test_project__workflow_replacement.yml"
    workflowDest = testProjectRootDest / "CI" / "GitLab" / "workflow.yml"
    workflowDest.parent.mkdir(parents=True, exist_ok=True)
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
