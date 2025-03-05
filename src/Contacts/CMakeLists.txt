find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Boost REQUIRED)


# Headers
## Headers to be processed by MOC.
set(_moc_HEADERS

)

## Regular/static headers.
set(_regular_HEADERS
  Contacts.hpp
  Contacts_Contact.hpp
  Contacts_FieldType.hpp
  Contacts_FieldTypeExtension.hpp
)

## All headers.
set(contacts_HEADERS ${_moc_HEADERS} ${_regular_HEADERS})
####################################################################


# Resources
## Resource files to be processed by RCC.
set(_rcc_RESOURCES
    #contacts.qrc
)

## Resource files to be processed by LRelease.
set(_ts_RESOURCES
  #resources/contacts_txt_en.ts
  #resources/contacts_txt_fr.ts
  #resources/contacts_txt_images.ts
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

# RCC wrappings.
qt_add_resources(_rcc_SOURCES ${_rcc_RESOURCES})

## Regular/static sources.
set(_regular_SOURCES
  Contacts_Contact.cpp
  Contacts_FieldTypeExtension.cpp
)

## All sources.
set(contacts_SOURCES ${_regular_SOURCES} ${_moc_SOURCES} ${_rcc_SOURCES})
####################################################################


# Target
if(LIB_CONTACTS_SHARED)
    set(_LIB_TYPE SHARED)
else()
    set(_LIB_TYPE STATIC)
endif()

add_library(contacts ${_LIB_TYPE})
# If _LIB_TYPE is SHARED, a preproceccor macro contacts_EXPORTS or CONTACTS_EXPORTS is defined implicitly when the target is compiled.
# No need to target_compile_definitions(contacts PRIVATE contacts_EXPORTS) explicitly.

target_include_directories(contacts PRIVATE
  ${Boost_INCLUDE_DIRS}
)

target_link_libraries(contacts PUBLIC Qt6::Core)
####################################################################


# Building and installation
set_up_library(contacts "${contacts_HEADERS}" "${contacts_SOURCES}" "${_ts_RESOURCES}" "${_other_RESOURCES}")
####################################################################