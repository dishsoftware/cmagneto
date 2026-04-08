#pragma once

#include "DishSW/ContactHolder/ContactHolder_DEFS.hpp"
#include "src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy_EXPORT.hpp"

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISHSW_CONTACTHOLDER_CONTACTS_PRIVATEDUMMY_VERIFY(x) assert(x);
    #define DISHSW_CONTACTHOLDER_CONTACTS_PRIVATEDUMMY_ASSERT(x) assert(x);
#else
    #define DISHSW_CONTACTHOLDER_CONTACTS_PRIVATEDUMMY_VERIFY(x) x
    #define DISHSW_CONTACTHOLDER_CONTACTS_PRIVATEDUMMY_ASSERT(x)
#endif
