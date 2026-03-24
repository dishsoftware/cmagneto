#pragma once

#include "Contacts_EXPORT.hpp"

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISH_CONTACTHOLDER_CONTACTS_VERIFY(x) assert(x);
    #define DISH_CONTACTHOLDER_CONTACTS_ASSERT(x) assert(x);
#else
    #define DISH_CONTACTHOLDER_CONTACTS_VERIFY(x) x
    #define DISH_CONTACTHOLDER_CONTACTS_ASSERT(x)
#endif
