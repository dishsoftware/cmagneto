#pragma once

#include "Contacts_DEFS.hpp"

#include <cstdint>


namespace Dish::ContactHolder::Contacts::FieldType {
    enum class CONTACTS_EXPORT Enum : std::uint8_t {
        kString, // Generic string without restrictions.
        kPhoneNumber,
        kEMailAddress,
        kLocation, // Address, coordinates.
        kGraphics // Images, Videos, GIFs, etc..
    };
} // namespace Dish::ContactHolder::Contacts::FieldType