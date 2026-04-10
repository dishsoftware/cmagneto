// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto framework.
//
// By default, the CMagneto framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Core/logger/sinks/File.hpp"
#include "CMagneto/Core/logger/sinks/common.hpp"

#include <exception>
#include <fstream>
#include <ostream>
#include <utility>


namespace CMagneto::Core::logger::sinks {


    File::File(std::filesystem::path iFilePath, const bool iColored)
    :
        mFilePath{std::move(iFilePath)},
        mOutputFile{mFilePath, std::ios::app},
        mColored{iColored}
    {
        if (!mOutputFile)
            mErrorMessage = "Failed to open log file.";
    }


    bool File::write(const CMagneto::Core::Logger::Record& iRecord) noexcept {
        if (!mOutputFile) {
            if (mErrorMessage.empty())
                mErrorMessage = "Log file is not open.";

            return false;
        }

        mErrorMessage.clear();

        try {
            if (common::writeRecordToStream(mOutputFile, iRecord, mColored)) {
                mOutputFile.flush();
                if (mOutputFile)
                    return true;
            }

            mErrorMessage = "Failed to write to log file.";
            return false;
        }
        catch (const std::exception& exception) {
            mErrorMessage = exception.what();
            return false;
        }
        catch (...) {
            mErrorMessage = "Unknown error while writing to log file.";
            return false;
        }
    }


    std::string_view File::errorMessage() const noexcept {
        return mErrorMessage;
    }


    const std::filesystem::path& File::filePath() const noexcept {
        return mFilePath;
    }


} // namespace CMagneto::Core::logger::sinks
