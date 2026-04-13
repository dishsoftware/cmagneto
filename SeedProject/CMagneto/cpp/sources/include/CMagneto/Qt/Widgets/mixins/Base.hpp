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

#include "CMagneto/Qt/Widgets/IHasHierarchicalID.hpp"


namespace CMagneto::Qt::Widgets::mixins {


    class Base : public CMagneto::Qt::Widgets::IHasHierarchicalID {
    protected:
        explicit Base(CMagneto::Core::HierarchicalID iNestingID)
        :
            mNestingID{std::move(iNestingID)}
        {}

    public:
        [[nodiscard]] const CMagneto::Core::HierarchicalID& nestingID() const noexcept override {
            return mNestingID;
        }

    private:
        CMagneto::Core::HierarchicalID mNestingID;
    };


} // namespace CMagneto::Qt::Widgets::mixins
