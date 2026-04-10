// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Qt/Widgets/mixins/WithGeometrySettings.hpp"
#include "CMagneto/Qt/helpers/string.hpp"


namespace CMagneto::Qt::Widgets::mixins {


    WithGeometrySettings::WithGeometrySettings(
        CMagneto::Qt::Widgets::AppContext& iAppContext,
        CMagneto::Core::HierarchicalID iNestingID
    ) noexcept
    :
        Base{std::move(iNestingID)},
        mAppContext{iAppContext}
    {}


    CMagneto::Qt::Widgets::AppContext& WithGeometrySettings::appContext() noexcept {
        return mAppContext;
    }


    const CMagneto::Qt::Widgets::AppContext& WithGeometrySettings::appContext() const noexcept {
        return mAppContext;
    }


    void WithGeometrySettings::loadGeometrySettings(QWidget& iWidget) const {
        const CMagneto::Core::HierarchicalID geometrySettingsID{
            nestingID(),
            CMagneto::Qt::helpers::settings::leafs::kGeometry
        };

        const QByteArray geometry = appContext().qtWidgetSettings().value(
            CMagneto::Qt::helpers::toQString(geometrySettingsID.stringID())
        ).toByteArray();

        if (!geometry.isEmpty())
            iWidget.restoreGeometry(geometry);
    }


    void WithGeometrySettings::saveGeometrySettings(const QWidget& iWidget) {
        const CMagneto::Core::HierarchicalID geometrySettingsID{
            nestingID(),
            CMagneto::Qt::helpers::settings::leafs::kGeometry
        };

        appContext().qtWidgetSettings().setValue(
            CMagneto::Qt::helpers::toQString(geometrySettingsID.stringID()),
            iWidget.saveGeometry()
        );
    }


} // namespace CMagneto::Qt::Widgets::mixins
