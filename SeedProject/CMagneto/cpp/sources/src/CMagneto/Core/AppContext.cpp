// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Core/AppContext.hpp"

#include <cstdlib>
#include <system_error>


namespace {


    [[nodiscard]] std::filesystem::path envPath(const char* const iName) {
        const char* const value = std::getenv(iName);
        if (value == nullptr || *value == '\0')
            return {};

        return value;
    }


} // namespace


namespace CMagneto::Core {


    std::string AppContext::appIdentityString() const {
        return appIdentityString(appIdentity());
    }


    bool AppContext::isPortable() const noexcept {
        return isPortable(appIdentity());
    }


    std::filesystem::path AppContext::settingsDirPath() const {
        return settingsDirPath(appIdentity());
    }


    /*static*/ std::string AppContext::appIdentityString(const AppIdentity& iAppIdentity) {
        std::string appIdentityStringValue;
        appIdentityStringValue.reserve(
            iAppIdentity.mCompanyNameShort.size()
            + 2
            + iAppIdentity.mProjectNameBase.size()
            + 2
            + iAppIdentity.mTargetName.size()
        );
        appIdentityStringValue
            .append(iAppIdentity.mCompanyNameShort)
            .append("::")
            .append(iAppIdentity.mProjectNameBase)
            .append("::")
            .append(iAppIdentity.mTargetName)
        ;
        return appIdentityStringValue;
    }


    bool AppContext::isPortable(const AppIdentity& iAppIdentity) noexcept {
        std::error_code errorCode;
        return std::filesystem::exists(portableMarkerFilePath(iAppIdentity), errorCode);
    }


    std::filesystem::path AppContext::settingsDirPath(const AppIdentity& iAppIdentity) {
        if (isPortable(iAppIdentity))
            return portableSettingsDirPath(iAppIdentity);

        return installedSettingsDirPath(iAppIdentity);
    }


    std::filesystem::path AppContext::portableMarkerFilePath(const AppIdentity& iAppIdentity) {
        return iAppIdentity.mExecutableFilePath.parent_path().parent_path() / kPortableMarkerFileName;
    }


    std::filesystem::path AppContext::ensureSettingsDirPath(const AppIdentity& iAppIdentity) {
        const std::filesystem::path settingsDirPathValue = settingsDirPath(iAppIdentity);
        std::filesystem::create_directories(settingsDirPathValue);
        return settingsDirPathValue;
    }


    std::filesystem::path AppContext::portableSettingsDirPath(const AppIdentity& iAppIdentity) {
        return iAppIdentity.mExecutableFilePath.parent_path().parent_path() / kSettingsDirName / iAppIdentity.mTargetName;
    }


    std::filesystem::path AppContext::installedSettingsDirPath(const AppIdentity& iAppIdentity) {
#ifdef _WIN32
        std::filesystem::path settingsBaseDirPath = envPath("APPDATA");
#else
        std::filesystem::path settingsBaseDirPath = envPath("XDG_CONFIG_HOME");
        if (settingsBaseDirPath.empty())
            settingsBaseDirPath = envPath("HOME") / ".config";
#endif

        return settingsBaseDirPath
            / iAppIdentity.mCompanyNameShort
            / iAppIdentity.mProjectNameBase
            / iAppIdentity.mTargetName
            / kSettingsDirName;
    }


} // namespace CMagneto::Core
