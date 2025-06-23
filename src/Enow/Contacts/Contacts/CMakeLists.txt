find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Boost REQUIRED)


# Headers
## Headers to be processed by MOC.
set(_moc_HEADERS

)

## Regular/static headers.
set(_regular_HEADERS
  Contacts.hpp
  Contact.hpp
  FieldType.hpp
  FieldTypeExtension.hpp
)

## All headers.
set(Contacts_HEADERS ${_moc_HEADERS} ${_regular_HEADERS})
####################################################################


# Resources
## Resource files to be processed by RCC.
set(_rcc_RESOURCES
    #Contacts.qrc
)

## Resource files to be processed by LRelease.
set(_ts_RESOURCES
  #resources/Contacts_txt_en.ts
  #resources/Contacts_txt_fr.ts
  #resources/Contacts_txt_images.ts
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
  Contact.cpp
  FieldTypeExtension.cpp
)

## All sources.
set(Contacts_SOURCES ${_regular_SOURCES} ${_moc_SOURCES} ${_rcc_SOURCES})
####################################################################


# Target
get_library_type(Contacts _LIB_TYPE)
add_library(Contacts ${_LIB_TYPE})
# If _LIB_TYPE is SHARED, a preproceccor macro Contacts_EXPORTS or CONTACTS_EXPORTS is defined implicitly when the target is compiled.
# No need to target_compile_definitions(Contacts PRIVATE Contacts_EXPORTS) explicitly.

target_include_directories(Contacts PRIVATE
  ${Boost_INCLUDE_DIRS}
)

target_link_libraries(Contacts PUBLIC Qt6::Core)
####################################################################


# Building and installation
set_up_library(Contacts "${Contacts_HEADERS}" "${Contacts_SOURCES}" "${_ts_RESOURCES}" "${_other_RESOURCES}")
####################################################################