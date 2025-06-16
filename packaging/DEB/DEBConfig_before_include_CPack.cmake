include_guard(GLOBAL)  # Ensures this file is included only once.

# Automatically compute shared lib dependencies. dpkg-shlibdeps is required (part of dpkg-dev).
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)