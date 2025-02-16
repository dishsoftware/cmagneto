#include <iostream>
#include "Contacts_FieldType.hpp"
#include "Contacts_FieldTypeExtension.hpp"

int main() {
    std::cout << "Hello, World!" << std::endl;

    enowsw::contacts::FieldType::Enum field = enowsw::contacts::FieldType::Enum::kEMail;
    std::cout << "Field index: " << static_cast<int>(field) << std::endl;

    const auto& fieldString = enowsw::contacts::FieldType::toString(field);
    std::cout << "Field string: " << fieldString.toStdString() << std::endl;

    return 0;
}