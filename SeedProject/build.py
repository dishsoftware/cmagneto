#!/usr/bin/env python3

# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
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

This one-command project build script is a part of the CMagneto framework.

For usage details and available options, run:
```
    python ./build.py --help
```
The script can be run from any working directory.
The location relative to the project root must be preserved.
"""

from CMagneto.py.cmake.build import buildProject


if __name__ == "__main__":
    buildProject()
