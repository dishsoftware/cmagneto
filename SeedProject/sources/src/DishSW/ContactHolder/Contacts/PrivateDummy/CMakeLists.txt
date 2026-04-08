# The lib only exists to check it is impossible to include
# a private header from a public header as
# `#include "DishSW/ContactHolder/Contacts/PrivateDummy/PrivateHeader.hpp`.
# And possible, but with obvious violation, as
# `#include "src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateHeader.hpp` or
# `#include "../../../../src/DishSW/ContactHolder/Contacts/PrivateDummy/PrivateDummy.hpp"`.

set(_TARGET_NAME DishSW_ContactHolder_Contacts_PrivateDummy)
CMagneto__get_library_type(${_TARGET_NAME} _LIB_TYPE)
add_library(${_TARGET_NAME} ${_LIB_TYPE})

CMagneto__set_up__library(${_TARGET_NAME}
    GENERATED_HEADERS_VISIBILITY PRIVATE
    PRIVATE_HEADERS
        PrivateDummy.hpp
    SOURCES
        PrivateDummy.cpp
)
