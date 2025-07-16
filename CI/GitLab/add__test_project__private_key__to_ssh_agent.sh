#!/usr/bin/env bash

# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# The scipt must be called as "<SCRIPT_NAME> <CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME>".
#
# The CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME must be a name of
# a CI/CD variable of type "Variable (default)", added into CMagneto GitLab project.
# It is a private SSH key, converted into a single line without whitespaces using `base64`:
# ```bash
# base64 pathToThePrivateKey | tr -d '\n'
# ```
# The private key must be also registered as a publicly available deploy SSH-key with write repo access in the test GitLab project.
# Thus, it is possible to have different keys for different test projects simultaneously.
#
#
# Why base64?
# A private SSH key can't be saved as a masked CI/CD variable - GitLab shows the error:
# ```
#   Unable to create masked variable because:
#   The value cannot contain the following characters: whitespace characters."
# ```
# The shenanigans with `base64` can be avoided by uploading the private key file into CMagneto -> Settings -> CI/CD -> Secure files.
# In that case it could be used as "$CI_SECURE_FILES_DIR/thePrivateKeyFileName.
# But the approach with an environment variable is more flexible:
#   A variable can be "protected" and become only available when a CI pipeline deals with protected branches;
#   Secure file is always available both in protected and regular branches.


# Exit early on errors;
# Fail on typos or missing vars;
# Not hide failures in pipelines.
set -euo pipefail

# Check if number of arguments is correct.
if [ $# -ne 1 ]; then
  echo "Usage: $0 <CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME>"
  exit 1
fi

CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME="$1"
CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO="${!CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO__VAR_NAME}"

# Checks if the environment variable is empty or unset.
if [ -z "$CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO" ]; then
  echo "Missing base64-encoded private SSH key for CMagneto CI Bot."
  exit 1
fi

KEY_PATH="../testProjectRepoKey"

# Convert the single-line-base64 string back into a private key.
echo "$CMAGNETO_CI_BOT__PRIV_KEY_BASE64__FOR_TEST_PROJECT_REPO" | base64 -d > "$KEY_PATH"

# Set file permissions so only the owner can read/write (a requirement for SSH-client to trust the key).
# Without this, `ssh-add` will likely fail with a "bad permissions" error.
chmod 600 "$KEY_PATH"

# Print correponding public key for debug.
ssh-keygen -y -f "$KEY_PATH"

# Start the SSH-agent.
eval "$(ssh-agent -s)"

# Load the key into the running SSH-agent.
ssh-add "$KEY_PATH"

ssh -T git@gitlab.com

# Immediately delete the key file for security. It is already buffered by the SSH-agent.
rm -f "$KEY_PATH"

ssh -T git@gitlab.com

# Without the following block:
#   Git couldn't verify the SSH host key fingerprint - a security check to prevent man-in-the-middle attacks.
#   SSH expects the remote server's key to be listed in the `~/.ssh/known_hosts` file,
#   but in Docker-based CI runner, that file may be empty unless populated explicitly.
mkdir -p ~/.ssh
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts
chmod 700 ~/.ssh
chmod 644 ~/.ssh/known_hosts

# tree .. -a -L 5 -I '.git' # Debug.