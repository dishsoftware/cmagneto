#pragma once

#include "Contacts_EXPORT.hpp"

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISHSW_CONTACTHOLDER_CONTACTS_VERIFY(x) assert(x);
    #define DISHSW_CONTACTHOLDER_CONTACTS_ASSERT(x) assert(x);
#else
    #define DISHSW_CONTACTHOLDER_CONTACTS_VERIFY(x) x
    #define DISHSW_CONTACTHOLDER_CONTACTS_ASSERT(x)
#endif
