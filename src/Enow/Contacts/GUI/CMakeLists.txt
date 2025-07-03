find_package(Qt6 REQUIRED COMPONENTS Widgets)


# Headers (PRIVATE)
## Headers to be processed by QtMOC.
set(_QtMOC_HEADERS

)

## Regular headers.
set(_regular_HEADERS

)
####################################################################


# Resources
## Resource files to be processed by Qt RCC.
set(_QtRCC_RESOURCES
    resources/target.qrc
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

## QtRCC wrappings.
qt_add_resources(_QtRCC_SOURCES ${_QtRCC_RESOURCES})

## Regular sources.
set(_regular_SOURCES
    main.cpp
)

## All sources.
set(_sources ${_QtMOC_SOURCES} ${_QtRCC_SOURCES} ${_regular_SOURCES})
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

set_project_entrypoint(GUI)
####################################################################