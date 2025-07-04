find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)


# Headers (PRIVATE)
## Headers to be processed by QtMOC.
set(_QtMOC_HEADERS

)

## Regular headers.
set(_regular_HEADERS

)
####################################################################


# Resources
## Resources to embed into the executable's binary.
set(_QtRCC_RESOURCE_FILES
    "resources/QRC/icons/logo.svg"
)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES

)

## Regular resource files.
set(_other_RESOURCES
    #resources/action_assets.json
)
####################################################################


# Sources
## QtMOC wrappings.
qt_wrap_moc(_QtMOC_SOURCES ${_QtMOC_HEADERS})

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
set_up_executable(GUI
    HEADERS
        ${_QtMOC_HEADERS} ${_regular_HEADERS}
    SOURCES
        ${_sources}
    QT_TS_RESOURCES
        ${_QtTS_RESOURCES}
    OTHER_RESOURCES
        ${_other_RESOURCES}
)

CMagneto__qt_add_resources(GUI QRC
   PREFIX "/Enow/Contacts/GUI/"
   BASE "resources/QRC"
   FILES
       ${_QtRCC_RESOURCE_FILES}
)

set_project_entrypoint(GUI)
####################################################################