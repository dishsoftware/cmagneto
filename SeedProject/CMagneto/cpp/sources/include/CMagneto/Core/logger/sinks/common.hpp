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

#include "CMagneto/Core/extensions/StringLike.hpp"
#include "CMagneto/Core/Logger.hpp"

#include <array>
#include <chrono>
#include <ostream>
#include <string>
#include <string_view>
#include <ctime>


namespace CMagneto::Core::logger::sinks::common {


    [[nodiscard]] inline std::string utcTimestampString() {
        const std::time_t nowTimeT = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());

        // const std::tm* utcTime = std::gmtime(&nowTimeT);
        // `std::gmtime` is not used here because it returns shared static
        // storage. Another call can overwrite that shared `std::tm` before this
        // log line is formatted, especially in multithreaded code.
        //
        // Use the thread-safe platform variants that write into local `std::tm utcTime` instead.
        std::tm utcTime{};
#if defined(_WIN32)
        gmtime_s(&utcTime, &nowTimeT);
#else
        gmtime_r(&nowTimeT, &utcTime);
#endif

        std::array<char, 32> buffer{};
        const std::size_t charsCount = std::strftime(buffer.data(), buffer.size(), "%Y-%m-%d %H:%M:%S UTC", &utcTime);

        return std::string{buffer.data(), charsCount};
    }


    [[nodiscard]] constexpr CMagneto::Core::extensions::StringLike::Color::Enum levelColor(
        const CMagneto::Core::Logger::Level::Enum iLevel
    ) noexcept {
        switch (iLevel) {
            case CMagneto::Core::Logger::Level::Enum::kCritical:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kMagenta;

            case CMagneto::Core::Logger::Level::Enum::kError:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kRed;

            case CMagneto::Core::Logger::Level::Enum::kWarning:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kYellow;

            case CMagneto::Core::Logger::Level::Enum::kInfo:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kGreen;

            case CMagneto::Core::Logger::Level::Enum::kDebug:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kCyan;

            case CMagneto::Core::Logger::Level::Enum::kOff:
                return CMagneto::Core::extensions::StringLike::Color::Enum::kBlue;
        }

        return CMagneto::Core::extensions::StringLike::Color::Enum::kBlue;
    }


    [[nodiscard]] inline std::string levelString(
        const CMagneto::Core::Logger::Level::Enum iLevel,
        const bool iColored
    ) {
        const std::string_view plainLevelText = CMagneto::Core::Logger::Level::toString(iLevel);
        if (!iColored)
            return std::string{plainLevelText};

        return CMagneto::Core::extensions::StringLike::makeColored(plainLevelText, levelColor(iLevel));
    }


    [[nodiscard]] inline bool writeRecordToStream(
        std::ostream& ioOutputStream,
        const CMagneto::Core::Logger::Record& iRecord,
        const bool iColored,
        const std::string_view iAppIdentityString = {}
    ) {
        const std::string coloredLevelString = levelString(iRecord.mLevel, iColored);
        ioOutputStream
            << '[' << utcTimestampString() << ']'
            << '[' << coloredLevelString << ']';

        if (!iAppIdentityString.empty())
            ioOutputStream << '[' << iAppIdentityString << ']';

        ioOutputStream
            << '[' << iRecord.mCategory << "] "
            << iRecord.mText
            << " (" << iRecord.mSourceLocation.file_name() << ':' << iRecord.mSourceLocation.line()
            << ")"
            << std::endl
        ;
        return static_cast<bool>(ioOutputStream);
    }


} // namespace CMagneto::Core::logger::sinks::common
