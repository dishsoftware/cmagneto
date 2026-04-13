// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#pragma once

#include <string_view>


namespace CMagneto::Qt::helpers::settings::leafs {


    inline constexpr std::string_view kGeometry{"@geometry"};
    inline constexpr std::string_view kState{"@state"};


} // namespace CMagneto::Qt::helpers::settings::leafs
