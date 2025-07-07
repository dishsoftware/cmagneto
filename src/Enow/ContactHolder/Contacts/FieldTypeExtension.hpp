#pragma once

#include "Contacts_DEFS.hpp"

#include "FieldType.hpp"

#include <QString>

#include <set>


namespace Enow::ContactHolder::Contacts::FieldType {
    CONTACTS_EXPORT const std::set<Enum>& allEnums();
    CONTACTS_EXPORT const std::set<QString>& allStrings();

    CONTACTS_EXPORT const QString& toString(const Enum iEnum);

    /** \throws std::invalid_argument, if iStr is not in allStrings(). */
    CONTACTS_EXPORT Enum toEnum(const QString& iStr);
} // namespace Enow::ContactHolder::Contacts::FieldType