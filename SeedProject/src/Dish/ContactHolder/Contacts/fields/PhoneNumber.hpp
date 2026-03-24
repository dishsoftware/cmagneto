#pragma once

#include "../Contacts_DEFS.hpp"

#include "../Field.hpp"

#include <QString>


namespace Dish::ContactHolder::Contacts::fields {
    class DISH_CONTACTHOLDER_CONTACTS_EXPORT PhoneNumber : public Dish::ContactHolder::Contacts::Field {
    // Fields.
    private:
        QString mLabel;
        QString mPhoneNumber;

    // Methods.
    public:
        static constexpr FieldType::Enum kFieldType = FieldType::Enum::kPhoneNumber;

        PhoneNumber() noexcept = default;
        PhoneNumber(const PhoneNumber&) noexcept = default;
        PhoneNumber(PhoneNumber&&) noexcept = default;
        PhoneNumber& operator=(const PhoneNumber&) noexcept = default;
        PhoneNumber& operator=(PhoneNumber&&) noexcept = default;
        virtual ~PhoneNumber() noexcept override = default;

        /*! \returns Deep copy of this instance. */
        virtual std::unique_ptr<Dish::ContactHolder::Contacts::Field> clone() const override;

        virtual FieldType::Enum fieldType() const noexcept override { return kFieldType; }

        const QString& label() const noexcept { return mLabel; }
        /*! \brief Leading and trailing whitespaces are trimmed. */
        void setLabel(const QString& iLabel);

        const QString& phoneNumber() const noexcept { return mPhoneNumber; }
        /*! \brief Sets phone number.
            \note Leading and trailing whitespaces are trimmed.
            \note If iPhoneNumber is not valid, mPhoneNumber is not changed.
            \note Empty iPhoneNumber is considered valid.
        \returns true, if iPhoneNumber is valid. */
        bool setPhoneNumber(const QString& iPhoneNumber);

        const QString phoneNumberFormatted() const;

        /*! \returns JSON representation of this field. */
        virtual QJsonObject toJSON() const override;
    };
} // namespace Dish::ContactHolder::Contacts::fields
