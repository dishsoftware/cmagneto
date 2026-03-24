#pragma once

#include "Contacts_DEFS.hpp"

#include "FieldType.hpp"

#include <QString>

#include <set>


namespace Dish::ContactHolder::Contacts::FieldType {
    DISH_CONTACTHOLDER_CONTACTS_EXPORT const std::set<Enum>& allEnums();
    DISH_CONTACTHOLDER_CONTACTS_EXPORT const std::set<QString>& allStrings();

    DISH_CONTACTHOLDER_CONTACTS_EXPORT const QString& toString(const Enum iEnum);

    /** \throws std::invalid_argument, if iStr is not in allStrings(). */
    DISH_CONTACTHOLDER_CONTACTS_EXPORT Enum toEnum(const QString& iStr);
} // namespace Dish::ContactHolder::Contacts::FieldType
