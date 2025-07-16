# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import subprocess


def checkDocker():
    try:
        subprocess.run(["docker", "info"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        print("❌ Docker is installed but the daemon is not running. Start Docker Desktop or Docker service.")
        exit(1)
    except FileNotFoundError:
        print("❌ Docker is not installed or not in PATH.")
        exit(1)