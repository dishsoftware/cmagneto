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

#include <QString>

#include <filesystem>
#include <string>
#include <string_view>


namespace CMagneto::Qt::helpers {


    [[nodiscard]] inline QString toQString(const std::string_view iString) {
        return QString::fromUtf8(iString.data(), static_cast<qsizetype>(iString.size()));
    }


    [[nodiscard]] inline QString toQString(const std::string& iString) {
        return toQString(std::string_view{iString});
    }


    [[nodiscard]] inline QString toQString(const std::filesystem::path& iPath) {
        #ifdef _WIN32
            return QString::fromStdWString(iPath.native());
        #else
            return QString::fromUtf8(iPath.c_str());
        #endif
    }


} // namespace CMagneto::Qt::helpers
