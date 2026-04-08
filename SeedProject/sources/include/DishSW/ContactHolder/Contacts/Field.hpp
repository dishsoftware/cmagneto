// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "Contacts_DEFS.hpp"

#include "FieldType.hpp"

#include <QJsonObject>

#include <memory>


namespace DishSW::ContactHolder::Contacts {
    class DISHSW_CONTACTHOLDER_CONTACTS_EXPORT Field {
    // Methods.
    protected:
        Field() noexcept = default;
        Field(const Field&) noexcept = default;
        Field(Field&&) noexcept = default;
        Field& operator=(const Field&) noexcept = default;
        Field& operator=(Field&&) noexcept = default;

    public:
        virtual ~Field() noexcept;

        /*! \returns Deep copy of this instance. */
        virtual std::unique_ptr<Field> clone() const = 0;

        virtual FieldType::Enum fieldType() const noexcept = 0;

        /*! \returns String representation of fieldType(). */
        const QString& fieldTypeID() const noexcept;

        /*! \returns JSON representation of this field. */
        virtual QJsonObject toJSON() const;
    };
} // namespace DishSW::ContactHolder::Contacts
