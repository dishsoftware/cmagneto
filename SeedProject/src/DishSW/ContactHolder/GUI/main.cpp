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
#include <QCoreApplication>
#include <QIcon>
#include <QStyleFactory>
#include <zlib.h>

#include <iostream>


int main(int argc, char* argv[]) {
    CLI::App cliApp{DishSW::ContactHolder::projectNameForUI()};
    cliApp.description(DishSW::ContactHolder::projectDescription());
    cliApp.allow_extras();

    bool cliVersionFlag = false;
    cliApp.add_flag("--version,-v", cliVersionFlag, "Print version and exit.");

    CLI11_PARSE(cliApp, argc, argv);

    if(cliVersionFlag) {
        if(argc != 2) {
            std::cerr << "The --version command must be used without any other arguments." << std::endl;
            return 1;
        }

        std::cout << DishSW::ContactHolder::version() << std::endl;
        return 0;
    }

    QApplication qApplication(argc, argv);

    std::wcout << QApplication::translate("DishSW::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
    std::wcout << "DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = DishSW::ContactHolder::Contacts::FieldType::toString(fieldType);
    std::wcout << "DishSW::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

    auto emailAddress = DishSW::ContactHolder::Contacts::fields::EmailAddress();
    std::wcout << "zlib version: " << zlibVersion() << std::endl;
    std::wcout << "Qt widget styles count: " << QStyleFactory::keys().size() << std::endl;

    std::wcout << "Project version: " << DishSW::ContactHolder::version() << std::endl;

    QIcon iconContacts(":/DishSW/ContactHolder/Contacts/icons/logo.svg");
    QIcon iconGUI(":/DishSW/ContactHolder/GUI/icons/logo.svg");

    return 0;
}
