// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Core/binaryTools/currentExecutableFilePath.hpp"

#include <stdexcept>
#include <string>

#if defined(_WIN32)
    #ifndef NOMINMAX
        #define NOMINMAX
    #endif
    #include <windows.h>
#elif defined(__APPLE__)
    #include <mach-o/dyld.h>
#else
    #include <unistd.h>
#endif


namespace CMagneto::Core::binaryTools {


    std::filesystem::path currentExecutableFilePath() {
#if defined(_WIN32)
        std::wstring pathBuffer(MAX_PATH, L'\0');

        while (true) {
            const DWORD copiedSize = ::GetModuleFileNameW(
                nullptr,
                pathBuffer.data(),
                static_cast<DWORD>(pathBuffer.size())
            );

            if (copiedSize == 0)
                throw std::runtime_error{"GetModuleFileNameW() failed."};

            if (copiedSize < pathBuffer.size()) {
                pathBuffer.resize(copiedSize);
                return std::filesystem::path{pathBuffer};
            }

            pathBuffer.resize(pathBuffer.size() * 2);
        }
#elif defined(__APPLE__)
        std::uint32_t pathSize = 0;
        _NSGetExecutablePath(nullptr, &pathSize);

        std::string pathBuffer(pathSize, '\0');
        if (_NSGetExecutablePath(pathBuffer.data(), &pathSize) != 0)
            throw std::runtime_error{"_NSGetExecutablePath() failed."};

        return std::filesystem::weakly_canonical(std::filesystem::path{pathBuffer.c_str()});
#else
        std::string pathBuffer(256, '\0');

        while (true) {
            const ssize_t copiedSize = ::readlink(
                "/proc/self/exe",
                pathBuffer.data(),
                pathBuffer.size()
            );

            if (copiedSize < 0)
                throw std::runtime_error{"readlink(\"/proc/self/exe\") failed."};

            if (static_cast<std::size_t>(copiedSize) < pathBuffer.size()) {
                pathBuffer.resize(static_cast<std::size_t>(copiedSize));
                return std::filesystem::path{pathBuffer};
            }

            pathBuffer.resize(pathBuffer.size() * 2);
        }
#endif
    }


} // namespace CMagneto::Core::binaryTools
