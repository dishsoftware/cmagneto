#include "PhoneNumber.hpp"

#include "PhoneNumberFormatter/Formatter.hpp"


namespace Enow::ContactHolder::Contacts::fields {
    std::unique_ptr<Enow::ContactHolder::Contacts::Field> PhoneNumber::clone() const {
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
} // namespace Enow::ContactHolder::Contacts::fields