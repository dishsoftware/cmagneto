# Add seed project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent / "ProjectRoot"
import sys
sys.path.append(str(PROJECT_ROOT))


from CMagneto.py.utils import Utils
import os
import shutil


# -------- Configuration --------
CMAGNETO__SEED_PROJECT__SUBDIR = Path("ProjectRoot/")  # Seed project root in CMagneto repo relative to CMagneto repo root.
SEED_PROJECT__REPO_URL = "git@gitlab.com:dishsoftware/contactholder.git" # GitLab repo URL. git@gitlab.com:dishsoftware/contactholder.git
SEED_PROJECT__REPO_NAME = "contactholder" # GitLab repo name.
GIT_EMAIL = "CMagneto-CI-Bot@dishsoftware.org"
GIT_NAME  = "CMagneto CI Bot"
# --------------------------------

# CMAGNETO_CI_BOT__PRIVATE_SSH_KEY__FOR_SEED_PROJECT_REPO__NO_WHITESPACES


def push__projectroot__to__seed_project_repo():
    """
    1) Clones the seed project repo.
    2) Replaces its content with content of `./ProjectRoot/` of CMagneto repo.
    3) Overrides `./CI/GitLab/scripts/workflow.yml` in the repo dir of the seed project
       with `seed_project__workflow_replacement.yml` located in the
       eponymous with this script dir alongside this script in the repo of CMagneto.
    4) Pushes the changes into the seed project repo into an eponymous branch.
    5) The seed project repo commit's message is composed as "{CI_COMMIT_SHA}\n\n{CI_COMMIT_MESSAGE}",
       where CI_COMMIT_SHA and CI_COMMIT_MESSAGE are GitLab CI vars of the CMagneto pipeline.
    6) If the CMagneto pipeline trigger was a tag push, pushes the same tag on the seed project repo commit.
    """

    Utils.runCommand(["pwd"])
    Utils.runCommand(["ls"])

    # GitLab CI variables
    CMagneto__CI_COMMIT_SHA = os.environ["CI_COMMIT_SHA"]
    CMagneto__CI_COMMIT_MESSAGE = os.environ["CI_COMMIT_MESSAGE"]
    CMagneto__CI_COMMIT_REF_NAME = os.environ["CI_COMMIT_REF_NAME"]
    CMagneto__CI_COMMIT_TAG = os.environ.get("CI_COMMIT_TAG")  # May be not set.

    statusText = f"Synching branch/tag \"{CMagneto__CI_COMMIT_REF_NAME}\" into ContactHolder seed project repo"
    Utils.status(statusText + "...")

    # Clone the seed project repo.
    CMagnetoRoot = Path(os.getcwd())
    seedProjectRoot = CMagnetoRoot.parent / SEED_PROJECT__REPO_NAME

    Utils.runCommand(["git", "clone", "--depth=1", SEED_PROJECT__REPO_URL, str(seedProjectRoot)])

    # Setup Git user in the seed project repo.
    Utils.runCommand(["git", "config", "user.email", GIT_EMAIL], seedProjectRoot)
    Utils.runCommand(["git", "config", "user.name", GIT_NAME], seedProjectRoot)

    # Checkout/create branch (in the seed project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Utils.runCommand(["git", "checkout", "-B", CMagneto__CI_COMMIT_REF_NAME], seedProjectRoot)
    Utils.runCommand(["git", "remote", "set-url", "origin", SEED_PROJECT__REPO_URL], seedProjectRoot)

    # Delete all content of the seed project root, except `.git/`.
    for item in seedProjectRoot.iterdir():
        if item.name == ".git":
            continue
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()

    # Copy from `./cmagneto/ProjectRoot/` into the seed project root.
    sourcePath = CMagnetoRoot / CMAGNETO__SEED_PROJECT__SUBDIR
    for item in sourcePath.glob("**/*"):
        relPath = item.relative_to(sourcePath)
        dest = seedProjectRoot / relPath
        dest.parent.mkdir(parents=True, exist_ok=True)
        if item.is_file():
            shutil.copy2(item, dest)

    # Copy `./__thisScriptNameWE__/seed_project__workflow_replacement.yml` (located relative to this script in CMagneto repo dir)
    # into `./CI/GitLab/workflow.yml` of the seed project root.
    workflowReplacementSrc = Path(__file__).resolve().with_suffix('') / "seed_project__workflow_replacement.yml"
    workflowDest = seedProjectRoot / "CI" / "GitLab" / "workflow.yml"
    workflowDest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(workflowReplacementSrc, workflowDest)

    # Commit and push to the seed project repo.
    Utils.runCommand(["git", "add", "."], seedProjectRoot)
    Utils.runCommand(["git", "commit", "-m", f"{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}"], seedProjectRoot)
    Utils.runCommand(["git", "push", "--force", SEED_PROJECT__REPO_URL, f"HEAD:{CMagneto__CI_COMMIT_REF_NAME}"], seedProjectRoot)

    # Tag the seed project repo commit, if the CMagneto pipeline trigger was a tag push.
    if CMagneto__CI_COMMIT_TAG:
        Utils.runCommand(["git", "tag", CMagneto__CI_COMMIT_TAG], seedProjectRoot)
        Utils.runCommand(["git", "push", SEED_PROJECT__REPO_URL, CMagneto__CI_COMMIT_TAG], seedProjectRoot)

    Utils.status(statusText + " finished.\n")

if __name__ == "__main__":
    push__projectroot__to__seed_project_repo()
