// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "DishSW/ContactHolder/Contacts/Contact.hpp"
#include "src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy.hpp"


namespace DishSW::ContactHolder::Contacts {
    namespace {
        [[maybe_unused]] const int kPrivateDummyValue = PrivateDummy::touch();
    } // namespace

} // namespace DishSW::ContactHolder::Contacts
