// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "Field.hpp"

#include "FieldTypeExtension.hpp"

#include <stdexcept>


namespace Dish::ContactHolder::Contacts {
    /*  Checks within the assignment constructors are overhead for runtime safety against severe developer mistakes.
        Despite:
        - These assignment operators are protected in the class;
        - All concrete derived classes SHOULD override or default their own public assignment operators with matching types
          E.g. PhoneNumber::operator=(const PhoneNumber&);
        It is possible to program some derived classes to accept different types in their assignment operators,
        while not keeping a value, returned by an overriden fieldType() method, static.

        This is unlikely, that's why the checks are disabled, and, hence, the assignment operators are defaulted.

    Field& Field::operator=(const Field& iOther) {
        if (fieldType() != iOther.fieldType())
            throw std::invalid_argument("Can't assign Field of a different FieldType.");

        return *this;
    }

    Field& Field::operator=(Field&& iOther) {
        if (this == &iOther)
            return *this;

        if (fieldType() != iOther.fieldType())
            throw std::invalid_argument("Can't assign Field of a different FieldType.");

        return *this;
    }
    */

    Field::~Field() noexcept = default;

    const QString& Field::fieldTypeID() const noexcept {
        return FieldType::toString(fieldType());
    }

    QJsonObject Field::toJSON() const {
        // The method is not marked as noexcept because, QJsonObject::operator[] is not marked as noexcept.
        QJsonObject obj;
        obj["FieldType"] = fieldTypeID();
        return obj;
    }
} // namespace Dish::ContactHolder::Contacts
