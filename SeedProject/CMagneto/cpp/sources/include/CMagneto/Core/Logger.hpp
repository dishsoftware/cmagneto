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

#include <concepts>
#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <source_location>
#include <string>
#include <string_view>
#include <utility>


namespace CMagneto::Core {


    /** Logger with a registry of named output sinks. */
    class Logger {
    public:


        /** Message severity. */
        class Level {
            Level() = delete;
        public:
            enum class Enum : std::uint8_t {
                kOff,
                kCritical,
                kError,
                kWarning,
                kInfo,
                kDebug
            };


            inline static constexpr std::string_view kDebugString{"Debug"};
            inline static constexpr std::string_view kInfoString{"Info"};
            inline static constexpr std::string_view kWarningString{"Warning"};
            inline static constexpr std::string_view kErrorString{"Error"};
            inline static constexpr std::string_view kCriticalString{"Critical"};
            inline static constexpr std::string_view kOffString{"Off"};


            [[nodiscard]] static constexpr std::string_view toString(const Enum iEnum) noexcept {
                switch (iEnum) {
                    case Enum::kOff: return kOffString;
                    case Enum::kCritical: return kCriticalString;
                    case Enum::kError: return kErrorString;
                    case Enum::kWarning: return kWarningString;
                    case Enum::kInfo: return kInfoString;
                    case Enum::kDebug: return kDebugString;
                }
                return {};
            }


            [[nodiscard]] static constexpr std::optional<Enum> fromString(
                const std::string_view iString
            ) noexcept {
                if (iString == kOffString)
                    return Enum::kOff;

                if (iString == kCriticalString)
                    return Enum::kCritical;

                if (iString == kErrorString)
                    return Enum::kError;

                if (iString == kWarningString)
                    return Enum::kWarning;

                if (iString == kInfoString)
                    return Enum::kInfo;

                if (iString == kDebugString)
                    return Enum::kDebug;

                return std::nullopt;
            }
        }; // class Level


        /** Per-sink action on sink write failure. */
        class FailurePolicy {
            FailurePolicy() = delete;
        public:
            enum class Enum : std::uint8_t {
                kReportAndContinue,
                kTerminate
            };
        }; // class FailurePolicy


        /** Log entry. */
        struct Record {
            Level::Enum mLevel;
            std::string_view mCategory;
            std::string_view mText;
            std::source_location mSourceLocation;
        };


        /** Output for log entries. */
        class Sink {
        public:
            Sink() = default;
            virtual ~Sink() = default;
            Sink(const Sink& iOther) = default;
            Sink(Sink&& iOther) noexcept = default;
            Sink& operator=(const Sink& iOther) = default;
            Sink& operator=(Sink&& iOther) noexcept = default;

            [[nodiscard]] virtual bool write(const Record& iRecord) noexcept = 0;

            /** \returns A description why the last `write` has failed. */
            [[nodiscard]] virtual std::string_view errorMessage() const noexcept = 0;
        };


        /** Settings of a single registered sink. */
        struct SinkAndSettings {
            std::shared_ptr<Sink> mSink;
            Level::Enum mLevel;
            FailurePolicy::Enum mFailurePolicy;
        };


        Logger() noexcept = default;
        ~Logger() = default;
        Logger(const Logger& iOther) = default;
        Logger(Logger&& iOther) noexcept = default;
        Logger& operator=(const Logger& iOther) = default;
        Logger& operator=(Logger&& iOther) noexcept = default;

        [[nodiscard]] bool addSink(
            std::string iSinkID,
            std::shared_ptr<Sink> iSink,
            Level::Enum iLevel = Level::Enum::kInfo,
            FailurePolicy::Enum iFailurePolicy = FailurePolicy::Enum::kReportAndContinue
        );

        [[nodiscard]] bool removeSink(std::string_view iSinkID);
        [[nodiscard]] bool hasSink(std::string_view iSinkID) const;

        [[nodiscard]] bool setSinkLevel(
            std::string_view iSinkID,
            Level::Enum iLevel
        );

        [[nodiscard]] bool setSinkFailurePolicy(
            std::string_view iSinkID,
            FailurePolicy::Enum iFailurePolicy
        );

        [[nodiscard]] bool doesSinkLog(
            std::string_view iSinkID,
            Level::Enum iLevel
        ) const;

        [[nodiscard]] bool doesAnySinkLog(Level::Enum iLevel) const noexcept;

        [[nodiscard]] static constexpr bool doesLog(
            const Level::Enum iMessageLevel,
            const Level::Enum iThresholdLevel
        ) noexcept {
            if (iMessageLevel == Level::Enum::kOff || iThresholdLevel == Level::Enum::kOff)
                return false;

            return static_cast<std::uint8_t>(iMessageLevel) <= static_cast<std::uint8_t>(iThresholdLevel);
        }

        [[nodiscard]] bool log(
            Level::Enum iLevel,
            std::string_view iCategory,
            std::string_view iText,
            std::source_location iSourceLocation = std::source_location::current()
        ) const noexcept;

        template <typename MessageFactory>
            requires
                requires(MessageFactory&& iMessageFactory) { // <== Pretend there is a value named `iMessageFactory` of type `MessageFactory&&`.
                    std::string_view{                                   // |
                        std::forward<MessageFactory>(iMessageFactory)() // | Is the callable's result usable
                        //            Is `iMessageFactory` callable ==^ // | as a std::string_view.
                        //            with no arguments.                // |
                    };                                                  // |
                }
        [[nodiscard]] bool logLazy(
            const Level::Enum iLevel,
            const std::string_view iCategory,
            MessageFactory&& iMessageFactory,
            const std::source_location iSourceLocation = std::source_location::current()
        ) const noexcept(noexcept(std::string_view{std::forward<MessageFactory>(iMessageFactory)()})) {
            if (!doesAnySinkLog(iLevel))
                return true;

            return log(
                iLevel,
                iCategory,
                std::forward<MessageFactory>(iMessageFactory)(),
                iSourceLocation
            );
        }

    private:
        using Sinks = std::map<std::string, SinkAndSettings, std::less<>>;

        [[nodiscard]] SinkAndSettings* getSinkAndSettings(std::string_view iSinkID);
        [[nodiscard]] const SinkAndSettings* getSinkAndSettings(std::string_view iSinkID) const;

        Sinks mSinks;
    };


} // namespace CMagneto::Core
