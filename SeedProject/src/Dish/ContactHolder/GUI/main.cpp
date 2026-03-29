// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "Dish/ContactHolder/Contacts/FieldType.hpp"
#include "Dish/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "Dish/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <QCoreApplication>
#include <QIcon>
#include <QStyleFactory>
#include <QApplication>

#include <iostream>

#include <zlib.h>


int main() {
    std::wcout << QApplication::translate("Dish::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = Dish::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
    std::wcout << "Dish::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = Dish::ContactHolder::Contacts::FieldType::toString(fieldType);
    std::wcout << "Dish::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

    auto emailAddress = Dish::ContactHolder::Contacts::fields::EmailAddress();
    std::wcout << "zlib version: " << zlibVersion() << std::endl;
    std::wcout << "Qt widget styles count: " << QStyleFactory::keys().size() << std::endl;

    QIcon iconContacts(":/Dish/ContactHolder/Contacts/icons/logo.svg");
    QIcon iconGUI(":/Dish/ContactHolder/GUI/icons/logo.svg");

    return 0;
}
