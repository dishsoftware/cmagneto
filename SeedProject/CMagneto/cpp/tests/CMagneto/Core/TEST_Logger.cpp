#include "CMagneto/Core/Logger.hpp"

#include <gtest/gtest.h>

#include <cstdio>
#ifdef _WIN32
    #include <io.h>
#else
    #include <unistd.h>
#endif
#include <memory>
#include <optional>
#include <string>
#include <string_view>


namespace CMagneto::Core {


    namespace {
        /** Duplicates an OS file descriptor so the original stream can be restored later. */
        [[nodiscard]] int dupFD(const int iFileDescriptor) {
            #ifdef _WIN32
                return _dup(iFileDescriptor);
            #else
                return dup(iFileDescriptor);
            #endif
        }


        /** Redirects one file descriptor to another, e.g. temporary stderr capture in tests. */
        [[nodiscard]] int dup2FD(const int iSourceFileDescriptor, const int iTargetFileDescriptor) {
            #ifdef _WIN32
                return _dup2(iSourceFileDescriptor, iTargetFileDescriptor);
            #else
                return dup2(iSourceFileDescriptor, iTargetFileDescriptor);
            #endif
        }


        /** Returns the OS file descriptor behind a C `FILE*` stream. */
        [[nodiscard]] int fileNumber(FILE* iFile) {
            #ifdef _WIN32
                return _fileno(iFile);
            #else
                return fileno(iFile);
            #endif
        }


        /** Closes an OS file descriptor using the platform-specific runtime call. */
        void closeFD(const int iFileDescriptor) {
            #ifdef _WIN32
                _close(iFileDescriptor);
            #else
                close(iFileDescriptor);
            #endif
        }


        class TestSink : public Logger::Sink {
        public:
            explicit TestSink(const bool iShouldSucceed = true) noexcept
            :
                mShouldSucceed{iShouldSucceed}
            {}

            TestSink(const TestSink& iOther) = default;
            ~TestSink() override = default;
            TestSink(TestSink&& iOther) noexcept = default;
            TestSink& operator=(const TestSink& iOther) = default;
            TestSink& operator=(TestSink&& iOther) noexcept = default;

            [[nodiscard]] bool write(const Logger::Record& iRecord) noexcept override {
                ++mNumOfCalls;
                mLastRecord = iRecord;
                return mShouldSucceed;
            }

            [[nodiscard]] std::string_view errorMessage() const noexcept override {
                return mErrorMessage;
            }

            bool mShouldSucceed{true};
            std::string mErrorMessage{"Test sink failure."};
            std::size_t mNumOfCalls{0};
            std::optional<Logger::Record> mLastRecord;
        };


        class StderrCapture {
        public:
            StderrCapture()
            :
                mFile{std::tmpfile()}
            {
                EXPECT_NE(mFile, nullptr);

                mOriginalFD = dupFD(fileNumber(stderr));
                EXPECT_NE(mOriginalFD, -1);
                EXPECT_NE(dup2FD(fileNumber(mFile), fileNumber(stderr)), -1);
            }

            StderrCapture(const StderrCapture& iOther) = delete;
            StderrCapture(StderrCapture&& iOther) noexcept = delete;
            StderrCapture& operator=(const StderrCapture& iOther) = delete;
            StderrCapture& operator=(StderrCapture&& iOther) noexcept = delete;

            ~StderrCapture() {
                if (mOriginalFD != -1) {
                    fflush(stderr);
                    static_cast<void>(dup2FD(mOriginalFD, fileNumber(stderr)));
                    closeFD(mOriginalFD);
                }

                if (mFile)
                    fclose(mFile);
            }

            [[nodiscard]] std::string readCapturedText() const {
                if (!mFile)
                    return {};

                fflush(stderr);
                fseek(mFile, 0, SEEK_SET);

                std::string text;
                char buffer[256];
                while (true) {
                    const std::size_t numOfReadBytes = fread(buffer, 1, sizeof(buffer), mFile);
                    text.append(buffer, numOfReadBytes);
                    if (numOfReadBytes < sizeof(buffer))
                        return text;
                }
            }

        private:
            FILE* mFile{nullptr};
            int mOriginalFD{-1};
        };
    } // namespace


    TEST(CMagneto_Core_Logger, LevelToStringReturnsNamesForAllLevels) {
        using Level = Logger::Level;

        EXPECT_EQ(Level::toString(Level::Enum::kOff), Level::kOffString);
        EXPECT_EQ(Level::toString(Level::Enum::kCritical), Level::kCriticalString);
        EXPECT_EQ(Level::toString(Level::Enum::kError), Level::kErrorString);
        EXPECT_EQ(Level::toString(Level::Enum::kWarning), Level::kWarningString);
        EXPECT_EQ(Level::toString(Level::Enum::kInfo), Level::kInfoString);
        EXPECT_EQ(Level::toString(Level::Enum::kDebug), Level::kDebugString);
    }


    TEST(CMagneto_Core_Logger, LevelFromStringParsesKnownValuesAndRejectsUnknownValue) {
        using Level = Logger::Level;

        EXPECT_EQ(Level::fromString(Level::kOffString), Level::Enum::kOff);
        EXPECT_EQ(Level::fromString(Level::kCriticalString), Level::Enum::kCritical);
        EXPECT_EQ(Level::fromString(Level::kErrorString), Level::Enum::kError);
        EXPECT_EQ(Level::fromString(Level::kWarningString), Level::Enum::kWarning);
        EXPECT_EQ(Level::fromString(Level::kInfoString), Level::Enum::kInfo);
        EXPECT_EQ(Level::fromString(Level::kDebugString), Level::Enum::kDebug);
        EXPECT_EQ(Level::fromString("Unknown"), std::nullopt);
    }


    TEST(CMagneto_Core_Logger, doesLogTreatsLowerEnumValuesAsMoreSevere) {
        using Level = Logger::Level;

        EXPECT_TRUE(Logger::doesLog(Level::Enum::kCritical, Level::Enum::kCritical));
        EXPECT_TRUE(Logger::doesLog(Level::Enum::kError, Level::Enum::kWarning));
        EXPECT_TRUE(Logger::doesLog(Level::Enum::kCritical, Level::Enum::kInfo));
        EXPECT_FALSE(Logger::doesLog(Level::Enum::kInfo, Level::Enum::kWarning));
        EXPECT_FALSE(Logger::doesLog(Level::Enum::kDebug, Level::Enum::kCritical));
        EXPECT_FALSE(Logger::doesLog(Level::Enum::kOff, Level::Enum::kDebug));
        EXPECT_FALSE(Logger::doesLog(Level::Enum::kCritical, Level::Enum::kOff));
    }


    TEST(CMagneto_Core_Logger, addSinkRejectsDuplicateIDs) {
        Logger logger;

        EXPECT_TRUE(logger.addSink("console", std::make_shared<TestSink>()));
        EXPECT_FALSE(logger.addSink("console", std::make_shared<TestSink>()));
        EXPECT_TRUE(logger.hasSink("console"));
    }


    TEST(CMagneto_Core_Logger, doesSinkLogUsesPerSinkLevels) {
        Logger logger;

        ASSERT_TRUE(logger.addSink("warnings", std::make_shared<TestSink>(), Logger::Level::Enum::kWarning));
        ASSERT_TRUE(logger.addSink("debug", std::make_shared<TestSink>(), Logger::Level::Enum::kDebug));

        EXPECT_TRUE(logger.doesSinkLog("warnings", Logger::Level::Enum::kError));
        EXPECT_TRUE(logger.doesSinkLog("warnings", Logger::Level::Enum::kWarning));
        EXPECT_FALSE(logger.doesSinkLog("warnings", Logger::Level::Enum::kInfo));

        EXPECT_TRUE(logger.doesSinkLog("debug", Logger::Level::Enum::kDebug));
        EXPECT_TRUE(logger.doesAnySinkLog(Logger::Level::Enum::kInfo));
        EXPECT_FALSE(logger.doesSinkLog("missing", Logger::Level::Enum::kCritical));
    }


    TEST(CMagneto_Core_Logger, removeSinkRemovesRegisteredSink) {
        Logger logger;

        ASSERT_TRUE(logger.addSink("console", std::make_shared<TestSink>()));
        EXPECT_TRUE(logger.hasSink("console"));
        EXPECT_TRUE(logger.removeSink("console"));
        EXPECT_FALSE(logger.hasSink("console"));
        EXPECT_FALSE(logger.removeSink("console"));
    }


    TEST(CMagneto_Core_Logger, LogReportsAndContinuesWhenFailingSinkPolicyIsReportAndContinue) {
        auto failingSink = std::make_shared<TestSink>(false);
        auto succeedingSink = std::make_shared<TestSink>(true);
        StderrCapture stderrCapture;

        Logger logger;
        ASSERT_TRUE(
            logger.addSink(
                "failing",
                failingSink,
                Logger::Level::Enum::kWarning,
                Logger::FailurePolicy::Enum::kReportAndContinue
            )
        );
        ASSERT_TRUE(
            logger.addSink(
                "succeeding",
                succeedingSink,
                Logger::Level::Enum::kWarning,
                Logger::FailurePolicy::Enum::kReportAndContinue
            )
        );

        EXPECT_FALSE(logger.log(Logger::Level::Enum::kError, "Core", "Emitted message"));
        EXPECT_EQ(failingSink->mNumOfCalls, 1U);
        EXPECT_EQ(succeedingSink->mNumOfCalls, 1U);

        const std::string stderrText = stderrCapture.readCapturedText();
        EXPECT_NE(stderrText.find("sink \"failing\" failed"), std::string::npos);
        EXPECT_NE(stderrText.find("Test sink failure."), std::string::npos);
    }


    TEST(CMagneto_Core_Logger, LogTerminatesWhenFailingSinkPolicyIsTerminate) {
        auto failingSink = std::make_shared<TestSink>(false);
        auto succeedingSink = std::make_shared<TestSink>(true);

        Logger logger;
        ASSERT_TRUE(
            logger.addSink(
                "failing",
                failingSink,
                Logger::Level::Enum::kWarning,
                Logger::FailurePolicy::Enum::kTerminate
            )
        );
        ASSERT_TRUE(
            logger.addSink(
                "succeeding",
                succeedingSink,
                Logger::Level::Enum::kWarning,
                Logger::FailurePolicy::Enum::kReportAndContinue
            )
        );

        EXPECT_DEATH(
            static_cast<void>(logger.log(Logger::Level::Enum::kError, "Core", "Emitted message")),
            "sink \"failing\" failed: Test sink failure\\."
        );
    }


    TEST(CMagneto_Core_Logger, LogUsesPerSinkLevelFiltering) {
        auto warningSink = std::make_shared<TestSink>(true);
        auto debugSink = std::make_shared<TestSink>(true);

        Logger logger;
        ASSERT_TRUE(logger.addSink("warning", warningSink, Logger::Level::Enum::kWarning));
        ASSERT_TRUE(logger.addSink("debug", debugSink, Logger::Level::Enum::kDebug));

        EXPECT_TRUE(logger.log(Logger::Level::Enum::kInfo, "Core", "Info message"));
        EXPECT_EQ(warningSink->mNumOfCalls, 0U);
        ASSERT_TRUE(debugSink->mLastRecord.has_value());
        EXPECT_EQ(debugSink->mLastRecord->mText, "Info message");

        EXPECT_TRUE(logger.log(Logger::Level::Enum::kError, "Core", "Error message"));
        EXPECT_EQ(warningSink->mNumOfCalls, 1U);
        EXPECT_EQ(debugSink->mNumOfCalls, 2U);
    }


    TEST(CMagneto_Core_Logger, LogLazySkipsMessageFactoryWhenNoSinkWouldLogLevel) {
        auto warningSink = std::make_shared<TestSink>(true);

        Logger logger;
        ASSERT_TRUE(logger.addSink("warning", warningSink, Logger::Level::Enum::kWarning));

        bool wasFactoryCalled = false;
        EXPECT_TRUE(
            logger.logLazy(
                Logger::Level::Enum::kInfo,
                "Core",
                [&wasFactoryCalled]() -> std::string_view {
                    wasFactoryCalled = true;
                    return "Ignored message";
                }
            )
        );
        EXPECT_FALSE(wasFactoryCalled);
        EXPECT_EQ(warningSink->mNumOfCalls, 0U);

        EXPECT_TRUE(
            logger.logLazy(
                Logger::Level::Enum::kError,
                "Core",
                [&wasFactoryCalled]() -> std::string_view {
                    wasFactoryCalled = true;
                    return "Emitted message";
                }
            )
        );
        EXPECT_TRUE(wasFactoryCalled);
        EXPECT_EQ(warningSink->mNumOfCalls, 1U);
        ASSERT_TRUE(warningSink->mLastRecord.has_value());
        EXPECT_EQ(warningSink->mLastRecord->mText, "Emitted message");
    }


} // namespace CMagneto::Core
