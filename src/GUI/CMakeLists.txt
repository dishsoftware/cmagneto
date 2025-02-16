find_package(Qt6 REQUIRED COMPONENTS Widgets)


include_directories(
  ${PROJECT_SOURCE_DIR}/src/Contacts # Allows to include headers from Contacts using #include "Contacts/Header.hpp" instead of #include "../Contacts/Header.hpp"
)


# Sources
set(_gui_SOURCES
    main.cpp
)
####################################################################


# Target
add_executable(contacts_gui ${_gui_SOURCES})
target_link_libraries(contacts_gui Qt6::Core Qt6::Gui Qt6::Widgets contacts)
####################################################################


# Installation
install(TARGETS contacts_gui EXPORT ${PROJECT_NAME}TargetGroup DESTINATION bin)
####################################################################