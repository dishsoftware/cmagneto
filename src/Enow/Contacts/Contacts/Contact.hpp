#pragma once

#include "Contacts_DEFS.hpp"

#include "fields/PhoneNumber.hpp"

#include <list>


namespace Enow::Contacts::Contacts {
    class CONTACTS_EXPORT Contact {
    private:
        // std::list<std::shared_ptr<fields::PhoneNumber>> mPhoneNumbers;

    public:
        Contact() noexcept = default;
        Contact(const Contact&) noexcept = default;
        Contact(Contact&&) noexcept = default;
        Contact& operator=(const Contact&) noexcept = default;
        Contact& operator=(Contact&&) noexcept = default;
    };
} // namespace Enow::Contacts::Contacts