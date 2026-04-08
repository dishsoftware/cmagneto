// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "../Contacts_DEFS.hpp"

#include "../Field.hpp"

#include <QString>


namespace DishSW::ContactHolder::Contacts::fields {
    class DISHSW_CONTACTHOLDER_CONTACTS_EXPORT EmailAddress : public DishSW::ContactHolder::Contacts::Field {
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
        virtual std::unique_ptr<DishSW::ContactHolder::Contacts::Field> clone() const override;

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
} // namespace DishSW::ContactHolder::Contacts::fields
