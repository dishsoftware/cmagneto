// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "DishSW/ContactHolder/Contacts/FieldTypeExtension.hpp"

#include <gtest/gtest.h>


namespace DishSW::ContactHolder::Contacts::FieldType {


    TEST(DishSW_ContactHolder_Contacts_FieldType, ToStringFromString) {

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


} // namespace  DishSW::ContactHolder::Contacts::FieldType
