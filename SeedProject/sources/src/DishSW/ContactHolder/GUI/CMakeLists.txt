find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets LinguistTools)
find_package(ZLIB CONFIG QUIET)
if(NOT ZLIB_FOUND)
    find_package(ZLIB MODULE REQUIRED)
endif()


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
    "QtRC/icons/logo.svg"
)

## Resource files to be processed by Qt LRelease.
set(_QtTS_RESOURCES
    "QtTS/main_en.ts"
    "QtTS/main_ru.ts"
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
set(_TARGET_NAME DishSW_ContactHolder_GUI)
add_executable(${_TARGET_NAME})
target_link_libraries(${_TARGET_NAME}
    PRIVATE
        CLI11::CLI11
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        ZLIB::ZLIB
        DishSW::ContactHolder::Contacts
)
####################################################################


# Building and installation
CMagneto__set_up__executable(${_TARGET_NAME}
    HEADERS
        ${_QtMOC_HEADERS} ${_regular_HEADERS}
    SOURCES
        ${_sources}
    QT_TS_RESOURCES
        ${_QtTS_RESOURCES}
    OTHER_RESOURCES
        ${_other_RESOURCES}
)

CMagneto__bind_icon_to_executable(${_TARGET_NAME}
    WINDOWS_ICON "AppIcon/ContactHolder.ico"
    LINUX_ICON "AppIcon/ContactHolder.png"
    MACOS_ICON "AppIcon/ContactHolder.icns"
)

CMagneto__place_icon_near_executable(${_TARGET_NAME})

CMagneto__add_executable_to_application_menu(${_TARGET_NAME}
    NAME "Contact Holder"
    # LAUNCH_IN_TERMINAL
)

CMagneto__embed_QtRC_resources(${_TARGET_NAME} QtRC
    FILES
        ${_QtRCC_RESOURCE_FILES}
)

CMagneto__set_project_entrypoint(${_TARGET_NAME})
####################################################################
