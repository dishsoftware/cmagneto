// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Core/Logger.hpp"

#include <exception>
#include <iostream>
#include <utility>


namespace CMagneto::Core {


    namespace {
        void reportSinkFailure(
            const std::string_view iSinkID,
            const Logger::Sink& iSink
        ) noexcept {
            const std::string_view errorMessage = iSink.errorMessage();
            std::cerr
                << "CMagneto::Core::Logger: sink \""
                << iSinkID
                << "\" failed";

            if (!errorMessage.empty())
                std::cerr << ": " << errorMessage;

            std::cerr << '\n';
        }
    } // namespace


    bool Logger::addSink(
        std::string iSinkID,
        std::shared_ptr<Sink> iSink,
        const Level::Enum iLevel,
        const FailurePolicy::Enum iFailurePolicy
    ) {
        if (!iSink || hasSink(iSinkID))
            return false;

        mSinks.emplace(
            std::move(iSinkID),
            SinkAndSettings{
                .mSink = std::move(iSink),
                .mLevel = iLevel,
                .mFailurePolicy = iFailurePolicy
            }
        );

        return true;
    }


    bool Logger::removeSink(const std::string_view iSinkID) {
        const auto sinkIt = mSinks.find(iSinkID);
        if (sinkIt == mSinks.end())
            return false;

        mSinks.erase(sinkIt);
        return true;
    }


    bool Logger::hasSink(const std::string_view iSinkID) const {
        return mSinks.contains(iSinkID);
    }


    bool Logger::setSinkLevel(
        const std::string_view iSinkID,
        const Level::Enum iLevel
    ) {
        SinkAndSettings* const sinkAndSettings = getSinkAndSettings(iSinkID);
        if (!sinkAndSettings)
            return false;

        sinkAndSettings->mLevel = iLevel;
        return true;
    }


    bool Logger::setSinkFailurePolicy(
        const std::string_view iSinkID,
        const FailurePolicy::Enum iFailurePolicy
    ) {
        SinkAndSettings* const sinkAndSettings = getSinkAndSettings(iSinkID);
        if (!sinkAndSettings)
            return false;

        sinkAndSettings->mFailurePolicy = iFailurePolicy;
        return true;
    }


    bool Logger::doesSinkLog(
        const std::string_view iSinkID,
        const Level::Enum iLevel
    ) const {
        const SinkAndSettings* const sinkAndSettings = getSinkAndSettings(iSinkID);
        if (!sinkAndSettings)
            return false;

        return doesLog(iLevel, sinkAndSettings->mLevel);
    }


    bool Logger::doesAnySinkLog(const Level::Enum iLevel) const noexcept {
        for (const auto& [sinkID, sinkAndSettings] : mSinks) {
            static_cast<void>(sinkID);

            if (doesLog(iLevel, sinkAndSettings.mLevel))
                return true;
        }

        return false;
    }


    bool Logger::log(
        const Level::Enum iLevel,
        const std::string_view iCategory,
        const std::string_view iText,
        const std::source_location iSourceLocation
    ) const noexcept {
        const Record record{
            .mLevel = iLevel,
            .mCategory = iCategory,
            .mText = iText,
            .mSourceLocation = iSourceLocation
        };

        bool allWritesSucceeded = true;
        for (const auto& [sinkID, sinkAndSettings] : mSinks) {
            if (!doesLog(iLevel, sinkAndSettings.mLevel))
                continue;

            if (sinkAndSettings.mSink->write(record))
                continue;

            allWritesSucceeded = false;
            reportSinkFailure(sinkID, *sinkAndSettings.mSink);

            if (sinkAndSettings.mFailurePolicy == FailurePolicy::Enum::kTerminate)
                std::terminate();
        }

        return allWritesSucceeded;
    }


    Logger::SinkAndSettings* Logger::getSinkAndSettings(const std::string_view iSinkID) {
        const auto sinkIt = mSinks.find(iSinkID);
        if (sinkIt == mSinks.end())
            return nullptr;

        return &sinkIt->second;
    }


    const Logger::SinkAndSettings* Logger::getSinkAndSettings(const std::string_view iSinkID) const {
        const auto sinkIt = mSinks.find(iSinkID);
        if (sinkIt == mSinks.end())
            return nullptr;

        return &sinkIt->second;
    }


} // namespace CMagneto::Core
