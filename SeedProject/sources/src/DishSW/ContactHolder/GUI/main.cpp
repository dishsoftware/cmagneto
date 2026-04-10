// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "GUI_DEFS.hpp"

#include "DishSW/ContactHolder/Contacts/FieldType.hpp"
#include "DishSW/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "DishSW/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <CLI/CLI.hpp>
#include <QApplication>
#include <QIcon>
#include <QMainWindow>
#include <QStyleFactory>
#include <zlib.h>

#include <cstdlib>
#include <iostream>


int main(int iArgumentsSize, char* iArguments[]) {
    CLI::App cliApp{DishSW::ContactHolder::projectNameForUI()};
    cliApp.description(DishSW::ContactHolder::projectDescription());
    cliApp.allow_extras();

    bool cliVersionFlag = false;
    cliApp.add_flag("--version, -v", cliVersionFlag, "Print version and exit.");

    CLI11_PARSE(cliApp, iArgumentsSize, iArguments);

    if (cliVersionFlag) {
        if(iArgumentsSize != 2) {
            std::cerr << "The --version command must be used without any other arguments." << std::endl;
            return EXIT_FAILURE;
        }

        std::cout << DishSW::ContactHolder::version() << std::endl;
        return EXIT_SUCCESS;
    }


    QApplication qApplication(iArgumentsSize, iArguments);
    // qApplication.setOrganizationName(QString::fromUtf8(DishSW::ContactHolder::compamyNameShort()));
	qApplication.setApplicationName(QString::fromUtf8(DishSW::ContactHolder::projectNameForUI()));
	qApplication.setApplicationVersion(QString::fromUtf8(DishSW::ContactHolder::version()));
	qApplication.setWindowIcon(QIcon(QStringLiteral(":/DishSW/ContactHolder/GUI/icons/logo.svg")));

    try {

        { // Boilerplate output
            std::wcout << QApplication::translate("DishSW::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

            const auto fieldType = DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
            std::wcout << "DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

            const auto& fieldTypeString = DishSW::ContactHolder::Contacts::FieldType::toString(fieldType);
            std::wcout << "DishSW::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

            auto emailAddress = DishSW::ContactHolder::Contacts::fields::EmailAddress();
            std::wcout << "zlib version: " << zlibVersion() << std::endl;
            std::wcout << "Qt widget styles count: " << QStyleFactory::keys().size() << std::endl;
        } // Boilerplate output

        QMainWindow mainWindow;
        mainWindow.setWindowTitle(QString::fromUtf8(DishSW::ContactHolder::projectNameForUI()));
        mainWindow.setWindowIcon(qApplication.windowIcon()); // Window instance may use non application-wide default window icon.
        mainWindow.resize(960, 640);
        mainWindow.show();

		return qApplication.exec();
    }
    catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    catch (...) {
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
}
