// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#pragma once

#include "Contacts_DEFS.hpp"

#include "fields/PhoneNumber.hpp"

#include <list>


namespace Dish::ContactHolder::Contacts {
    class DISH_CONTACTHOLDER_CONTACTS_EXPORT Contact {
    private:
        // std::list<std::shared_ptr<fields::PhoneNumber>> mPhoneNumbers;

    public:
        Contact() noexcept = default;
        Contact(const Contact&) noexcept = default;
        Contact(Contact&&) noexcept = default;
        Contact& operator=(const Contact&) noexcept = default;
        Contact& operator=(Contact&&) noexcept = default;
    };
} // namespace Dish::ContactHolder::Contacts
