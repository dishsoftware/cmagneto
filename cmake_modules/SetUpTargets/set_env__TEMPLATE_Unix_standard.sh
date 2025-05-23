#!/bin/bash

# If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
# The file contains variables in the section "Template parameters".
# Values of these variables are specific to the machine the project was built on and set during the process (look into SetUpTargets.cmake).
# Replaced values of these variables must not contain `\n`. The character is reserved to mark substrings to replace during build.

# Run the script in the same shell session, from which an executable is run:
# `. script.sh` or `source script.sh`.


# SECTION<Template parameters>START
# Directories must be separated with ":".
SHARED_LIB_DIRS_STRING="param\nSHARED_LIB_DIRS_STRING\nparam"
# SECTION<Template parameters>END


if [[ -n "$SHARED_LIB_DIRS_STRING" && "$SHARED_LIB_DIRS_STRING" != *$"\n"* ]]; then
    # If SHARED_LIB_DIRS_STRING is not empty and does not contain `\n`.
    export LD_LIBRARY_PATH="$SHARED_LIB_DIRS_STRING:${LD_LIBRARY_PATH}"
elif [[ -z "$SHARED_LIB_DIRS_STRING" ]]; then
    # If SHARED_LIB_DIRS_STRING is empty, do nothing.
    :
else
    # SHARED_LIB_DIRS_STRING contains "\n", which is reserved to mark substrings to be replaced during build.
    SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$(basename -- "${BASH_SOURCE[0]}")"
    echo "Incorrectly generated script: $SCRIPT_PATH"
fi