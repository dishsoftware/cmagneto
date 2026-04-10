// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#pragma once

#include "CMagneto/Core/Logger.hpp"

#include <filesystem>
#include <fstream>
#include <string>
#include <string_view>


namespace CMagneto::Core::logger::sinks {


    /** Basic logger sink which appends records to a file. */
    class File : public CMagneto::Core::Logger::Sink {
    public:
        explicit File(
            std::filesystem::path iFilePath,
            bool iColored = false,
            std::string iAppIdentityString = {}
        );

        ~File() override = default;
        File(const File& iOther) = delete;
        File(File&& iOther) noexcept = default;
        File& operator=(const File& iOther) = delete;
        File& operator=(File&& iOther) noexcept = default;

        [[nodiscard]] bool write(const CMagneto::Core::Logger::Record& iRecord) noexcept override;
        [[nodiscard]] std::string_view errorMessage() const noexcept override;

        [[nodiscard]] const std::filesystem::path& filePath() const noexcept;

    private:
        std::filesystem::path mFilePath;
        std::ofstream mOutputFile;
        bool mColored{false};
        std::string mAppIdentityString;
        std::string mErrorMessage;
    };


} // namespace CMagneto::Core::logger::sinks
