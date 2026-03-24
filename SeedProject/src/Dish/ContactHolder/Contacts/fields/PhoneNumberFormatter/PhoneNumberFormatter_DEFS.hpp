#pragma once

#ifndef COMPILE_TIME_MESSAGE
    #if defined(_MSC_VER)
        #define COMPILE_TIME_MESSAGE(msg) __pragma(message("[COMPILE MESSAGE] " msg))
    #else
        #define COMPILE_TIME_MESSAGE(msg) /* Unsupported compiler */
    #endif
#endif


#if defined(LIB_DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_SHARED) || defined(LIB_PHONENUMBERFORMATTER_SHARED)
    #if defined(DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORTS) || defined(Dish_ContactHolder_Contacts_fields_PhoneNumberFormatter_EXPORTS) || defined(PHONENUMBERFORMATTER_EXPORTS) || defined(PhoneNumberFormatter_EXPORTS)
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT __attribute__((visibility("default")))
                #pragma message ("MinGW Export")
            #elif defined(_MSC_VER)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT __declspec(dllexport)
                COMPILE_TIME_MESSAGE("MSVC Export")
            #else
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("Windows Compiler (unknown) Export")
            #endif
        #else // Not Windows.
            #if defined(__GNUC__)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT __attribute__((visibility("default")))
                #pragma message ("GCC Export")
            #else
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("Other OS Non-GCC Export")
            #endif
        #endif
    #else // Import case.
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("MinGW Import")
            #elif defined(_MSC_VER)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT __declspec(dllimport)
                COMPILE_TIME_MESSAGE("MSVC Import")
            #else
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("Windows Compiler (unknown) Export")
        #endif
        #else // Not Windows.
            COMPILE_TIME_MESSAGE("NOT WIN")
            #if defined(__GNUC__)
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("GCC Import")
            #else
                #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
                #pragma message ("Other OS Non-GCC Import")
            #endif
        #endif
    #endif
#else // LIB_PHONENUMBERFORMATTER is static.
    #define DISH_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORT
#endif


#if defined(_MSC_VER)
    #pragma warning (disable: 4251)
#endif


#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define PHONENUMBERFORMATTER_VERIFY(x) assert(x);
    #define PHONENUMBERFORMATTER_ASSERT(x) assert(x);
#else
    #define PHONENUMBERFORMATTER_VERIFY(x) x
    #define PHONENUMBERFORMATTER_ASSERT(x)
#endif
