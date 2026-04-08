// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "Contacts_DEFS.hpp"

#include "FieldType.hpp"

#include <QString>

#include <set>


namespace DishSW::ContactHolder::Contacts::FieldType {
    DISHSW_CONTACTHOLDER_CONTACTS_EXPORT const std::set<Enum>& allEnums();
    DISHSW_CONTACTHOLDER_CONTACTS_EXPORT const std::set<QString>& allStrings();

    DISHSW_CONTACTHOLDER_CONTACTS_EXPORT const QString& toString(const Enum iEnum);

    /** \throws std::invalid_argument, if iStr is not in allStrings(). */
    DISHSW_CONTACTHOLDER_CONTACTS_EXPORT Enum toEnum(const QString& iStr);
} // namespace DishSW::ContactHolder::Contacts::FieldType
