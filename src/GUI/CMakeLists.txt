find_package(Qt6 REQUIRED COMPONENTS Widgets)


include_directories(
  ${PROJECT_SOURCE_DIR}/src/Contacts # Allows to include headers from Contacts using #include "Contacts/Header.hpp" instead of #include "../Contacts/Header.hpp"
)


# Sources
set(_regular_SOURCES
    main.cpp
)
####################################################################


# Target
add_executable(gui)
target_link_libraries(gui PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets contacts)
####################################################################


# Installation
install_executable(gui "${_regular_HEADERS}" "${_regular_SOURCES}" "${_ts_RESOURCES}" "${_other_RESOURCES}")
set_project_entrypoint(gui)
####################################################################