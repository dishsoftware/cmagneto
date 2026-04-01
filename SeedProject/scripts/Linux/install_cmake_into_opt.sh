#!/usr/bin/env bash
set -e

# ===== Check input =====
if [ -z "$1" ]; then
    echo "Usage: $0 <cmake-version>"
    echo "Example: $0 4.2.3"
    exit 1
fi

CMAKE_VERSION="$1"

# ===== Config =====
INSTALL_DIR="/opt/cmake-${CMAKE_VERSION}"
TMP_DIR="/tmp"
ARCHIVE_NAME="cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
DOWNLOAD_URL="https://cmake.org/files/v${CMAKE_VERSION%.*}/${ARCHIVE_NAME}"

# ===== Install =====
echo "Installing CMake ${CMAKE_VERSION}..."

sudo mkdir -p "${INSTALL_DIR}"

cd "${TMP_DIR}"

echo "Downloading from ${DOWNLOAD_URL}..."
wget -q "${DOWNLOAD_URL}"

echo "Extracting..."
tar -xzf "${ARCHIVE_NAME}"

echo "Copying files to ${INSTALL_DIR}..."
sudo cp -a "cmake-${CMAKE_VERSION}-linux-x86_64/." "${INSTALL_DIR}/"

echo "Done!"
echo "CMake ${CMAKE_VERSION} installed in ${INSTALL_DIR}"
