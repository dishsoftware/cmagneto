#include "Enow/Contacts/Contacts/FieldType.hpp"
#include "Enow/Contacts/Contacts/FieldTypeExtension.hpp"
#include <iostream>
#include "Enow/Contacts/Contacts/dataTypes/Email.hpp"


int main() {
    std::cout << "Hello, World!" << std::endl;

    const auto field = Enow::Contacts::Contacts::FieldType::Enum::kEMail;
    std::cout << "Enow::Contacts::Contacts::FieldType::Enum::kEMail index: " << static_cast<int>(field) << std::endl;

    const auto& fieldString = Enow::Contacts::Contacts::FieldType::toString(field);
    std::cout << "Enow::Contacts::Contacts::FieldType::toString(kEMail): " << fieldString.toStdString() << std::endl;

    auto email = Enow::Contacts::Contacts::dataTypes::Email();

    return 0;
}