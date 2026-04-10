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

#include <ostream>
#include <string>
#include <string_view>


namespace CMagneto::Core::logger::sinks::common {


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

        return CMagneto::Core::extensions::StringLike::colored(plainLevelText, levelColor(iLevel));
    }


    [[nodiscard]] inline bool writeRecordToStream(
        std::ostream& ioOutputStream,
        const CMagneto::Core::Logger::Record& iRecord,
        const bool iColored
    ) {
        const std::string coloredLevelString = levelString(iRecord.mLevel, iColored);
        ioOutputStream
            << '[' << coloredLevelString << ']'
            << '[' << iRecord.mCategory << "] "
            << iRecord.mText
            << " (" << iRecord.mSourceLocation.file_name() << ':' << iRecord.mSourceLocation.line()
            << ")"
            << std::endl
        ;
        return static_cast<bool>(ioOutputStream);
    }


} // namespace CMagneto::Core::logger::sinks::common
