# Add seed project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`.
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent / "ProjectRoot"
import sys
sys.path.append(str(PROJECT_ROOT))


from CMagneto.py.utils import Utils
from pathlib import Path
import os
import shutil


# -------- Configuration --------
CMAGNETO__SEED_PROJECT__SUBDIR = Path("ProjectRoot/")  # Seed project root in CMagneto repo relative to CMagneto repo root.
SEED_PROJECT__REPO_URL = "https://gitlab-ci-token:{token}@gitlab.com/dishsoftware/contactholder.git" # GitLab repo URL.
SEED_PROJECT__REPO_NAME = "contactholder" # GitLab repo name.
GIT_EMAIL = "CMagneto-CI-Bot@dishsoftware.org"
GIT_NAME  = "CMagneto CI Bot"
# --------------------------------


def push__projectroot__to__seed_project_repo():
    """
    1) Clones the seed project repo.
    2) Replaces its content with content of `./ProjectRoot/` of CMagneto repo.
    3) Pushes the changes into the seed project repo into an eponymous branch.
    4) The seed project repo commit's message is composed as "{CI_COMMIT_SHA}\n\n{CI_COMMIT_MESSAGE}",
       where CI_COMMIT_SHA and CI_COMMIT_MESSAGE are GitLab CI vars of the CMagneto pipeline.
    5) If the CMagneto pipeline trigger was a tag push, pushes the same tag on the seed project repo commit.
    """

    # GitLab CI variables
    CMagneto__CI_COMMIT_SHA = os.environ["CI_COMMIT_SHA"]
    CMagneto__CI_COMMIT_MESSAGE = os.environ["CI_COMMIT_MESSAGE"]
    CMagneto__CI_COMMIT_REF_NAME = os.environ["CI_COMMIT_REF_NAME"]
    CMagneto__CI_COMMIT_TAG = os.environ.get("CI_COMMIT_TAG")  # May be not set.
    CMagneto__CI_JOB_TOKEN = os.environ["CI_JOB_TOKEN"]

    statusText = f"Syncing branch/tag \"{CMagneto__CI_COMMIT_REF_NAME}\" into ContactHolder seed project repo"
    Utils.status(statusText + "...")

    # Clone the seed project repo.
    CMagnetoRoot = Path(os.getcwd())
    seedProjectRoot = CMagnetoRoot.parent / SEED_PROJECT__REPO_NAME
    seedProjectRepoURL = SEED_PROJECT__REPO_URL.format(token=CMagneto__CI_JOB_TOKEN)

    Utils.runCommand(["git", "clone", "--depth=1", seedProjectRepoURL, str(seedProjectRoot)])

    # Setup Git user in the seed project repo.
    Utils.runCommand(["git", "config", "user.email", GIT_EMAIL], seedProjectRoot)
    Utils.runCommand(["git", "config", "user.name", GIT_NAME], seedProjectRoot)

    # Checkout/create branch (in the seed project repo) with the same name as the branch of CMagneto, where CI pipeline trigger happened.
    Utils.runCommand(["git", "checkout", "-B", CMagneto__CI_COMMIT_REF_NAME], seedProjectRoot)

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

    # Commit and push to the seed project repo.
    Utils.runCommand(["git", "add", "."], seedProjectRoot)
    Utils.runCommand(["git", "commit", "-m", f"{CMagneto__CI_COMMIT_SHA}\n\n{CMagneto__CI_COMMIT_MESSAGE}"], seedProjectRoot)
    Utils.runCommand(["git", "push", "origin", CMagneto__CI_COMMIT_REF_NAME], seedProjectRoot)

    # Tag the seed project repo commit, if the CMagneto pipeline trigger was a tag push.
    if CMagneto__CI_COMMIT_TAG:
        Utils.runCommand(["git", "tag", CMagneto__CI_COMMIT_TAG], seedProjectRoot)
        Utils.runCommand(["git", "push", "origin", CMagneto__CI_COMMIT_TAG], seedProjectRoot)

    Utils.status(statusText + " finished.\n")

if __name__ == "__main__":
    push__projectroot__to__seed_project_repo()
