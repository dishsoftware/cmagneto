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

#include <QSettings>

#include <filesystem>
#include <memory>
#include <utility>


namespace {


    [[nodiscard]] QString qtWidgetSettingsFilePath(const std::filesystem::path& iAppSettingsRootPath) {
        std::filesystem::create_directories(iAppSettingsRootPath);

        return CMagneto::Qt::helpers::toQString(
            iAppSettingsRootPath
            / std::filesystem::path{CMagneto::Qt::Widgets::AppContext::kQtWidgetSettingsFileName}
        );
    }


} // namespace


namespace CMagneto::Qt::Widgets {

    using AppMetadata = CMagneto::Core::AppContext::AppMetadata;


    AppContext::AppContext(const AppMetadata& iAppMetadata)
    :
        CMagneto::Core::AppContext{iAppMetadata},
        mQtWidgetSettings{std::make_unique<QSettings>(qtWidgetSettingsFilePath(appSettingsRootPath()), QSettings::IniFormat)}
    {}


    AppContext::AppContext(
        const AppMetadata& iAppMetadata,
        CMagneto::Core::Logger iLogger
    )
    :
        CMagneto::Core::AppContext{iAppMetadata, std::move(iLogger)},
        mQtWidgetSettings{std::make_unique<QSettings>(qtWidgetSettingsFilePath(appSettingsRootPath()), QSettings::IniFormat)}
    {}


    AppContext::AppContext(
        const AppMetadata& iAppMetadata,
        std::filesystem::path iAppExecutableFilePath
    )
    :
        CMagneto::Core::AppContext{iAppMetadata, std::move(iAppExecutableFilePath)},
        mQtWidgetSettings{std::make_unique<QSettings>(qtWidgetSettingsFilePath(appSettingsRootPath()), QSettings::IniFormat)}
    {}


    AppContext::~AppContext() = default;


    QSettings& AppContext::qtWidgetSettings() noexcept {
        return *mQtWidgetSettings;
    }


    const QSettings& AppContext::qtWidgetSettings() const noexcept {
        return *mQtWidgetSettings;
    }


} // namespace CMagneto::Qt::Widgets
