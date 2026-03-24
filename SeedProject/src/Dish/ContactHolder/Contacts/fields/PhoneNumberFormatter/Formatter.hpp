#pragma once

#include "PhoneNumberFormatter_DEFS.hpp"

#include <QString>


namespace Dish::ContactHolder::Contacts::fields::PhoneNumberFormatter {
    class DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT Formatter {
    private:
        Formatter() = delete;

    public:
        static QString format(const QString& iPhoneNumber);
    };
} // namespace Dish::ContactHolder::Contacts::fields::PhoneNumberFormatter
