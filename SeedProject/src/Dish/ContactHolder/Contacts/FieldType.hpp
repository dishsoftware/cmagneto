// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "Contacts_DEFS.hpp"

#include <cstdint>


namespace Dish::ContactHolder::Contacts::FieldType {
    enum class DISH_CONTACTHOLDER_CONTACTS_EXPORT Enum : std::uint8_t {
        kString, // Generic string without restrictions.
        kPhoneNumber,
        kEMailAddress,
        kLocation, // Address, coordinates.
        kGraphics // Images, Videos, GIFs, etc..
    };
} // namespace Dish::ContactHolder::Contacts::FieldType
