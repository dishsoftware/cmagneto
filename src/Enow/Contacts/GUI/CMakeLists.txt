find_package(Qt6 REQUIRED COMPONENTS Widgets)


# Sources
set(_regular_SOURCES
    main.cpp
)
####################################################################


# Target
add_executable(gui)
target_link_libraries(gui PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets Contacts)
####################################################################


# Building and installation
set_up_executable(gui "${_regular_HEADERS}" "${_regular_SOURCES}" "${_ts_RESOURCES}" "${_other_RESOURCES}")
set_project_entrypoint(gui)
####################################################################