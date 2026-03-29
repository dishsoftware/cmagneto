#!/usr/bin/env python3

# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

"""
build.py

This one-command Docker image build script is a part of the CMagneto framework.

For usage details and available options, run:
```
    python ./build_image.py --help
```
The script can be run from any working directory.
The location relative to the project root must be preserved.
"""

# Add project root to `sys.path`
# to be able to import CMagneto python scripts as `CMagneto.py.*`
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
import sys
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from CMagneto.py.docker.build_image import buildImage


if __name__ == "__main__":
    buildImage()