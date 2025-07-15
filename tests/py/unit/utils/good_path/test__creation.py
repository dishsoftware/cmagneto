# Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import pytest
from cmagneto_project_root import *
from CMagneto.py.utils import Utils


@pytest.mark.parametrize(
    #                         |                                     |
    #                         |                                     |
    "pathString               , isValid, posixNormalized            ",
    [
        ("f"                  , True   , "f"                        ),
        ("d/////f"            , True   , "d/f"                      ),
        ("./f"                , True   , "f"                        ),
        ("././f"              , True   , "f"                        ),
        ("./../f"             , True   , "../f"                     ),
        ("d/../f"             , True   , "f"                        ),
        ("d/"                 , True   , "d/"                       ),
        ("./d/"               , True   , "d/"                       ),
        ("d1/../d2/"          , True   , "d2/"                      ),
        ("/"                  , True   , "/"                        ),
        ("\\"                 , True   , "/"                        ),
        ("/unixAbsF"          , True   , "/unixAbsF"                ),
        ("/unixAbsD/"         , True   , "/unixAbsD/"               ),
        ("c:/"                , True   , "C:/"                      ),
        ("c:\\"               , True   , "C:/"                      ),
        ("/unixAbsF"          , True   , "/unixAbsF"                ),
        ("/unixAbsD/"         , True   , "/unixAbsD/"               ),
    ]
)
def test__goodpath_invalid_type(
    pathString: str,
    isValid: bool,
    posixNormalized: str
):
    if isValid:
        path = Utils.GoodPath(pathString)
        assert path.posixNormalized == posixNormalized, \
            f"{pathString} → Expected posix normalized = '{posixNormalized}'; got '{path.posixNormalized}'."
    else:
        with pytest.raises((ValueError, TypeError)):
            Utils.GoodPath(pathString)
