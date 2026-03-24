#pragma once

#include "Contacts_DEFS.hpp"

#include "FieldType.hpp"

#include <QJsonObject>

#include <memory>


namespace Dish::ContactHolder::Contacts {
    class DISH_CONTACTHOLDER_CONTACTS_EXPORT Field {
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
} // namespace Dish::ContactHolder::Contacts
