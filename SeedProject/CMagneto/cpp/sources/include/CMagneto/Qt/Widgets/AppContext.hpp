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

#include <QSettings>

#include <utility>


namespace CMagneto::Qt::Widgets {


    class AppContext : public CMagneto::Core::AppContext {
    public:
        AppContext() = default;

        explicit AppContext(CMagneto::Core::Logger iLogger) noexcept
        :
            CMagneto::Core::AppContext{std::move(iLogger)}
        {}

        ~AppContext() = default;
        AppContext(const AppContext& iOther) = delete;
        AppContext(AppContext&& iOther) noexcept = delete;
        AppContext& operator=(const AppContext& iOther) = delete;
        AppContext& operator=(AppContext&& iOther) noexcept = delete;

        QSettings& qtWidgetSettings() noexcept {
            return mQtWidgetSettings;
        }

        [[nodiscard]] const QSettings& qtWidgetSettings() const noexcept {
            return mQtWidgetSettings;
        }

    private:
        QSettings mQtWidgetSettings;
    };


} // namespace CMagneto::Qt::Widgets
