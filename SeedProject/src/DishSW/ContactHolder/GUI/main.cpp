// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "DishSW/ContactHolder/Contacts/FieldType.hpp"
#include "DishSW/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "DishSW/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <QCoreApplication>
#include <QIcon>
#include <QStyleFactory>
#include <QApplication>

#include <iostream>

#include <zlib.h>


int main() {
    std::wcout << QApplication::translate("DishSW::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
    std::wcout << "DishSW::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = DishSW::ContactHolder::Contacts::FieldType::toString(fieldType);
    std::wcout << "DishSW::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

    auto emailAddress = DishSW::ContactHolder::Contacts::fields::EmailAddress();
    std::wcout << "zlib version: " << zlibVersion() << std::endl;
    std::wcout << "Qt widget styles count: " << QStyleFactory::keys().size() << std::endl;

    QIcon iconContacts(":/DishSW/ContactHolder/Contacts/icons/logo.svg");
    QIcon iconGUI(":/DishSW/ContactHolder/GUI/icons/logo.svg");

    return 0;
}
