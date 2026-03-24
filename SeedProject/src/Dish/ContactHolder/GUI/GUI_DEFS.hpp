#pragma once

#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define DISH_CONTACTHOLDER_GUI_VERIFY(x) assert(x);
    #define DISH_CONTACTHOLDER_GUI_ASSERT(x) assert(x);
#else
    #define DISH_CONTACTHOLDER_GUI_VERIFY(x) x
    #define DISH_CONTACTHOLDER_GUI_ASSERT(x)
#endif
