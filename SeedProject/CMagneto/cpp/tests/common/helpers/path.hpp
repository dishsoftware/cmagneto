// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#pragma once

#include <chrono>
#include <filesystem>
#include <functional>
#ifdef _WIN32
    #include <process.h>
#else
    #include <unistd.h>
#endif
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>


namespace CMagneto::tests::common::helpers::path {


    [[nodiscard]] inline unsigned long currentProcessID() noexcept {
        #ifdef _WIN32
            return static_cast<unsigned long>(_getpid());
        #else
            return static_cast<unsigned long>(getpid());
        #endif
    }


    /** Creates a unique temporary directory for test artifacts and returns its path. */
    [[nodiscard]] inline std::filesystem::path createUniqueTempDirectory(
        const std::string_view iDirectoryNamePrefix = "CMagneto_Test"
    ) {
        const std::filesystem::path tempDirectoryPath = std::filesystem::temp_directory_path();
        const auto processPart = currentProcessID();
        const auto threadPart = std::hash<std::thread::id>{}(std::this_thread::get_id());

        for (std::size_t attemptIndex = 0; attemptIndex < 128; ++attemptIndex) {
            const auto nowTicks = std::chrono::steady_clock::now().time_since_epoch().count();
            const std::string directoryName =
                std::string{iDirectoryNamePrefix}
                .append("_")
                .append(std::to_string(nowTicks))
                .append("_")
                .append(std::to_string(processPart))
                .append("_")
                .append(std::to_string(threadPart))
                .append("_")
                .append(std::to_string(attemptIndex))
            ;
            const std::filesystem::path candidateDirectoryPath = tempDirectoryPath / directoryName;

            std::error_code errorCode;
            if (std::filesystem::create_directory(candidateDirectoryPath, errorCode))
                return candidateDirectoryPath;

            if (errorCode)
                throw std::runtime_error(
                    std::string{"CMagneto::tests::common::helpers::path::createUniqueTempDirectory: "}
                    .append(errorCode.message())
                );
        }

        throw std::runtime_error(
            "CMagneto::tests::common::helpers::path::createUniqueTempDirectory: failed to allocate unique temporary directory."
        );
    }


} // namespace CMagneto::tests::common::helpers::path
