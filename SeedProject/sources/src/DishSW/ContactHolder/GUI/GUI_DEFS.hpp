#pragma once

#include "DishSW/ContactHolder/ContactHolder_DEFS.hpp"

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISHSW_CONTACTHOLDER_GUI_VERIFY(x) assert(x);
    #define DISHSW_CONTACTHOLDER_GUI_ASSERT(x) assert(x);
#else
    #define DISHSW_CONTACTHOLDER_GUI_VERIFY(x) x
    #define DISHSW_CONTACTHOLDER_GUI_ASSERT(x)
#endif
