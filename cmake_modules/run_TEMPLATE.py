# If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
# The file contains variables in section "Template parameters".
# Values of these variables are specific to your machine and set during the process (look into InstallTargets.cmake).


import os
import subprocess
import platform
import sys


# SECTION START: Template parameters.
# Values of these variables are set during build process.
## Separator between dirs must be "\n".
SHARED_LIB_DIRS_STRING = "param:SHARED_LIB_DIRS_STRING:param"
EXECUTABLE_NAME_WE = "param:EXECUTABLE_NAME_WE:param"
# SECTION END: Template parameters.


OS_NAME = platform.system()


def prepend_dir_to_env_path_variable(iDirToAdd: str, iEnvVarName: str) -> None:
    """
    Prepend a directory to the specified environment variable.
    """
    envVarValue = os.environ.get(iEnvVarName, "")
    os.environ[iEnvVarName] = iDirToAdd + os.path.pathsep + envVarValue
    return

def prepend_dirs_to_env_path_variable(iDirsToAdd: list[str], iEnvVarName: str) -> None:
    """
    Prepend directories to the specified environment variable.
    """
    dirs = [dir.replace("/", "\\") for dir in iDirsToAdd] if OS_NAME == "Windows" else iDirsToAdd
    for dir in dirs:
        prepend_dir_to_env_path_variable(dir, iEnvVarName)
    return


# Set paths to shared libraries.
sharedLibDirs = SHARED_LIB_DIRS_STRING.split("\n")
if OS_NAME == "Windows":
    prepend_dirs_to_env_path_variable(sharedLibDirs, "PATH")
elif OS_NAME == "Linux":
    prepend_dirs_to_env_path_variable(sharedLibDirs, "LD_LIBRARY_PATH")
else:
    print("Set paths to shared libraries: unsupported OS:", OS_NAME)
    sys.exit(1)


# Run the executable.
executable_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), EXECUTABLE_NAME_WE + ".exe" if OS_NAME == "Windows" else EXECUTABLE_NAME_WE)
print("Executable path: ", executable_path)
arguments = []
try:
    result = subprocess.run([executable_path, *arguments], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    print("Output:", result.stdout)
except subprocess.CalledProcessError as e:
    print("Error:", e.stderr)