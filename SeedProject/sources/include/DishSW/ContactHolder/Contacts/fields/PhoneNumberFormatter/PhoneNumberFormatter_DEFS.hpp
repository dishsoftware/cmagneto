#pragma once

#include "DishSW/ContactHolder/ContactHolder_DEFS.hpp"
#include "DishSW/ContactHolder/Contacts/fields/PhoneNumberFormatter/PhoneNumberFormatter_EXPORT.hpp"

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_VERIFY(x) assert(x);
    #define DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_ASSERT(x) assert(x);
#else
    #define DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_VERIFY(x) x
    #define DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_ASSERT(x)
#endif
