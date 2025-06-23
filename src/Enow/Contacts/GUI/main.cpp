#include <iostream>
#include "Enow/Contacts/Contacts/FieldType.hpp"
#include "Enow/Contacts/Contacts/FieldTypeExtension.hpp"


int main() {
    std::cout << "Hello, World!" << std::endl;

    Enow::Contacts::Contacts::FieldType::Enum field = Enow::Contacts::Contacts::FieldType::Enum::kEMail;
    std::cout << "Field index: " << static_cast<int>(field) << std::endl;

    const auto& fieldString = Enow::Contacts::Contacts::FieldType::toString(field);
    std::cout << "Field string: " << fieldString.toStdString() << std::endl;

    return 0;
}