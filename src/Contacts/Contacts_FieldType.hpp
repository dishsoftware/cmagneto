#ifndef ENOWSW_CONTACTS_FIELDTYPE_HPP
#define ENOWSW_CONTACTS_FIELDTYPE_HPP

#include "Contacts.hpp"


namespace enowsw::contacts::FieldType {
    enum class CONTACTS_EXPORT Enum {
        kString, // Generic string without restrictions.
        kPhoneNumber,
        kEMail,
        kLocation, // Address, coordinates.
        kGraphics // Images, Videos, GIFs, etc..
    };
} // namespace enowsw::contacts::FieldType

#endif // ENOWSW_CONTACTS_FIELDTYPE_HPP