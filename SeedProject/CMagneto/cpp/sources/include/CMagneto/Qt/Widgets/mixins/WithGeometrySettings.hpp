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

#include "CMagneto/Qt/helpers/settings/leafs.hpp"
#include "CMagneto/Qt/Widgets/AppContext.hpp"
#include "CMagneto/Qt/Widgets/mixins/Base.hpp"

#include <QWidget>


namespace CMagneto::Qt::Widgets::mixins {


    class WithGeometrySettings : public Base {
    protected:
        explicit WithGeometrySettings(
            CMagneto::Qt::Widgets::AppContext& iAppContext,
            CMagneto::Core::HierarchicalID iNestingID
        ) noexcept;

        [[nodiscard]] CMagneto::Qt::Widgets::AppContext& appContext() noexcept;
        [[nodiscard]] const CMagneto::Qt::Widgets::AppContext& appContext() const noexcept;

        virtual void loadGeometrySettings(QWidget& iWidget) const;
        virtual void saveGeometrySettings(const QWidget& iWidget);

    private:
        CMagneto::Qt::Widgets::AppContext& mAppContext;
    };


} // namespace CMagneto::Qt::Widgets::mixins
