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

// #include                                                "PrivateDummy.hpp" // Build must fail.
// #include     "DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy.hpp" // Build must fail.
// #include "src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy.hpp" // Build passes, but violation is obvious.
// #include "../../../../src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy.hpp" // Build passes, but violation is obvious. And ".." is against code conventions.



namespace DishSW::ContactHolder::Contacts {
    class DISHSW_CONTACTHOLDER_CONTACTS_EXPORT Contact {
    private:
        // std::list<std::shared_ptr<fields::PhoneNumber>> mPhoneNumbers;

    public:
        Contact() noexcept = default;
        Contact(const Contact&) noexcept = default;
        Contact(Contact&&) noexcept = default;
        Contact& operator=(const Contact&) noexcept = default;
        Contact& operator=(Contact&&) noexcept = default;
    };
} // namespace DishSW::ContactHolder::Contacts
