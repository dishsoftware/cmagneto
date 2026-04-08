find_package(Qt6 REQUIRED COMPONENTS Core)


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
    Formatter.hpp
)

set(_regular_INTERFACE_HEADERS

)

set(_regular_PRIVATE_HEADERS

)
####################################################################


# Resources
## Resources to embed into the lib's binary using Qt RCC.
set(_QtRCC_RESOURCE_FILES

)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES
    #resources/PhoneNumberFormatter_txt_en.ts
    #resources/PhoneNumberFormatter_txt_fr.ts
    #resources/PhoneNumberFormatter_txt_images.ts
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
    Formatter.cpp
)

## All sources.
set(_sources ${_QtMOC_SOURCES} ${_regular_SOURCES})
####################################################################


# Target
set(_TARGET_NAME DishSW_ContactHolder_Contacts_fields_PhoneNumberFormatter)
CMagneto__get_library_type(${_TARGET_NAME} _LIB_TYPE)
add_library(${_TARGET_NAME} ${_LIB_TYPE})
## If _LIB_TYPE is SHARED, a preproceccor macro DishSW_ContactHolder_Contacts_fields_PhoneNumberFormatter_EXPORTS or DISHSW_CONTACTHOLDER_CONTACTS_FIELDS_PHONENUMBERFORMATTER_EXPORTS is defined implicitly when the target is compiled.
## No need to target_compile_definitions(${_TARGET_NAME} PRIVATE DishSW_ContactHolder_Contacts_fields_PhoneNumberFormatter_EXPORTS) explicitly.

target_link_libraries(${_TARGET_NAME}
    PUBLIC
        Qt6::Core
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
    FILES
        ${_QtRCC_RESOURCE_FILES}
)
####################################################################
