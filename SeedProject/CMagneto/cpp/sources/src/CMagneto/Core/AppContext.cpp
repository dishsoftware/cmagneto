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
#include "CMagneto/Core/binaryTools/currentExecutableFilePath.hpp"

#include <cstdlib>
#include <stdexcept>
#include <system_error>
#include <utility>


namespace {


    [[nodiscard]] std::filesystem::path envPath(const char* const iName) {
        const char* const value = std::getenv(iName);
        if (value == nullptr || *value == '\0')
            return {};

        return value;
    }


} // namespace


namespace CMagneto::Core {


    AppContext::AppContext(const AppMetadata& iAppMetadata)
    :
        mAppMetadata{iAppMetadata},
        mProjectID{projectID(iAppMetadata)},
        mAppID{appID(iAppMetadata)},
        mExecutableContext{makeExecutableContext(iAppMetadata, CMagneto::Core::binaryTools::currentExecutableFilePath())}
    {}


    AppContext::AppContext(
        const AppMetadata& iAppMetadata,
        Logger iLogger
    ) :
        mAppMetadata{iAppMetadata},
        mProjectID{projectID(iAppMetadata)},
        mAppID{appID(iAppMetadata)},
        mExecutableContext{makeExecutableContext(iAppMetadata, CMagneto::Core::binaryTools::currentExecutableFilePath())},
        mLogger{std::move(iLogger)}
    {}


    AppContext::AppContext(
        const AppMetadata& iAppMetadata,
        std::filesystem::path iAppExecutableFilePath
    ) :
        mAppMetadata{iAppMetadata},
        mProjectID{projectID(iAppMetadata)},
        mAppID{appID(iAppMetadata)},
        mExecutableContext{makeExecutableContext(iAppMetadata, std::move(iAppExecutableFilePath))}
    {}


    std::filesystem::path AppContext::runtimeResourceFilePath(const std::filesystem::path& iRelativeResourcePath) const {
        return mExecutableContext.mProjectRuntimeResourcesRootPath / normalizeRuntimeResourceRelativePath(iRelativeResourcePath);
    }


    /*static*/ std::string AppContext::projectID(const AppMetadata& iAppMetadata) {
        std::string projectIDValue;

        projectIDValue.reserve(
            iAppMetadata.mCompanyNameShort.size()
            + 2
            + iAppMetadata.mProjectNameBase.size()
        );

        projectIDValue
            .append(iAppMetadata.mCompanyNameShort)
            .append("::")
            .append(iAppMetadata.mProjectNameBase)
        ;

        return projectIDValue;
    }


    /*static*/ std::string AppContext::appID(const AppMetadata& iAppMetadata) {
        std::string appIDValue;

        appIDValue.reserve(
            iAppMetadata.mCompanyNameShort.size()
            + 2
            + iAppMetadata.mProjectNameBase.size()
            + 2
            + iAppMetadata.mTargetName.size()
        );

        appIDValue
            .append(iAppMetadata.mCompanyNameShort)
            .append("::")
            .append(iAppMetadata.mProjectNameBase)
            .append("::")
            .append(iAppMetadata.mTargetName)
        ;

        return appIDValue;
    }


    /*static*/ AppContext::ExecutableContext AppContext::makeExecutableContext(
        const AppMetadata& iAppMetadata,
        std::filesystem::path iAppExecutableFilePath
    ) {
        ExecutableContext executableContext;
        executableContext.mAppExecutableFilePath = normalizeAppExecutableFilePath(iAppExecutableFilePath);
        executableContext.mProjectInstallationRootPath = executableContext.mAppExecutableFilePath.parent_path().parent_path();

        std::error_code errorCode;
        executableContext.mIsProjectPortable = std::filesystem::exists(
            executableContext.mProjectInstallationRootPath / kPortableMarkerFileName,
            errorCode
        );
        executableContext.mProjectBinariesRootPath = executableContext.mProjectInstallationRootPath / kBinariesDirName;

        if (executableContext.mIsProjectPortable)
            executableContext.mProjectSettingsRootPath = executableContext.mProjectInstallationRootPath / kSettingsDirName;
        else
            executableContext.mProjectSettingsRootPath = installedProjectSettingsRootPath(iAppMetadata);

        executableContext.mAppSettingsRootPath = executableContext.mProjectSettingsRootPath / std::filesystem::path{iAppMetadata.mTargetName};
        executableContext.mDefaultProjectLogsRootPath = executableContext.mProjectSettingsRootPath.parent_path() / kLogsDirName;
        executableContext.mDefaultAppLogsRootPath = executableContext.mDefaultProjectLogsRootPath / std::filesystem::path{iAppMetadata.mTargetName};
        executableContext.mProjectRuntimeResourcesRootPath = executableContext.mProjectInstallationRootPath / kRuntimeResourcesDirName;
        return executableContext;
    }


    /*static*/ std::filesystem::path AppContext::normalizeAppExecutableFilePath(
        const std::filesystem::path& iAppExecutableFilePath
    ) {
        if (iAppExecutableFilePath.empty())
            throw std::invalid_argument{"Executable path must not be empty."};

        const std::filesystem::path normalizedAppExecutableFilePath = iAppExecutableFilePath.lexically_normal();
        if (normalizedAppExecutableFilePath.empty() || normalizedAppExecutableFilePath == ".")
            throw std::invalid_argument{"Executable path must not be empty."};

        if (!normalizedAppExecutableFilePath.has_filename())
            throw std::invalid_argument{"App executable path must identify a file under the project bin directory."};

        const std::filesystem::path binDirPath = normalizedAppExecutableFilePath.parent_path();
        if (binDirPath.empty())
            throw std::invalid_argument{"Executable path must have a parent bin directory."};

        if (binDirPath.filename() != kBinariesDirName)
            throw std::invalid_argument{"Executable path must be located under a directory named \"bin\"."};

        const std::filesystem::path projectInstallationRootPathValue = binDirPath.parent_path();
        if (projectInstallationRootPathValue.empty())
            throw std::invalid_argument{"Project installation root path must be derivable from the app executable path."};

        return normalizedAppExecutableFilePath;
    }


    /*static*/ std::filesystem::path AppContext::normalizeRuntimeResourceRelativePath(
        const std::filesystem::path& iRelativeResourcePath
    ) {
        if (iRelativeResourcePath.empty())
            throw std::invalid_argument{"Runtime resource path must not be empty."};

        if (iRelativeResourcePath.is_absolute() || iRelativeResourcePath.has_root_name() || iRelativeResourcePath.has_root_directory())
            throw std::invalid_argument{"Runtime resource path must be relative to the runtime resource root."};

        const std::filesystem::path normalizedPath = iRelativeResourcePath.lexically_normal();
        if (normalizedPath.empty() || normalizedPath == ".")
            throw std::invalid_argument{"Runtime resource path must point to a file under the runtime resource root."};

        for (const auto& pathElement : normalizedPath) {
            if (pathElement == "..")
                throw std::invalid_argument{"Runtime resource path must not traverse parent directories."};
        }

        return normalizedPath;
    }

    /*static*/ std::filesystem::path AppContext::installedProjectSettingsRootPath(const AppMetadata& iAppMetadata) {
        #ifdef _WIN32
            std::filesystem::path settingsBaseDirPath = envPath("APPDATA");
        #else
            std::filesystem::path settingsBaseDirPath = envPath("XDG_CONFIG_HOME");
            if (settingsBaseDirPath.empty())
                settingsBaseDirPath = envPath("HOME") / ".config";
        #endif

        return settingsBaseDirPath
            / iAppMetadata.mCompanyNameShort
            / iAppMetadata.mProjectNameBase
            / kSettingsDirName
        ;
    }


} // namespace CMagneto::Core
