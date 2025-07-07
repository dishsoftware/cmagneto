#include "Enow/ContactHolder/Contacts/FieldType.hpp"
#include "Enow/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "Enow/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <QCoreApplication>
#include <QIcon>

#include <iostream>


int main() {
    std::wcout << QCoreApplication::translate("Enow::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = Enow::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
    std::wcout << "Enow::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = Enow::ContactHolder::Contacts::FieldType::toString(fieldType);
    std::wcout << "Enow::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

    auto emailAddress = Enow::ContactHolder::Contacts::fields::EmailAddress();

    QIcon iconContacts(":/Enow/ContactHolder/Contacts/icons/logo.svg");
    QIcon iconGUI(":/Enow/ContactHolder/GUI/icons/logo.svg");

    return 0;
}