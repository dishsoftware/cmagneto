// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "PhoneNumberFormatter_DEFS.hpp"

#include <QString>


namespace DishSW::ContactHolder::Contacts::fields::PhoneNumberFormatter {
    class DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT Formatter {
    private:
        Formatter() = delete;

    public:
        static QString format(const QString& iPhoneNumber);
    };
} // namespace DishSW::ContactHolder::Contacts::fields::PhoneNumberFormatter
