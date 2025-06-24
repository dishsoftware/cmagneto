#pragma once

#include "../Contacts.hpp"
#include <iostream>


namespace Enow::Contacts::Contacts::dataTypes {
    class CONTACTS_EXPORT Email {
    public:
        // Constructor
        Email() {
            std::cout << "Enow::Contacts::Contacts::dataTypes::Email object created." << std::endl;
        };

        // Destructor
        ~Email() = default;

        // Copy constructor
        Email(const Email&) = default;

        // Move constructor
        Email(Email&&) noexcept = default;

        // Copy assignment operator
        Email& operator=(const Email&) = default;

        // Move assignment operator
        Email& operator=(Email&&) noexcept = default;

        // Additional member functions can be added here
    };
} // namespace Enow::Contacts::Contacts::dataTypes