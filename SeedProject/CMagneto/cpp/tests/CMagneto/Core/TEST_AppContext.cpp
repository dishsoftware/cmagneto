#include "CMagneto/Core/AppContext.hpp"

#include <gtest/gtest.h>

#include <fstream>
#include <cstdlib>
#include <stdexcept>
#include <system_error>


namespace CMagneto::Core {


    namespace {


        [[nodiscard]] AppContext::AppMetadata makeAppMetadata() {
            return AppContext::AppMetadata{
                .mCompanyNameShort = "DishSW",
                .mProjectNameBase = "ContactHolder",
                .mTargetName = "GUI",
                .mProjectVersionString = "1.2.3",
                .mProjectVersionMajor = 1,
                .mProjectVersionMinor = 2,
                .mProjectVersionPatch = 3,
                .mProjectNameForUI = "Contact Holder",
                .mProjectDescription = "Test application metadata"
            };
        }


        [[nodiscard]] std::filesystem::path expectedInstalledProjectSettingsRoot(const AppContext::AppMetadata& iAppMetadata) {
#ifdef _WIN32
            const char* const appData = std::getenv("APPDATA");
            return std::filesystem::path{appData == nullptr ? "" : appData}
                / iAppMetadata.mCompanyNameShort
                / iAppMetadata.mProjectNameBase
                / AppContext::kSettingsDirName;
#else
            const char* const xdgConfigHome = std::getenv("XDG_CONFIG_HOME");
            if (xdgConfigHome != nullptr && *xdgConfigHome != '\0') {
                return std::filesystem::path{xdgConfigHome}
                    / iAppMetadata.mCompanyNameShort
                    / iAppMetadata.mProjectNameBase
                    / AppContext::kSettingsDirName;
            }

            const char* const home = std::getenv("HOME");
            return std::filesystem::path{home == nullptr ? "" : home}
                / ".config"
                / iAppMetadata.mCompanyNameShort
                / iAppMetadata.mProjectNameBase
                / AppContext::kSettingsDirName;
#endif
        }


        [[nodiscard]] std::filesystem::path expectedInstalledProjectLogsRoot(const AppContext::AppMetadata& iAppMetadata) {
            return expectedInstalledProjectSettingsRoot(iAppMetadata).parent_path() / AppContext::kLogsDirName;
        }


    } // namespace


    TEST(CMagneto_Core_AppContext, ComputesProjectInstallationRootAndRuntimeResourcePathsFromAppExecutablePath) {
        const AppContext::AppMetadata appMetadata = makeAppMetadata();
        const AppContext appContext{appMetadata, "/opt/contact-holder/bin/ContactHolder_GUI"};

        EXPECT_EQ(appContext.appExecutableFilePath(), std::filesystem::path("/opt/contact-holder/bin/ContactHolder_GUI"));
        EXPECT_EQ(appContext.projectInstallationRootPath(), std::filesystem::path("/opt/contact-holder"));
        EXPECT_EQ(appContext.projectBinariesRootPath(), std::filesystem::path("/opt/contact-holder/bin"));
        EXPECT_EQ(appContext.projectSettingsRootPath(), expectedInstalledProjectSettingsRoot(appMetadata));
        EXPECT_EQ(
            appContext.appSettingsRootPath(),
            expectedInstalledProjectSettingsRoot(appMetadata) / "GUI"
        );
        EXPECT_EQ(appContext.defaultProjectLogsRootPath(), expectedInstalledProjectLogsRoot(appMetadata));
        EXPECT_EQ(
            appContext.defaultAppLogsRootPath(),
            expectedInstalledProjectLogsRoot(appMetadata) / "GUI"
        );
        EXPECT_EQ(appContext.projectRuntimeResourcesRootPath(), std::filesystem::path("/opt/contact-holder/res"));
        EXPECT_EQ(
            appContext.runtimeResourceFilePath("GUI/launch.json"),
            std::filesystem::path("/opt/contact-holder/res/GUI/launch.json")
        );
    }


    TEST(CMagneto_Core_AppContext, NormalizesRuntimeResourceRelativePaths) {
        const AppContext::AppMetadata appMetadata = makeAppMetadata();
        const AppContext appContext{appMetadata, "/opt/contact-holder/bin/ContactHolder_GUI"};

        EXPECT_EQ(
            appContext.runtimeResourceFilePath("./GUI/./launch.json"),
            std::filesystem::path("/opt/contact-holder/res/GUI/launch.json")
        );
    }


    TEST(CMagneto_Core_AppContext, RejectsUnsafeRuntimeResourcePaths) {
        const AppContext::AppMetadata appMetadata = makeAppMetadata();
        const AppContext appContext{appMetadata, "/opt/contact-holder/bin/ContactHolder_GUI"};

        EXPECT_THROW(
            static_cast<void>(appContext.runtimeResourceFilePath("")),
            std::invalid_argument
        );
        EXPECT_THROW(
            static_cast<void>(appContext.runtimeResourceFilePath("/etc/passwd")),
            std::invalid_argument
        );
        EXPECT_THROW(
            static_cast<void>(appContext.runtimeResourceFilePath("../secrets.txt")),
            std::invalid_argument
        );
    }


    TEST(CMagneto_Core_AppContext, RejectsExecutablePathsOutsideExpectedBinLayout) {
        const AppContext::AppMetadata appMetadata = makeAppMetadata();

        EXPECT_THROW(
            static_cast<void>(AppContext{appMetadata, ""}),
            std::invalid_argument
        );
        EXPECT_THROW(
            static_cast<void>(AppContext{appMetadata, "ContactHolder_GUI"}),
            std::invalid_argument
        );
        EXPECT_THROW(
            static_cast<void>(AppContext{appMetadata, "/opt/contact-holder/ContactHolder_GUI"}),
            std::invalid_argument
        );
        EXPECT_THROW(
            static_cast<void>(AppContext{appMetadata, "/opt/contact-holder/lib/ContactHolder_GUI"}),
            std::invalid_argument
        );
    }


    TEST(CMagneto_Core_AppContext, CachesProjectPortableLaunchModeAtConstruction) {
        const AppContext::AppMetadata appMetadata = makeAppMetadata();
        const std::filesystem::path testProjectInstallationRootPath = std::filesystem::temp_directory_path()
            / "cmagneto_app_context_is_portable_cache_test";
        const std::filesystem::path appExecutableFilePath = testProjectInstallationRootPath / "bin" / "ContactHolder_GUI";
        const std::filesystem::path portableMarkerFilePath = testProjectInstallationRootPath / AppContext::kPortableMarkerFileName;

        std::error_code errorCode;
        std::filesystem::remove_all(testProjectInstallationRootPath, errorCode);
        std::filesystem::create_directories(appExecutableFilePath.parent_path());

        {
            std::ofstream portableMarkerFile{portableMarkerFilePath};
            ASSERT_TRUE(portableMarkerFile.is_open());
        }

        const AppContext portableAppContext{appMetadata, appExecutableFilePath};
        std::filesystem::remove(portableMarkerFilePath);
        EXPECT_TRUE(portableAppContext.isProjectPortable());
        EXPECT_EQ(portableAppContext.projectSettingsRootPath(), testProjectInstallationRootPath / AppContext::kSettingsDirName);
        EXPECT_EQ(
            portableAppContext.appSettingsRootPath(),
            testProjectInstallationRootPath / AppContext::kSettingsDirName / appMetadata.mTargetName
        );
        EXPECT_EQ(portableAppContext.defaultProjectLogsRootPath(), testProjectInstallationRootPath / AppContext::kLogsDirName);
        EXPECT_EQ(
            portableAppContext.defaultAppLogsRootPath(),
            testProjectInstallationRootPath / AppContext::kLogsDirName / appMetadata.mTargetName
        );

        {
            std::ofstream portableMarkerFile{portableMarkerFilePath};
            ASSERT_TRUE(portableMarkerFile.is_open());
        }
        std::filesystem::remove(portableMarkerFilePath);

        const AppContext installedAppContext{appMetadata, appExecutableFilePath};
        {
            std::ofstream portableMarkerFile{portableMarkerFilePath};
            ASSERT_TRUE(portableMarkerFile.is_open());
        }
        EXPECT_FALSE(installedAppContext.isProjectPortable());
        EXPECT_EQ(installedAppContext.projectSettingsRootPath(), expectedInstalledProjectSettingsRoot(appMetadata));
        EXPECT_EQ(
            installedAppContext.appSettingsRootPath(),
            expectedInstalledProjectSettingsRoot(appMetadata) / appMetadata.mTargetName
        );
        EXPECT_EQ(installedAppContext.defaultProjectLogsRootPath(), expectedInstalledProjectLogsRoot(appMetadata));
        EXPECT_EQ(
            installedAppContext.defaultAppLogsRootPath(),
            expectedInstalledProjectLogsRoot(appMetadata) / appMetadata.mTargetName
        );

        std::filesystem::remove_all(testProjectInstallationRootPath, errorCode);
    }


} // namespace CMagneto::Core
