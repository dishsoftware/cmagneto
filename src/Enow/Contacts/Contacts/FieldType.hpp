#pragma once

#include "Contacts.hpp"


namespace Enow::Contacts::Contacts::FieldType {
    enum class CONTACTS_EXPORT Enum {
        kString, // Generic string without restrictions.
        kPhoneNumber,
        kEMail,
        kLocation, // Address, coordinates.
        kGraphics // Images, Videos, GIFs, etc..
    };
} // namespace Enow::Contacts::Contacts::FieldType