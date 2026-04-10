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

#include <iosfwd>
#include <string>
#include <string_view>


namespace CMagneto::Core::logger::sinks {


    /** Basic logger sink which writes records to a console stream. */
    class Console : public CMagneto::Core::Logger::Sink {
    public:
        explicit Console(bool iColored = false) noexcept;
        explicit Console(std::ostream& iOutputStream, bool iColored = false) noexcept;
        ~Console() override = default;
        Console(const Console& iOther) = default;
        Console(Console&& iOther) noexcept = default;
        Console& operator=(const Console& iOther) = default;
        Console& operator=(Console&& iOther) noexcept = default;

        [[nodiscard]] bool write(const CMagneto::Core::Logger::Record& iRecord) noexcept override;
        [[nodiscard]] std::string_view errorMessage() const noexcept override;

    private:
        std::ostream* mOutputStream{nullptr};
        bool mColored{false};
        std::string mErrorMessage;
    };


} // namespace CMagneto::Core::logger::sinks
