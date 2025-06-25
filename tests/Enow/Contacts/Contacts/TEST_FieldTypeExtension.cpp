#include "Enow/Contacts/Contacts/FieldTypeExtension.hpp"

#include <gtest/gtest.h>


TEST(Enow_Contacts_Contacts, FieldTypeExtension) {
    using namespace Enow::Contacts::Contacts::FieldType;

    // Check allEnums() and allStrings() correspond to each other.
    std::set<QString> stringsFromEnums{};
    for (const auto& enumVal : allEnums()) {
        const auto stringFromEnum = toString(enumVal);
        const auto enumFromString = toEnum(stringFromEnum);
        ASSERT_EQ(enumVal, enumFromString);
        ASSERT_EQ(stringFromEnum, toString(enumFromString));
        stringsFromEnums.insert(stringFromEnum);
    }

    ASSERT_EQ(stringsFromEnums.size(), allStrings().size());
    for (const auto& string : allStrings()) {
        ASSERT_TRUE(stringsFromEnums.find(string) != stringsFromEnums.end());
    }
}