// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "DishSW/ContactHolder/Contacts/fields/PhoneNumber.hpp"

#include "DishSW/ContactHolder/Contacts/fields/PhoneNumberFormatter/Formatter.hpp"


namespace DishSW::ContactHolder::Contacts::fields {
    std::unique_ptr<DishSW::ContactHolder::Contacts::Field> PhoneNumber::clone() const {
        // Not noexcept because of std::make_unique: memory allocation failure (underlying new operator) may happen.
        return std::make_unique<PhoneNumber>(*this);
    }

    void PhoneNumber::setLabel(const QString& iLabel) {
        mLabel = iLabel.trimmed();
    }

    bool PhoneNumber::setPhoneNumber(const QString& iPhoneNumber) {
        // TODO Implement actual phone number validation logic.
        mPhoneNumber = iPhoneNumber.trimmed();
        return true;
    }

    const QString PhoneNumber::phoneNumberFormatted() const {
        return PhoneNumberFormatter::Formatter::format(mPhoneNumber);
    }

    QJsonObject PhoneNumber::toJSON() const {
        QJsonObject obj = Field::toJSON();
        obj["Label"] = mLabel;
        obj["PhoneNumber"] = mPhoneNumber;
        return obj;
    }
} // namespace DishSW::ContactHolder::Contacts::fields
