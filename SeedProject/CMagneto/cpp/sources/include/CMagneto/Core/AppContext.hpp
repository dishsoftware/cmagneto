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

#include "CMagneto/Core/Logger.hpp"

#include <cstdint>
#include <filesystem>
#include <string>
#include <string_view>


namespace CMagneto::Core {


    /**
     *  \brief Process-wide application context.
     *
     * An application is an executable, compiled from an executable target of a project.
     *
     * Supports portable project installation mode.
     * The portable mode is enabled, if `<ProjectInstallationRoot>/portable.flag` exists
     * at the moment `AppContext` is constructed. Otherwise the installed per-user settings layout is used.
     *
     * The class requires the following project installation layout:
     *
     * ```text
     * <ProjectInstallationRoot>/
     *  ├── bin/
     *  │   ├── <AppExecutable>  # E.g. <TargetName> == `GUI`, then <AppExecutable> == `DishSW_ContactHolder1_GUI.exe`.
     *  │   └── ...
     *  ├── res/                 # Project runtime resources root.
     *  ├── portable.flag        # Optional. Existence means the project installation is portable.
     *  ├── settings/            # Project settings root. Located here only in portable mode.
     *  └── ...
     * ```
     *
     *
     * Project settings root location depends on project installation mode and platform:
     *
     * 1. Portable mode:
     *    `<ProjectInstallationRoot>/settings/`
     *
     * 2. Installed (per-user) mode:
     *    2.1. Linux/macOS-like:
     *        `(<XDG_CONFIG_HOME> or <HOME>/.config)/<CompanyName>/<ProjectName>/settings/`
     *
     *    2.2. Windows:
     *         `<APPDATA>/<CompanyName>/<ProjectName>/settings/`
     *
     *
     * The class organizes the following layout of project settings root:
     *
     * ```
     * settings/           # Project settings root.
     *  ├── <TargetName>/  # App settings root.
     *  └── ...
     * ```
     *
     * Default project     log root is `ProjectSettingsRoot/../logs/`.
     * Default application log root is `ProjectSettingsRoot/../logs/<TargetName>/`
     */
    class AppContext {
    public:
        /** Immutable application metadata independent of the current process location. */
        struct AppMetadata {
            std::string_view mCompanyNameShort;
            std::string_view mProjectNameBase;
            std::string_view mTargetName; // Name of target being executed.
            std::string_view mProjectVersionString; // Project `<major>.<minor>.<patch>` version.
            std::uint32_t mProjectVersionMajor;
            std::uint32_t mProjectVersionMinor;
            std::uint32_t mProjectVersionPatch;
            std::string_view mProjectNameForUI;
            std::string_view mProjectDescription;
        };

        inline static constexpr std::string_view kBinariesDirName{"bin"};
        inline static constexpr std::string_view kRuntimeResourcesDirName{"res"};
        inline static constexpr std::string_view kPortableMarkerFileName{"portable.flag"};
        inline static constexpr std::string_view kSettingsDirName{"settings"};
        inline static constexpr std::string_view kLogsDirName{"logs"};

        AppContext() = delete;

        /** Uses `binaryTools::currentExecutableFilePath()` of the current process. */
        explicit AppContext(const AppMetadata& iAppMetadata);

        /** Uses `binaryTools::currentExecutableFilePath()` of the current process. */
        AppContext(
            const AppMetadata& iAppMetadata,
            Logger iLogger
        );

        /**
         * Test seam for injecting a synthetic app executable path matching the CMagneto Project layout.
         * Production code should prefer `AppContext(const AppMetadata&)`.
         */
        AppContext(
            const AppMetadata& iAppMetadata,
            std::filesystem::path iAppExecutableFilePath
        );

        ~AppContext() = default;
        AppContext(const AppContext& iOther) = delete;
        AppContext(AppContext&& iOther) noexcept = delete;
        AppContext& operator=(const AppContext& iOther) = delete;
        AppContext& operator=(AppContext&& iOther) noexcept = delete;

        [[nodiscard]] const AppMetadata& appMetadata() const noexcept {
            return mAppMetadata;
        }

        /** \returns Cached `<CompanyNameShort>::<ProjectNameBase>`. */
        [[nodiscard]] const std::string& projectID() const noexcept {
            return mProjectID;
        }

        /** \returns Cached `<CompanyNameShort>::<ProjectNameBase>::<TargetName>`. */
        [[nodiscard]] const std::string& appID() const noexcept {
            return mAppID;
        }

        Logger& logger() noexcept {
            return mLogger;
        }

        [[nodiscard]] const Logger& logger() const noexcept {
            return mLogger;
        }

        /** \returns Path to the executable binary of this application. */
        [[nodiscard]] const std::filesystem::path& appExecutableFilePath() const noexcept {
            return mExecutableContext.mAppExecutableFilePath;
        }

        /** \returns Project installation root, i.e. parent of the executable's `bin/` directory. */
        [[nodiscard]] std::filesystem::path projectInstallationRootPath() const {
            return mExecutableContext.mProjectInstallationRootPath;
        }

        /** \returns `<ProjectInstallationRoot>/bin/`. */
        [[nodiscard]] std::filesystem::path projectBinariesRootPath() const {
            return mExecutableContext.mProjectBinariesRootPath;
        }

        /**
         * \returns Cached project launch mode detected when this `AppContext` was constructed.
         * Portable mode is enabled when a portable marker file exists in the project installation root.
         */
        [[nodiscard]] bool isProjectPortable() const noexcept {
            return mExecutableContext.mIsProjectPortable;
        }

        /**
         * \returns Root directory under which this project's settings are stored.
         *
         * Project-portable mode:
         * `<ProjectInstallationRoot>/settings/`
         *
         * Installed mode:
         * Linux/macOS-like:
         * `(<XDG_CONFIG_HOME> or <HOME>/.config)/<CompanyName>/<ProjectName>/settings/`
         *
         * Windows:
         * `<APPDATA>/<CompanyName>/<ProjectName>/settings/`
         */
        [[nodiscard]] std::filesystem::path projectSettingsRootPath() const {
            return mExecutableContext.mProjectSettingsRootPath;
        }

        /**
         * \returns Root directory for this application's settings.
         *
         * Project-portable mode:
         * `<ProjectInstallationRoot>/settings/<TargetName>/`
         *
         * Installed mode:
         * Linux/macOS-like:
         * `(<XDG_CONFIG_HOME> or <HOME>/.config)/<CompanyName>/<ProjectName>/settings/<TargetName>/`
         *
         * Windows:
         * `<APPDATA>/<CompanyName>/<ProjectName>/settings/<TargetName>/`
         *
         * Project-portable mode is used when `isProjectPortable()` is `true`;
         * otherwise the per-user installed layout is used.
         */
        [[nodiscard]] std::filesystem::path appSettingsRootPath() const {
            return mExecutableContext.mAppSettingsRootPath;
        }

        /**
         * \returns Root directory for default project log files.
         *
         * Project-portable mode:
         * `<ProjectInstallationRoot>/logs/`
         *
         * Installed mode:
         * Linux/macOS-like:
         * `(<XDG_CONFIG_HOME> or <HOME>/.config)/<CompanyName>/<ProjectName>/logs/`
         *
         * Windows:
         * `<APPDATA>/<CompanyName>/<ProjectName>/logs/`
         */
        [[nodiscard]] std::filesystem::path defaultProjectLogsRootPath() const {
            return mExecutableContext.mDefaultProjectLogsRootPath;
        }

        /**
         * \returns Root directory for default log files of this application.
         *
         * Project-portable mode:
         * `<ProjectInstallationRoot>/logs/<TargetName>/`
         *
         * Installed mode:
         * Linux/macOS-like:
         * `(<XDG_CONFIG_HOME> or <HOME>/.config)/<CompanyName>/<ProjectName>/logs/<TargetName>/`
         *
         * Windows:
         * `<APPDATA>/<CompanyName>/<ProjectName>/logs/<TargetName>/`
         */
        [[nodiscard]] std::filesystem::path defaultAppLogsRootPath() const {
            return mExecutableContext.mDefaultAppLogsRootPath;
        }

        /** \returns Root directory for all disk-backed runtime resources of the installed project. */
        [[nodiscard]] std::filesystem::path projectRuntimeResourcesRootPath() const {
            return mExecutableContext.mProjectRuntimeResourcesRootPath;
        }

        /**
         * \brief Resolves a file path under the runtime resource root.
         *
         * \param iRelativeResourcePath Path relative to `projectRuntimeResourcesRootPath()`.
         * It must not be absolute and must not contain parent traversal.
         *
         * \returns Normalized absolute path of the runtime resource file.
         * \throws std::invalid_argument if `iRelativeResourcePath` is empty or escapes the runtime resource root.
         */
        [[nodiscard]] std::filesystem::path runtimeResourceFilePath(const std::filesystem::path& iRelativeResourcePath) const;

    private:
        struct ExecutableContext {
            std::filesystem::path mAppExecutableFilePath;
            std::filesystem::path mProjectInstallationRootPath;
            std::filesystem::path mProjectBinariesRootPath;
            std::filesystem::path mProjectSettingsRootPath;
            std::filesystem::path mAppSettingsRootPath;
            std::filesystem::path mDefaultProjectLogsRootPath;
            std::filesystem::path mDefaultAppLogsRootPath;
            std::filesystem::path mProjectRuntimeResourcesRootPath;
            bool mIsProjectPortable;
        };

        /** \returns `<CompanyName_SHORT>::<ProjectNameBase>`. */
        [[nodiscard]] static std::string projectID(const AppMetadata& iAppMetadata);

        /** \returns `<CompanyName_SHORT>::<ProjectNameBase>::<TargetName>`. */
        [[nodiscard]] static std::string appID(const AppMetadata& iAppMetadata);

        /**
         * \brief Builds the fully resolved executable context for this app.
         *
         * Validates and normalizes the executable path according to the CMagneto Project layout,
         * detects project portability, and derives the cached project/app root paths.
         */
        [[nodiscard]] static ExecutableContext makeExecutableContext(
            const AppMetadata& iAppMetadata,
            std::filesystem::path iAppExecutableFilePath
        );

        /**
         * \brief Validates and normalizes an app executable path according to the CMagneto Project layout.
         *
         * The path must be non-empty, identify a file under a `bin/` directory, and allow derivation
         * of the project installation root as the parent of that `bin/` directory.
         *
         * \throws std::invalid_argument if the path does not satisfy the required layout.
         */
        [[nodiscard]] static std::filesystem::path normalizeAppExecutableFilePath(
            const std::filesystem::path& iAppExecutableFilePath
        );

        /**
         * \brief Validates and normalizes a runtime resource path relative to the runtime resource root.
         *
         * \throws std::invalid_argument if the path is empty, absolute, or contains parent traversal.
         */
        [[nodiscard]] static std::filesystem::path normalizeRuntimeResourceRelativePath(
            const std::filesystem::path& iRelativeResourcePath
        );

        /** \returns Project settings root under the per-user config location for installed mode. */
        [[nodiscard]] static std::filesystem::path installedProjectSettingsRootPath(const AppMetadata& iAppMetadata);

        const AppMetadata mAppMetadata;
        const std::string mProjectID;
        const std::string mAppID;
        const ExecutableContext mExecutableContext;
        Logger mLogger;
    };


} // namespace CMagneto::Core
