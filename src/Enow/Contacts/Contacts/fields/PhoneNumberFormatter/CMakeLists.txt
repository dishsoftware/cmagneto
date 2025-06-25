find_package(Qt6 REQUIRED COMPONENTS Core)


# Headers
## Headers to be processed by MOC.
set(_moc_HEADERS

)

## Regular/static headers.
set(_regular_HEADERS
    PhoneNumberFormatter_DEFS.hpp
    Formatter.hpp
)

## All headers.
set(_headers ${_moc_HEADERS} ${_regular_HEADERS})
####################################################################


# Resources
## Resource files to be processed by RCC.
set(_rcc_RESOURCES
    #PhoneNumberFormatter.qrc
)

## Resource files to be processed by LRelease.
set(_ts_RESOURCES
    #resources/PhoneNumberFormatter_txt_en.ts
    #resources/PhoneNumberFormatter_txt_fr.ts
    #resources/PhoneNumberFormatter_txt_images.ts
)

## Regular/static resource files.
set(_other_RESOURCES
    #resources/icon.png
    #resources/action_assets.json
)
####################################################################


# Sources
## MOC wrappings.
qt_wrap_moc(_moc_SOURCES ${_moc_HEADERS})

## RCC wrappings.
qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})

## Regular/static sources.
set(_regular_SOURCES
    Formatter.cpp
)

## All sources.
set(_sources ${_regular_SOURCES} ${_moc_SOURCES} ${_rcc_SOURCES})
####################################################################


# Target
get_library_type(PhoneNumberFormatter _LIB_TYPE)
add_library(PhoneNumberFormatter ${_LIB_TYPE})
## If _LIB_TYPE is SHARED, a preproceccor macro PhoneNumberFormatter_EXPORTS or PHONENUMBERFORMATTER_EXPORTS is defined implicitly when the target is compiled.
## No need to target_compile_definitions(PhoneNumberFormatter PRIVATE PhoneNumberFormatter_EXPORTS) explicitly.

target_link_libraries(PhoneNumberFormatter PUBLIC Qt6::Core)
####################################################################


# Building and installation
set_up_library(PhoneNumberFormatter "${_headers}" "${_sources}" "${_ts_RESOURCES}" "${_other_RESOURCES}")
####################################################################