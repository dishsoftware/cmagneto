find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets LinguistTools)


# Headers (PRIVATE)
## Headers to be processed by QtMOC.
set(_QtMOC_HEADERS

)

## Regular headers.
set(_regular_HEADERS

)
####################################################################


# Resources
## Resources to embed into the executable's binary using Qt RCC.
set(_QtRCC_RESOURCE_FILES
    "@resources/QtRC/icons/logo.svg"
)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES
    "@resources/QtTS/main_en.ts"
    "@resources/QtTS/main_ru.ts"
)

## Regular resource files.
set(_other_RESOURCES
    #resources/action_assets.json
)
####################################################################


# Sources
## QtMOC wrappings.
QtWrappers__qt_wrap_cpp(_QtMOC_SOURCES ${_QtMOC_HEADERS})

## Regular sources.
set(_regular_SOURCES
    main.cpp
)

## All sources.
set(_sources ${_QtMOC_SOURCES} ${_regular_SOURCES})
####################################################################


# Target
add_executable(GUI)
target_link_libraries(GUI PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets Contacts)
####################################################################


# Building and installation
CMagneto__set_up__executable(GUI
    HEADERS
        ${_QtMOC_HEADERS} ${_regular_HEADERS}
    SOURCES
        ${_sources}
    QT_TS_RESOURCES
        ${_QtTS_RESOURCES}
    OTHER_RESOURCES
        ${_other_RESOURCES}
)

CMagneto__embed_QtRC_resources(GUI QtRC
    PREFIX "/Enow/Contacts/GUI/"
    BASE "@resources/QtRC"
    FILES
        ${_QtRCC_RESOURCE_FILES}
)

CMagneto__set_project_entrypoint(GUI)
####################################################################