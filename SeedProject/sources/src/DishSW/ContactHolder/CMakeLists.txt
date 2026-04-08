if(NOT TARGET CLI11::CLI11)
    add_subdirectory(
        "${CMAKE_SOURCE_DIR}/3rdParty/sources/CLI11"
        "${CMAKE_BINARY_DIR}/3rdParty/build/CLI11"  # binary/build directory CMake should use for that subproject.
        EXCLUDE_FROM_ALL
    )
    # EXCLUDE_FROM_ALL - targets created inside that subdirectory are not automatically added
    # to the default `all` build target just because the subdirectory exists.
    # Practical effect:
    #   CLI11 `examples/tests/docs/fuzz` targets are less likely to get built accidentally;
    #   If a target of this project links to `CLI11::CLI11`, the `CLI11::CLI11` target is still available;
    #   Since CLI11 is header-only by default, there is not much to build for the main library target anyway.
endif()

add_subdirectory(Contacts)
add_subdirectory(GUI)