#!/bin/bash

# If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
# The file runs "set_env" script, which contains variables in the section "Template parameters".
# Values of these variables are specific to the machine the project was built on and set during the process (look into SetUpTargets.cmake).
# Replaced values of these variables must not contain `\n`. The character is reserved to mark substrings to replace during build.


# SECTION<Template parameters>START
DIR_WITH_CTESTTESTFILE="param\nDIR_WITH_CTESTTESTFILE\nparam"
BUILD_CONFIG="param\nBUILD_CONFIG\nparam"
REPORT_PATH="param\nREPORT_PATH\nparam"
# SECTION<Template parameters>END


if [[ -n "$DIR_WITH_CTESTTESTFILE" && "$DIR_WITH_CTESTTESTFILE" != *$"\n"* && \
      -n "$BUILD_CONFIG" && "$BUILD_CONFIG" != *$"\n"* && \
      -n "$REPORT_PATH" && "$REPORT_PATH" != *$"\n"*]]; then
    # If all template parameters are not empty and do not contain `\n`.
    . set_env.sh
    # Multi-config generator (e.g. Visual Studio) requires a build configuration to be defined.
    # For single-config generator (e.g. MinGW) it is redundant, but does not affect anything.
    ctest --test-dir "$DIR_WITH_CTESTTESTFILE" --output-on-failure --build-config "$BUILD_CONFIG" --output-junit "$REPORT_PATH" "$@"
else
    # Invalid template parameter value(s).
    SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$(basename -- "${BASH_SOURCE[0]}")"
    echo "Incorrectly generated script (invalid template parameter(s)): $SCRIPT_PATH"
fi