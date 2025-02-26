find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Boost REQUIRED)


# Headers
## Headers to be processed by MOC.
set(_moc_HEADERS

)

## Other/static headers.
set(_other_HEADERS
  Contacts.hpp
  Contacts_Contact.hpp
  Contacts_FieldType.hpp
  Contacts_FieldTypeExtension.hpp
)

## All headers.
set(contacts_HEADERS ${_moc_HEADERS} ${_other_HEADERS})
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

## Other/static resource files.
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

## Other/static sources.
set(_other_SOURCES
  Contacts_Contact.cpp
  Contacts_FieldTypeExtension.cpp
)

## All sources.
set(contacts_SOURCES ${_other_SOURCES} ${_moc_SOURCES} ${_rcc_SOURCES})
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

target_sources(contacts PRIVATE ${contacts_SOURCES})

target_include_directories(contacts PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<INSTALL_INTERFACE:include/contacts>
)

target_include_directories(contacts PRIVATE
  ${Boost_INCLUDE_DIRS}
)

target_link_libraries(contacts PUBLIC Qt6::Core)
####################################################################


# Installation
install(
  TARGETS contacts
  EXPORT ${PROJECT_NAME}TargetGroup
  LIBRARY DESTINATION bin
  ARCHIVE DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include/contacts
  # If uncommented, a generated contactsConfig.cmake will have INTERFACE_INCLUDE_DIRECTORIES with duplicated "${_IMPORT_PREFIX}/include/contacts",
  # because the target_include_directories(contacts PUBLIC $<INSTALL_INTERFACE:include/contacts>) is already set.
)

install(FILES ${contacts_HEADERS} DESTINATION include/contacts)
qt_install_ts_resources("${_ts_RESOURCES}" resources/contacts/translations)
install(FILES ${_other_RESOURCES} DESTINATION resources/contacts/other)

# Generate contactsConfig.cmake
install(EXPORT ${PROJECT_NAME}TargetGroup
    FILE contactsConfig.cmake
    NAMESPACE contacts::
    DESTINATION lib/cmake/contacts
)
####################################################################
