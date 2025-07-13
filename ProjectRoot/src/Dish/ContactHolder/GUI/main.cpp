#include "Dish/ContactHolder/Contacts/FieldType.hpp"
#include "Dish/ContactHolder/Contacts/FieldTypeExtension.hpp"
#include "Dish/ContactHolder/Contacts/fields/EmailAddress.hpp"

#include <QCoreApplication>
#include <QIcon>

#include <iostream>


int main() {
    std::wcout << QCoreApplication::translate("Dish::ContactHolder::GUI::main", "GREETING").toStdWString() << std::endl;

    const auto fieldType = Dish::ContactHolder::Contacts::FieldType::Enum::kEMailAddress;
    std::wcout << "Dish::ContactHolder::Contacts::FieldType::Enum::kEMailAddress index: " << static_cast<int>(fieldType) << std::endl;

    const auto& fieldTypeString = Dish::ContactHolder::Contacts::FieldType::toString(fieldType);
    std::wcout << "Dish::ContactHolder::Contacts::FieldType::toString(kEMailAddress): " << fieldTypeString.toStdWString() << std::endl;

    auto emailAddress = Dish::ContactHolder::Contacts::fields::EmailAddress();

    QIcon iconContacts(":/Dish/ContactHolder/Contacts/icons/logo.svg");
    QIcon iconGUI(":/Dish/ContactHolder/GUI/icons/logo.svg");

    return 0;
}