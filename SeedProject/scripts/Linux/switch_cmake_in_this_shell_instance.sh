# CMake version switching helpers.
# Usage:
#   use_cmake_system
#   use_cmake 4.2.3
#
# After editing ~/.bashrc, apply changes in the current shell with:
#   source ~/.bashrc
#
# These functions switch PATH so `cmake`, `ctest`, and `cpack`
# resolve either to the distro-provided tools in /usr/bin
# or to a manually installed CMake under /opt/cmake-<version>/bin.

use_cmake_system() {
  PATH=$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '
    $0 != "/usr/bin" &&
    $0 != "/usr/local/bin" &&
    $0 !~ /^\/opt\/cmake-[^/]+\/bin$/ { print }
  ')
  PATH=${PATH%:}
  export PATH="/usr/bin:/usr/local/bin${PATH:+:$PATH}"
  hash -r
}

use_cmake() {
  local version="$1"
  local cmake_bin="/opt/cmake-$version/bin"

  if [ ! -x "$cmake_bin/cmake" ]; then
    echo "CMake not found: $cmake_bin/cmake" >&2
    return 1
  fi

  PATH=$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '
    $0 != "/usr/bin" &&
    $0 != "/usr/local/bin" &&
    $0 !~ /^\/opt\/cmake-[^/]+\/bin$/ { print }
  ')
  PATH=${PATH%:}
  export PATH="$cmake_bin:/usr/bin:/usr/local/bin${PATH:+:$PATH}"
  hash -r
}

# Optional helper to verify which CMake toolchain is active.
cmake_which() {
  which cmake
  which ctest
  which cpack
  cmake --version
}

cmake_list_versions() {
  local dir
  local found=0

  for dir in /opt/cmake-*; do
    [ -d "$dir" ] || continue

    local version="${dir#/opt/cmake-}"

    if [ -x "$dir/bin/cmake" ]; then
      echo "$version"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "No custom CMake versions found in /opt"
  fi
}
