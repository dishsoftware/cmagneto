#pragma once

#include "Contacts.hpp"
#include <cstdint>


namespace Enow::Contacts::Contacts::FieldType {
    enum class CONTACTS_EXPORT Enum : std::uint8_t {
        kString, // Generic string without restrictions.
        kPhoneNumber,
        kEMail,
        kLocation, // Address, coordinates.
        kGraphics // Images, Videos, GIFs, etc..
    };
} // namespace Enow::Contacts::Contacts::FieldType