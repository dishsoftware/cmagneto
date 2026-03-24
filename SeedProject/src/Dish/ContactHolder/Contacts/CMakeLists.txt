add_subdirectory(fields/PhoneNumberFormatter)


find_package(Qt6 REQUIRED COMPONENTS Core Gui)
find_package(Boost REQUIRED)


# Headers
## Headers to be processed by QtMOC.
### Public QtMOC headers.
set(_QtMOC_PUBLIC_HEADERS

)

### Interface QtMOC headers.
### _QtMOC_INTERFACE_HEADERS must not be `#include`d in any file of this target.
### _QtMOC_INTERFACE_HEADERS should be empty. If not, consumers of this target must enable AUTOMOC or run QtMOC for _QtMOC_INTERFACE_HEADERS manually.
set(_QtMOC_INTERFACE_HEADERS)

### Private QtMOC headers.
set(_QtMOC_PRIVATE_HEADERS

)

### All headers to be processed by QtMOC during compilation of this target. _QtMOC_INTERFACE_HEADERS are not included intentionally.
set(_QtMOC_HEADERS
    ${_QtMOC_PUBLIC_HEADERS} ${_QtMOC_PRIVATE_HEADERS}
)


## Regular headers.
set(_regular_PUBLIC_HEADERS
    Contact.hpp
    Field.hpp
    FieldType.hpp
    FieldTypeExtension.hpp
    fields/EmailAddress.hpp
    fields/PhoneNumber.hpp
    # Invalid paths to test.
    #..\\../../in_src_with_no_subdir.hpp
    # ../../../in_src_with_no_subdir.hpp
    # C:/Data/Work/Dish/Note.hpp
)

set(_regular_INTERFACE_HEADERS

)

set(_regular_PRIVATE_HEADERS

)
####################################################################


# Resources
## Resources to embed into the lib's binary using Qt RCC.
set(_QtRCC_RESOURCE_FILES
    "@resources/QtRC/icons/logo.svg"
)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES
    "@resources/QtTS/fields/PhoneNumber_en.ts"
    "@resources/QtTS/fields/PhoneNumber_ru.ts"
)

## Regular resource files.
set(_other_RESOURCES
    #resources/icon.png
    #resources/action_assets.json
)
####################################################################


# Sources
## QtMOC wrappings.
QtWrappers__qt_wrap_cpp(_QtMOC_SOURCES ${_QtMOC_HEADERS})

## Regular sources.
set(_regular_SOURCES
    Contact.cpp
    Field.cpp
    FieldTypeExtension.cpp
    fields/EmailAddress.cpp
    fields/PhoneNumber.cpp
)

## All sources.
set(_sources ${_QtMOC_SOURCES} ${_regular_SOURCES})
####################################################################


# Target
set(_TARGET_NAME Dish_ContactHolder_Contacts)
CMagneto__get_library_type(${_TARGET_NAME} _LIB_TYPE)
add_library(${_TARGET_NAME} ${_LIB_TYPE})
## If _LIB_TYPE is SHARED, a preproceccor macro Dish_ContactHolder_Contacts_EXPORTS or DISH_CONTACTHOLDER_CONTACTS_EXPORTS is defined implicitly when the target is compiled.
## No need to target_compile_definitions(${_TARGET_NAME} PRIVATE Dish_ContactHolder_Contacts_EXPORTS) explicitly.

target_link_libraries(${_TARGET_NAME}
    PUBLIC
        Qt6::Core Qt6::Gui Boost::boost
    PRIVATE
        Dish::ContactHolder::Contacts::fields::PhoneNumberFormatter
)
####################################################################


# Building and installation
CMagneto__set_up__library(${_TARGET_NAME}
    PUBLIC_HEADERS
        ${_QtMOC_PUBLIC_HEADERS} ${_regular_PUBLIC_HEADERS}
    INTERFACE_HEADERS
        ${_QtMOC_INTERFACE_HEADERS} ${_regular_INTERFACE_HEADERS}
    PRIVATE_HEADERS
        ${_QtMOC_PRIVATE_HEADERS} ${_regular_PRIVATE_HEADERS}
    SOURCES
        ${_sources}
    QT_TS_RESOURCES
        ${_QtTS_RESOURCES}
    OTHER_RESOURCES
        ${_other_RESOURCES}
)

CMagneto__embed_QtRC_resources(${_TARGET_NAME} QtRC
    PREFIX "/Dish/ContactHolder/Contacts/"
    BASE "@resources/QtRC"
    FILES
        ${_QtRCC_RESOURCE_FILES}
)
####################################################################
