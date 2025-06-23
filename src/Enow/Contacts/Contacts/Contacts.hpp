#pragma once

#ifndef COMPILE_TIME_MESSAGE
    #if defined(_MSC_VER)
        #define COMPILE_TIME_MESSAGE(msg) __pragma(message("[COMPILE MESSAGE] " msg))
    #else
        #define COMPILE_TIME_MESSAGE(msg) /* Unsupported compiler */
    #endif
#endif


#if defined(LIB_CONTACTS_SHARED)
    #if defined(CONTACTS_EXPORTS) || defined(Contacts_EXPORTS)
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define CONTACTS_EXPORT __attribute__((visibility("default")))
                #pragma message ("MinGW Export")
            #elif defined(_MSC_VER)
                #define CONTACTS_EXPORT __declspec(dllexport)
                COMPILE_TIME_MESSAGE("MSVC Export")
            #else
                #define CONTACTS_EXPORT
                #pragma message ("Windows Compiler (unknown) Export")
            #endif
        #else // Not Windows.
            #if defined(__GNUC__)
                #define CONTACTS_EXPORT __attribute__((visibility("default")))
                #pragma message ("GCC Export")
            #else
                #define CONTACTS_EXPORT
                #pragma message ("Other OS Non-GCC Export")
            #endif
        #endif
    #else // Import case.
        #if defined(_WIN32)
            #if defined(__GNUC__)
                #define CONTACTS_EXPORT
                #pragma message ("MinGW Import")
            #elif defined(_MSC_VER)
                #define CONTACTS_EXPORT __declspec(dllimport)
                COMPILE_TIME_MESSAGE("MSVC Import")
            #else
                #define CONTACTS_EXPORT
                #pragma message ("Windows Compiler (unknown) Export")
        #endif
        #else // Not Windows.
            COMPILE_TIME_MESSAGE("NOT WIN")
            #if defined(__GNUC__)
                #define CONTACTS_EXPORT
                #pragma message ("GCC Import")
            #else
                #define CONTACTS_EXPORT
                #pragma message ("Other OS Non-GCC Import")
            #endif
        #endif
    #endif
#else // LIB_CONTACTS is static.
    #define CONTACTS_EXPORT
#endif


#if defined(_MSC_VER)
    #pragma warning (disable: 4251)
#endif


#if defined(_DEBUG) || defined(DEBUG)
    #include <assert.h>
    #define CONTACTS_VERIFY(x) assert(x);
    #define CONTACTS_ASSERT(x) assert(x);
#else
    #define CONTACTS_VERIFY(x) x
    #define CONTACTS_ASSERT(x)
#endif