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

#include "CMagneto/Core/Logger.hpp"

#include <cstdint>
#include <filesystem>
#include <string>
#include <string_view>
#include <utility>


namespace CMagneto::Core {


    class AppContext {
    public:
        struct AppIdentity {
            std::string_view mCompanyNameShort;
            std::string_view mProjectNameBase;
            std::string_view mProjectNameForUI;
            std::string_view mProjectDescription;
            std::string_view mTargetName; // Name of target being excuted.
            std::string_view mVersion;
            std::uint32_t mVersionMajor;
            std::uint32_t mVersionMinor;
            std::uint32_t mVersionPatch;
            std::filesystem::path mExecutableFilePath;
        };

        inline static constexpr std::string_view kPortableMarkerFileName{"portable.flag"};
        inline static constexpr std::string_view kSettingsDirName{"settings"};

        AppContext() = delete;

        explicit AppContext(const AppIdentity& iAppIdentity) noexcept
        :
            mAppIdentity{iAppIdentity}
        {}

        AppContext(
            const AppIdentity& iAppIdentity,
            Logger iLogger
        ) noexcept
        :
            mAppIdentity{iAppIdentity},
            mLogger{std::move(iLogger)}
        {}

        ~AppContext() = default;
        AppContext(const AppContext& iOther) = delete;
        AppContext(AppContext&& iOther) noexcept = delete;
        AppContext& operator=(const AppContext& iOther) = delete;
        AppContext& operator=(AppContext&& iOther) noexcept = delete;

        Logger& logger() noexcept {
            return mLogger;
        }

        [[nodiscard]] const Logger& logger() const noexcept {
            return mLogger;
        }

        [[nodiscard]] const AppIdentity& appIdentity() const noexcept {
            return mAppIdentity;
        }

        [[nodiscard]] std::string appIdentityString() const;

        [[nodiscard]] bool isPortable() const noexcept;
        [[nodiscard]] std::filesystem::path settingsDirPath() const;

        [[nodiscard]] static std::string appIdentityString(const AppIdentity& iAppIdentity);
        [[nodiscard]] static bool isPortable(const AppIdentity& iAppIdentity) noexcept;
        [[nodiscard]] static std::filesystem::path settingsDirPath(const AppIdentity& iAppIdentity);

    protected:
        [[nodiscard]] static std::filesystem::path portableMarkerFilePath(const AppIdentity& iAppIdentity);
        [[nodiscard]] static std::filesystem::path ensureSettingsDirPath(const AppIdentity& iAppIdentity);

    private:
        [[nodiscard]] static std::filesystem::path portableSettingsDirPath(const AppIdentity& iAppIdentity);
        [[nodiscard]] static std::filesystem::path installedSettingsDirPath(const AppIdentity& iAppIdentity);

        AppIdentity mAppIdentity;
        Logger mLogger;
    };


} // namespace CMagneto::Core
