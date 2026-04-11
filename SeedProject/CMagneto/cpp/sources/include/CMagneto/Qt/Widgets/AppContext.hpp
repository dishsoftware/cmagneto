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

#include "CMagneto/Core/AppContext.hpp"

#include <memory>


class QSettings;


namespace CMagneto::Qt::Widgets {


    class AppContext : public CMagneto::Core::AppContext {
    public:
        inline static constexpr std::string_view kQtWidgetSettingsFileName{"QtWidgetSettings.ini"};

        AppContext() = delete;

        explicit AppContext(const CMagneto::Core::AppContext::AppMetadata& iAppMetadata);

        AppContext(
            const CMagneto::Core::AppContext::AppMetadata& iAppMetadata,
            CMagneto::Core::Logger iLogger
        );

        /** Test seam mirroring `CMagneto::Core::AppContext(const AppMetadata&, std::filesystem::path)`. */
        AppContext(
            const CMagneto::Core::AppContext::AppMetadata& iAppMetadata,
            std::filesystem::path iAppExecutableFilePath
        );

        ~AppContext();
        AppContext(const AppContext& iOther) = delete;
        AppContext(AppContext&& iOther) noexcept = delete;
        AppContext& operator=(const AppContext& iOther) = delete;
        AppContext& operator=(AppContext&& iOther) noexcept = delete;

        QSettings& qtWidgetSettings() noexcept;

        [[nodiscard]] const QSettings& qtWidgetSettings() const noexcept;

        std::unique_ptr<QSettings> mQtWidgetSettings;
    };


} // namespace CMagneto::Qt::Widgets
