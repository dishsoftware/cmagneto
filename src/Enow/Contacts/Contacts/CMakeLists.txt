set(CMagneto__MESSAGE_LOG_LEVEL TRACE)

add_subdirectory(fields/PhoneNumberFormatter)


find_package(Qt6 REQUIRED COMPONENTS Core)
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
    Contacts_DEFS.hpp
    Contact.hpp
    Field.hpp
    FieldType.hpp
    FieldTypeExtension.hpp
    fields/EmailAddress.hpp
    fields/PhoneNumber.hpp
)

set(_regular_INTERFACE_HEADERS

)

set(_regular_PRIVATE_HEADERS
    # ../../../in_src_with_no_subdir.hpp
    # C:/Data/Work/Enow/Note.hpp
)
####################################################################


# Resources
## Resource files to be processed by Qt RCC.
set(_QtRCC_RESOURCES
    resources/target.qrc
)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES
    #resources/Contacts_txt_en.ts
    #resources/Contacts_txt_fr.ts
    #resources/Contacts_txt_images.ts
)

## Regular resource files.
set(_other_RESOURCES
    #resources/icon.png
    #resources/action_assets.json
)
####################################################################


# Sources
## QtMOC wrappings.
qt_wrap_moc(_QtMOC_SOURCES ${_QtMOC_HEADERS})

## QtRCC wrappings.
qt_add_resources(_QtRCC_SOURCES ${_QtRCC_RESOURCES})

## Regular sources.
set(_regular_SOURCES
    Contact.cpp
    Field.cpp
    FieldTypeExtension.cpp
    fields/EmailAddress.cpp
    fields/PhoneNumber.cpp
)

## All sources.
set(_sources ${_QtMOC_SOURCES} ${_QtRCC_SOURCES} ${_regular_SOURCES})
####################################################################


# Target
get_library_type(Contacts _LIB_TYPE)
add_library(Contacts ${_LIB_TYPE})
## If _LIB_TYPE is SHARED, a preproceccor macro Contacts_EXPORTS or CONTACTS_EXPORTS is defined implicitly when the target is compiled.
## No need to target_compile_definitions(Contacts PRIVATE Contacts_EXPORTS) explicitly.

target_link_libraries(Contacts
    PUBLIC
        Qt6::Core Boost::boost
    PRIVATE
        PhoneNumberFormatter
)
####################################################################


# Building and installation
set_up_library(Contacts
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
####################################################################