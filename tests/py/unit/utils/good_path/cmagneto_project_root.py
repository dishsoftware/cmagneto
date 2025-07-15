from pathlib import Path
import sys

# Resolve root paths
CMAGNETO_PROJECT_ROOT     = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
CMAGNETO_PROJECT_ROOT_STR = str(CMAGNETO_PROJECT_ROOT) + "/"
SEED_PROJECT_ROOT         = CMAGNETO_PROJECT_ROOT / "ProjectRoot"
SEED_PROJECT_ROOT_STR     = str(SEED_PROJECT_ROOT) + "/"

# Inject into sys.path once per session
if CMAGNETO_PROJECT_ROOT_STR not in sys.path:
    sys.path.insert(0, CMAGNETO_PROJECT_ROOT_STR)

if SEED_PROJECT_ROOT_STR not in sys.path:
    sys.path.insert(0, SEED_PROJECT_ROOT_STR)