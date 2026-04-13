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

#include "CMagneto/Qt/helpers/string.hpp"
#include "CMagneto/Qt/helpers/settings/leafs.hpp"
#include "CMagneto/Qt/Widgets/mixins/WithGeometrySettings.hpp"

#include <QByteArray>
#include <QSettings>

#include <concepts>
namespace CMagneto::Qt::Widgets::mixins {


    template <class TQtWidget>
    concept WidgetWithStateSettings =
        std::derived_from<TQtWidget, QWidget> &&
        requires(TQtWidget& iWidget, const TQtWidget& iConstWidget, const QByteArray& iState) {
            { iWidget.restoreState(iState) };
            { iConstWidget.saveState() };
        }
    ;


    class WithGeometryAndStateSettings : public WithGeometrySettings {
    protected:
        using WithGeometrySettings::WithGeometrySettings;

        template <WidgetWithStateSettings TQtWidget>
        void loadStateSettings(TQtWidget& iWidget) const {
            const CMagneto::Core::HierarchicalID stateSettingsID{
                nestingID(),
                CMagneto::Qt::helpers::settings::leafs::kState
            };

            const QByteArray state = appContext().qtWidgetSettings().value(
                CMagneto::Qt::helpers::toQString(stateSettingsID.stringID())
            ).toByteArray();

            if (!state.isEmpty())
                iWidget.restoreState(state);
        }

        template <WidgetWithStateSettings TQtWidget>
        void saveStateSettings(const TQtWidget& iWidget) {
            const CMagneto::Core::HierarchicalID stateSettingsID{
                nestingID(),
                CMagneto::Qt::helpers::settings::leafs::kState
            };

            appContext().qtWidgetSettings().setValue(
                CMagneto::Qt::helpers::toQString(stateSettingsID.stringID()),
                iWidget.saveState()
            );
        }
    };


} // namespace CMagneto::Qt::Widgets::mixins
