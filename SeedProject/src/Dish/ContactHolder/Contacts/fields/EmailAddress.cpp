#include "EmailAddress.hpp"


namespace Dish::ContactHolder::Contacts::fields {
    std::unique_ptr<Dish::ContactHolder::Contacts::Field> EmailAddress::clone() const {
        // Not noexcept because of std::make_unique: memory allocation failure (underlying new operator) may happen.
        return std::make_unique<EmailAddress>(*this);
    }

    void EmailAddress::setLabel(const QString& iLabel) {
        mLabel = iLabel.trimmed();
    }

    bool EmailAddress::setEmailAddress(const QString& iEmailAddress) {
        // TODO Implement actual emal address validation logic.
        mEmailAddress = iEmailAddress.trimmed();
        return true;
    }

    QJsonObject EmailAddress::toJSON() const {
        QJsonObject obj = Field::toJSON();
        obj["Label"] = mLabel;
        obj["EmailAddress"] = mEmailAddress;
        return obj;
    }
} // namespace Dish::ContactHolder::Contacts::fields