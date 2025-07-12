#pragma once

#include "PhoneNumberFormatter_DEFS.hpp"

#include <QString>


namespace Dish::ContactHolder::Contacts::fields::PhoneNumberFormatter {
    class PHONENUMBERFORMATTER_EXPORT Formatter {
    private:
        Formatter() = delete;

    public:
        static QString format(const QString& iPhoneNumber);
    };
} // namespace Dish::ContactHolder::Contacts::fields::PhoneNumberFormatter