// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#pragma once

#include "CMagneto/Core/HierarchicalID.hpp"


namespace CMagneto::Qt::Widgets {


    class IHasHierarchicalID {
    public:
        virtual ~IHasHierarchicalID() = default;

        [[nodiscard]] virtual const CMagneto::Core::HierarchicalID& nestingID() const noexcept = 0;
    };


} // namespace CMagneto::Qt::Widgets
