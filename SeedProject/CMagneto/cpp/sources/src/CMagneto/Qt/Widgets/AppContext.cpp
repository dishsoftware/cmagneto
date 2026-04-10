// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Qt/Widgets/AppContext.hpp"
#include "CMagneto/Qt/helpers/string.hpp"

#include <utility>


namespace CMagneto::Qt::Widgets {

    using AppIdentity = CMagneto::Core::AppContext::AppIdentity;


    AppContext::AppContext(const AppIdentity& iAppIdentity)
    :
        CMagneto::Core::AppContext{iAppIdentity},
        mQtWidgetSettings{qtWidgetSettingsFilePath(iAppIdentity), QSettings::IniFormat}
    {}


    AppContext::AppContext(
        const AppIdentity& iAppIdentity,
        CMagneto::Core::Logger iLogger
    )
    :
        CMagneto::Core::AppContext{iAppIdentity, std::move(iLogger)},
        mQtWidgetSettings{qtWidgetSettingsFilePath(iAppIdentity), QSettings::IniFormat}
    {}


    QString AppContext::qtWidgetSettingsFilePath(const AppIdentity& iAppIdentity) {
        return CMagneto::Qt::helpers::toQString(
            ensureSettingsDirPath(iAppIdentity)
            / std::filesystem::path{kQtWidgetSettingsFileName}
        );
    }


    QSettings& AppContext::qtWidgetSettings() noexcept {
        return mQtWidgetSettings;
    }


    const QSettings& AppContext::qtWidgetSettings() const noexcept {
        return mQtWidgetSettings;
    }


} // namespace CMagneto::Qt::Widgets
