enable_testing()

include(FetchContent)

# Prevent GTest from being installed.
set(INSTALL_GTEST OFF)

FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/52eb8108c5bdec04579160ae17225d66034bd723.zip # v1.17.0
)
# For Windows: Prevent overriding project's compiler/linker settings.
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(googletest)
include(GoogleTest)

add_subdirectory(Contacts)