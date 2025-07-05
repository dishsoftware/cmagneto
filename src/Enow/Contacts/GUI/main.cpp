#include "Enow/Contacts/Contacts/FieldType.hpp"
#include "Enow/Contacts/Contacts/FieldTypeExtension.hpp"
#include "Enow/Contacts/Contacts/fields/EmailAddress.hpp"

#include <QCoreApplication>
#include <QIcon>

#include <iostream>


int main() {
    std::wcout << QCoreApplication::translate("Enow::Contacts::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = Enow::Contacts::Contacts::FieldType::Enum::kEMailAddress;
    std::cout << "Enow::Contacts::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = Enow::Contacts::Contacts::FieldType::toString(fieldType);
    std::cout << "Enow::Contacts::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdString() << std::endl;

    auto emailAddress = Enow::Contacts::Contacts::fields::EmailAddress();

    QIcon iconContacts(":/Enow/Contacts/Contacts/icons/logo.svg");
    QIcon iconGUI(":/Enow/Contacts/GUI/icons/logo.svg");

    return 0;
}