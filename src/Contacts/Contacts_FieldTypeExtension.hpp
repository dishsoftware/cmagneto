#ifndef ENOWSW_CONTACTS_FIELDTYPEEXTENSION_HPP
#define ENOWSW_CONTACTS_FIELDTYPEEXTENSION_HPP

#include "Contacts_FieldType.hpp"
#include "Contacts.hpp"
#include <QString>
#include <set>


namespace enowsw::contacts::FieldType {
    CONTACTS_EXPORT const std::set<Enum>& allEnums();
    CONTACTS_EXPORT const std::set<QString>& allStrings();

    CONTACTS_EXPORT const QString& toString(const Enum iEnum);

    /** \throws std::invalid_argument, if iStr is not in allStrings(). */
    CONTACTS_EXPORT Enum toEnum(const QString& iStr);
} // namespace enowsw::contacts::FieldType

#endif // ENOWSW_CONTACTS_FIELDTYPEEXTENSION_HPP