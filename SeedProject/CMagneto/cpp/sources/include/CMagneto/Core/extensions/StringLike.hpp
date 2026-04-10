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

#include <concepts>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>


namespace CMagneto::Core::extensions::StringLike {


    namespace Color {
        enum class Enum : std::uint8_t {
            kRed = 31,
            kGreen = 32,
            kYellow = 33,
            kBlue = 34,
            kMagenta = 35,
            kCyan = 36
        };


        [[nodiscard]] constexpr std::uint8_t toCode(const Enum iColor) noexcept {
            return static_cast<std::uint8_t>(iColor);
        }
    } // namespace Color


    inline static constexpr std::string_view kANSIEscapePrefix{"\033["};
    inline static constexpr std::string_view kANSIEscapeSuffix{"m"};
    inline static constexpr std::string_view kANSIReset{"\033[0m"};


    template <typename TStringLike>
        requires
            requires(TStringLike&& iText) {
                std::string_view{std::forward<TStringLike>(iText)};
            }
    [[nodiscard]] std::string makeColored(
        TStringLike&& iText,
        const std::uint8_t iColorCode
    ) {
        const std::string_view text = std::forward<TStringLike>(iText);

        std::string coloredText;
        coloredText.reserve(
            kANSIEscapePrefix.size() +
            4U +
            kANSIEscapeSuffix.size() +
            text.size() +
            kANSIReset.size()
        );

        coloredText.append(kANSIEscapePrefix);
        coloredText.append(std::to_string(iColorCode));
        coloredText.append(kANSIEscapeSuffix);
        coloredText.append(text);
        coloredText.append(kANSIReset);

        return coloredText;
    }


    template <typename TStringLike>
        requires
            requires(TStringLike&& iText) {
                std::string_view{std::forward<TStringLike>(iText)};
            }
    [[nodiscard]] std::string makeColored(
        TStringLike&& iText,
        const Color::Enum iColor
    ) {
        return makeColored(std::forward<TStringLike>(iText), Color::toCode(iColor));
    }


} // namespace CMagneto::Core::extensions::StringLike
