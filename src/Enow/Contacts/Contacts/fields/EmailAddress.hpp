#pragma once

#include "../Contacts_DEFS.hpp"

#include "../Field.hpp"

#include <QString>


namespace Enow::Contacts::Contacts::fields {
    class CONTACTS_EXPORT EmailAddress : public Enow::Contacts::Contacts::Field {
    // Fields.
    private:
        QString mLabel;
        QString mEmailAddress;

    // Methods.
    public:
        static constexpr FieldType::Enum kFieldType = FieldType::Enum::kEMailAddress;

        EmailAddress() noexcept = default;
        EmailAddress(const EmailAddress&) noexcept = default;
        EmailAddress(EmailAddress&&) noexcept = default;
        EmailAddress& operator=(const EmailAddress&) noexcept = default;
        EmailAddress& operator=(EmailAddress&&) noexcept = default;
        virtual ~EmailAddress() noexcept override = default;

        /*! \returns Deep copy of this instance. */
        virtual std::unique_ptr<Enow::Contacts::Contacts::Field> clone() const override;

        virtual FieldType::Enum fieldType() const noexcept override { return kFieldType; }

        const QString& label() const noexcept { return mLabel; }
        /*! \brief Leading and trailing whitespaces are trimmed. */
        void setLabel(const QString& iLabel);

        const QString& emailAddress() const noexcept { return mEmailAddress; }
        /*! \brief Sets email address.
            \note Leading and trailing whitespaces are trimmed.
            \note If iEmailAddress is not valid, mEmailAddress is not changed.
            \note Empty iEmailAddress is considered valid.
        \returns true, if iEmailAddress is valid. */
        bool setEmailAddress(const QString& iEmailAddress);

        /*! \returns JSON representation of this field. */
        virtual QJsonObject toJSON() const override;
    };
} // namespace Enow::Contacts::Contacts::fields