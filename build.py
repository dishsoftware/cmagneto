# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
build.py

This one-command project build script is a part of the CMagneto CMake module.

For usage details and available options, run:
```
    python ./build.py --help
```
The script can be run from any working directory.
The location relative to the project root must be preserved.
"""

from cmake.modules.CMagneto.py.cmake.build import buildProject


if __name__ == "__main__":
    buildProject()
