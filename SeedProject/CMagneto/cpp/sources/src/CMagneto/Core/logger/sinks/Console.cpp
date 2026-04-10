// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Core/logger/sinks/Console.hpp"
#include "CMagneto/Core/logger/sinks/common.hpp"

#include <exception>
#include <iostream>
#include <ostream>
#include <utility>


namespace CMagneto::Core::logger::sinks {


    Console::Console(
        const bool iColored,
        std::string iAppIdentityString
    ) noexcept :
        mOutputStream{&std::cerr},
        mColored{iColored},
        mAppIdentityString{std::move(iAppIdentityString)}
    {}


    Console::Console(
        std::ostream& iOutputStream,
        const bool iColored,
        std::string iAppIdentityString
    ) noexcept :
        mOutputStream{&iOutputStream},
        mColored{iColored},
        mAppIdentityString{std::move(iAppIdentityString)}
    {}


    bool Console::write(const CMagneto::Core::Logger::Record& iRecord) noexcept {
        mErrorMessage.clear();

        if (!mOutputStream) {
            mErrorMessage = "Output stream is null.";
            return false;
        }

        try {
            if (common::writeRecordToStream(*mOutputStream, iRecord, mColored, mAppIdentityString))
                return true;

            mErrorMessage = "Failed to write to output stream.";
            return false;
        }
        catch (const std::exception& exception) {
            mErrorMessage = exception.what();
            return false;
        }
        catch (...) {
            mErrorMessage = "Unknown error while writing to output stream.";
            return false;
        }
    }


    std::string_view Console::errorMessage() const noexcept {
        return mErrorMessage;
    }


} // namespace CMagneto::Core::logger::sinks
