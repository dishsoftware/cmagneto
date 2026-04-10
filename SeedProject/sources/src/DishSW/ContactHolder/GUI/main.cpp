// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "GUI_DEFS.hpp"

#include "CMagneto/Core/binaryTools/currentExecutableFilePath.hpp"
#include "CMagneto/Core/logger/sinks/Console.hpp"
#include "CMagneto/Core/logger/sinks/File.hpp"
#include "CMagneto/Qt/Widgets/AppContext.hpp"
#include "CMagneto/Qt/Widgets/MainWindow.hpp"

#include "DishSW/ContactHolder/Contacts/FieldType.hpp"
#include "DishSW/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "DishSW/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <CLI/CLI.hpp>
#include <QApplication>
#include <QIcon>
#include <QStyleFactory>
#include <zlib.h>

#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <map>
#include <memory>
#include <string>


namespace {


    class SinkLogLevels {
    public:
        struct Settings {
            CMagneto::Core::Logger::Level::Enum mDefaultLogLevel;
            std::string_view mLogLevelEnvVarName;
        };

        inline static constexpr std::string_view kConsoleSinkID{"console"};
        inline static constexpr std::string_view kFileSinkID{"file"};

        inline static const std::map<std::string_view, Settings> kSettingsBySinkID{
            {
                kConsoleSinkID,
                {
                    .mDefaultLogLevel = CMagneto::Core::Logger::Level::Enum::kInfo,
                    .mLogLevelEnvVarName = "DISHSW_CONTACTHOLDER_GUI__CONSOLE_LOG_LEVEL"
                }
            },
            {
                kFileSinkID,
                {
                    .mDefaultLogLevel = CMagneto::Core::Logger::Level::Enum::kOff,
                    .mLogLevelEnvVarName = "DISHSW_CONTACTHOLDER_GUI__FILE_LOG_LEVEL"
                }
            }
        };

        SinkLogLevels() {
            parseEnvVars();
        }

        [[nodiscard]] CMagneto::Core::Logger::Level::Enum level(const std::string_view iSinkID) const {
            return mLevelsBySinkID.at(iSinkID);
        }

    private:
        void parseEnvVars() {
            for (const auto& [sinkID, settings] : kSettingsBySinkID) {
                mLevelsBySinkID.emplace(sinkID, settings.mDefaultLogLevel);

                const char* const logLevelEnvValue = std::getenv(settings.mLogLevelEnvVarName.data());
                if (logLevelEnvValue == nullptr || *logLevelEnvValue == '\0')
                    continue;

                const std::optional<CMagneto::Core::Logger::Level::Enum> parsedLevel =
                    CMagneto::Core::Logger::Level::fromString(logLevelEnvValue)
                ;

                if (parsedLevel.has_value()) {
                    mLevelsBySinkID.at(sinkID) = *parsedLevel;
                    continue;
                }

                std::cerr
                    << "Environment variable " << settings.mLogLevelEnvVarName
                    << " has invalid value: " << logLevelEnvValue
                    << ". Using " << CMagneto::Core::Logger::Level::toString(settings.mDefaultLogLevel)
                    << "."
                    << std::endl
                ;
            }
        }

        std::map<std::string_view, CMagneto::Core::Logger::Level::Enum> mLevelsBySinkID;
    };


} // namespace


int main(int iArgumentsSize, char* iArguments[]) {
    const CMagneto::Core::AppContext::AppIdentity appIdentity{
        DishSW::ContactHolder::companyNameShort(),
        DishSW::ContactHolder::projectNameBase(),
        DishSW::ContactHolder::projectNameForUI(),
        DishSW::ContactHolder::projectDescription(),
        DishSW::ContactHolder::GUI::targetName(),
        DishSW::ContactHolder::version(),
        DishSW::ContactHolder::versionMajor(),
        DishSW::ContactHolder::versionMinor(),
        DishSW::ContactHolder::versionPatch(),
        CMagneto::Core::binaryTools::currentExecutableFilePath()
    };


    { // CLI application context.
        CLI::App cliApp{std::string{appIdentity.mProjectNameForUI}.append(" ").append(appIdentity.mTargetName)};
        cliApp.description(std::string{appIdentity.mProjectDescription});
        cliApp.allow_extras();

        bool cliVersionFlag = false;
        cliApp.add_flag("--version, -v", cliVersionFlag, "Print version and exit.");

        CLI11_PARSE(cliApp, iArgumentsSize, iArguments);

        if (cliVersionFlag) {
            if(iArgumentsSize != 2) {
                std::cerr << "The --version command must be used without any other arguments." << std::endl;
                return EXIT_FAILURE;
            }

            std::cout << appIdentity.mVersion << std::endl;
            return EXIT_SUCCESS;
        }
    } // CLI application context.


    { // QApplication context.
        CMagneto::Qt::Widgets::AppContext appContext{appIdentity};

        { // Set up logging.
            const SinkLogLevels sinkLogLevels;

            const bool isConsoleSinkAdded = appContext.logger().addSink(
                SinkLogLevels::kConsoleSinkID.data(),
                std::make_shared<CMagneto::Core::logger::sinks::Console>(
                    true,
                    appContext.appIdentityString()
                ),
                sinkLogLevels.level(SinkLogLevels::kConsoleSinkID)
            );
            DISHSW_CONTACTHOLDER_GUI_VERIFY(isConsoleSinkAdded);

            const CMagneto::Core::Logger::Level::Enum fileLogLevel =
                sinkLogLevels.level(SinkLogLevels::kFileSinkID)
            ;

            if (fileLogLevel != CMagneto::Core::Logger::Level::Enum::kOff) {
                const std::filesystem::path fileLogFilePath = appContext.settingsDirPath().parent_path() / "log.txt";
                const auto fileSink = std::make_shared<CMagneto::Core::logger::sinks::File>(
                    fileLogFilePath,
                    false,
                    appContext.appIdentityString()
                );

                if (!fileSink->errorMessage().empty()) {
                    const bool fileSinkWarningLogged = appContext.logger().log(
                        CMagneto::Core::Logger::Level::Enum::kWarning,
                        "Launch",
                        std::string{"Failed to initialize file sink for "}
                            .append(fileLogFilePath.string())
                            .append(". ")
                            .append(fileSink->errorMessage())
                    );
                    DISHSW_CONTACTHOLDER_GUI_VERIFY(fileSinkWarningLogged);
                }
                else {
                    const bool isFileSinkAdded = appContext.logger().addSink(
                        SinkLogLevels::kFileSinkID.data(),
                        fileSink,
                        fileLogLevel
                    );

                    if (!isFileSinkAdded) {
                        const bool fileSinkWarningLogged = appContext.logger().log(
                            CMagneto::Core::Logger::Level::Enum::kWarning,
                            "Launch",
                            std::string{"Failed to add file sink for "}.append(fileLogFilePath.string())
                        );
                        DISHSW_CONTACTHOLDER_GUI_VERIFY(fileSinkWarningLogged);
                    }
                }
            }
        } // Set up logging.

        QApplication qApplication(iArgumentsSize, iArguments);
        qApplication.setOrganizationName(QString::fromUtf8(appIdentity.mCompanyNameShort.data()));
        qApplication.setApplicationName(
            QString::fromUtf8(appIdentity.mProjectNameBase.data())
            + QLatin1Char('_')
            + QString::fromUtf8(appIdentity.mTargetName.data())
        );
        qApplication.setApplicationVersion(QString::fromUtf8(appIdentity.mVersion.data()));
        qApplication.setWindowIcon(QIcon(QStringLiteral(":/DishSW/ContactHolder/GUI/icons/logo.svg")));

        try {
            const std::string launchMode = appContext.isPortable() ? "portable" : "installed";
            const std::string settingsDirPath = appContext.settingsDirPath().string();

            const bool startLogged = appContext.logger().log(
                CMagneto::Core::Logger::Level::Enum::kInfo,
                "Launch",
                std::string{appIdentity.mProjectNameForUI}.append(" started.")
            );
            DISHSW_CONTACTHOLDER_GUI_VERIFY(startLogged);

            const bool launchModeLogged = appContext.logger().log(
                CMagneto::Core::Logger::Level::Enum::kInfo,
                "Launch",
                std::string{"Launch mode: "}.append(launchMode)
            );
            DISHSW_CONTACTHOLDER_GUI_VERIFY(launchModeLogged);

            const bool settingsDirLogged = appContext.logger().log(
                CMagneto::Core::Logger::Level::Enum::kInfo,
                "Launch",
                std::string{"Settings directory: "}.append(settingsDirPath)
            );
            DISHSW_CONTACTHOLDER_GUI_VERIFY(settingsDirLogged);

            { // Boilerplate output.
                std::wcout << QApplication::translate("DishSW::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

                const auto fieldType = DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
                std::wcout << "DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

                const auto& fieldTypeString = DishSW::ContactHolder::Contacts::FieldType::toString(fieldType);
                std::wcout << "DishSW::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

                auto emailAddress = DishSW::ContactHolder::Contacts::fields::EmailAddress();
                std::wcout << "zlib version: " << zlibVersion() << std::endl;
                std::wcout << "Qt widget styles count: " << QStyleFactory::keys().size() << std::endl;
            } // Boilerplate output.

            CMagneto::Qt::Widgets::MainWindow mainWindow{
                appContext,
                CMagneto::Core::HierarchicalID{"/MainWindow"}
            };
            mainWindow.setObjectName(QStringLiteral("MainWindow"));
            mainWindow.setWindowTitle(QString::fromUtf8(appIdentity.mProjectNameForUI.data()));
            mainWindow.setWindowIcon(qApplication.windowIcon()); // Window instance may use non application-wide default window icon.
            mainWindow.resize(960, 640);
            mainWindow.loadSettings();
            mainWindow.show();

            return qApplication.exec();
        }
        catch (const std::exception& e) {
            const bool exceptionLogged = appContext.logger().log(
                CMagneto::Core::Logger::Level::Enum::kError,
                "Runtime",
                e.what()
            );
            static_cast<void>(exceptionLogged);
            std::cerr << e.what() << std::endl;
            return EXIT_FAILURE;
        }
        catch (...) {
            const bool unknownExceptionLogged = appContext.logger().log(
                CMagneto::Core::Logger::Level::Enum::kCritical,
                "Runtime",
                "Unknown unhandled exception"
            );
            static_cast<void>(unknownExceptionLogged);
            std::cerr << "Unknown unhandled exception" << std::endl;
            return EXIT_FAILURE;
        }

        // TODO
        // Best options to notify GUI user about an exception caught by the last resort catch blocks.
        //
        // 1. Record crash info, notify on next launch.
        //      In the catch block, write an error file or crash marker.
        //      On next startup, if that marker exists, show a normal QMessageBox saying the previous run failed.
        //      This is the safest GUI-user notification approach.
        // 2. Best-effort native OS dialog.
        //      In the catch block, call a platform-native API instead of Qt GUI.
        //      Example: Windows MessageBoxW(...).
        //      This avoids relying on Qt’s possibly-broken GUI state.
        //      Downside: platform-specific, still not 100% guaranteed.
        // 3. Spawn external helper process.
        //      In the catch block, start a tiny separate executable/script that shows an error dialog.
        //      That helper is outside the broken process, so it is more reliable than showing a Qt dialog inside the crashing app.
    } // QApplication context.
}
