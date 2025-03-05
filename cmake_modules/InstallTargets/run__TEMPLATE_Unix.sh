#!/bin/bash

# If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
# The file contains variables in the section "Template parameters".
# Values of these variables are specific to the machine the project was built on and set during the process (look into InstallTargets.cmake).
# Replaced values of these variables must not contain `\n`. The character is reserved to mark strings to replace.


# SECTION<Template parameters>START
EXECUTABLE_NAME_WE="param\nEXECUTABLE_NAME_WE\nparam"
# SECTION<Template parameters>END


if [[ -n "$EXECUTABLE_NAME_WE" && "$EXECUTABLE_NAME_WE" != *$"\n"* ]]; then
    # If EXECUTABLE_NAME_WE is not empty and does not contain `\n`.
    . set_env.sh
    ./$EXECUTABLE_NAME_WE
elif [[ -z "$EXECUTABLE_NAME_WE" ]]; then
    # If EXECUTABLE_NAME_WE is empty, do nothing.
    :
else
    # EXECUTABLE_NAME_WE contains "\n", which is reserved to mark substring to be replaced.
    SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$(basename -- "${BASH_SOURCE[0]}")"
    echo "Incorrectly generated script: $SCRIPT_PATH"
fi