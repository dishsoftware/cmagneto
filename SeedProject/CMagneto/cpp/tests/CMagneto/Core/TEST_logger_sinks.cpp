#include "CMagneto/Core/logger/sinks/Console.hpp"
#include "CMagneto/Core/logger/sinks/File.hpp"

#include <gtest/gtest.h>

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <unistd.h>


namespace CMagneto::Core::logger::sinks {


    namespace {
        [[nodiscard]] CMagneto::Core::Logger::Record makeTestRecord() {
            return CMagneto::Core::Logger::Record{
                .mLevel = CMagneto::Core::Logger::Level::Enum::kError,
                .mCategory = "Core",
                .mText = "Test message",
                .mSourceLocation = std::source_location::current()
            };
        }


        [[nodiscard]] std::filesystem::path makeTemporaryFilePath() {
            const std::filesystem::path tempDirectoryPath = std::filesystem::temp_directory_path();
            std::filesystem::path filePath = tempDirectoryPath / "CMagneto_Test_LoggerSinks_XXXXXX";

            std::string filePathString = filePath.string();
            const int fileDescriptor = mkstemp(filePathString.data());
            EXPECT_NE(fileDescriptor, -1);
            if (fileDescriptor != -1)
                close(fileDescriptor);

            return filePathString;
        }
    } // namespace


    TEST(CMagneto_Core_logger_sinks_Console, WritesToProvidedOutputStream) {
        std::ostringstream outputStream;
        Console sink{outputStream};

        EXPECT_TRUE(sink.write(makeTestRecord()));

        const std::string outputText = outputStream.str();
        EXPECT_EQ(outputText.front(), '[');
        EXPECT_NE(outputText.find(" UTC][Error][Core] Test message"), std::string::npos);
    }


    TEST(CMagneto_Core_logger_sinks_Console, CanColorLevelSubstring) {
        std::ostringstream outputStream;
        Console sink{outputStream, true};

        ASSERT_TRUE(sink.write(makeTestRecord()));

        const std::string outputText = outputStream.str();
        EXPECT_EQ(outputText.front(), '[');
        EXPECT_NE(outputText.find(" UTC]["), std::string::npos);
        EXPECT_NE(outputText.find("\033["), std::string::npos);
        EXPECT_NE(outputText.find("\033[0m"), std::string::npos);
        EXPECT_NE(outputText.find("Error"), std::string::npos);
    }


    TEST(CMagneto_Core_logger_sinks_Console, CanPrintAppIdentityPrefix) {
        std::ostringstream outputStream;
        Console sink{outputStream, false, "DishSW::ContactHolder::GUI"};

        ASSERT_TRUE(sink.write(makeTestRecord()));

        const std::string outputText = outputStream.str();
        EXPECT_NE(
            outputText.find(" UTC][Error][DishSW::ContactHolder::GUI][Core] Test message"),
            std::string::npos
        );
    }


    TEST(CMagneto_Core_logger_sinks_File, AppendsRecordsToFile) {
        const std::filesystem::path filePath = makeTemporaryFilePath();

        {
            File sink{filePath};
            ASSERT_TRUE(sink.write(makeTestRecord()));

            std::ifstream inputFile{filePath};
            ASSERT_TRUE(inputFile.is_open());

            std::string fileContent;
            std::getline(inputFile, fileContent);
            EXPECT_EQ(fileContent.front(), '[');
            EXPECT_NE(fileContent.find(" UTC][Error][Core] Test message"), std::string::npos);
        }

        std::filesystem::remove(filePath);
    }


    TEST(CMagneto_Core_logger_sinks_File, CanColorLevelSubstring) {
        const std::filesystem::path filePath = makeTemporaryFilePath();

        {
            File sink{filePath, true};
            ASSERT_TRUE(sink.write(makeTestRecord()));

            std::ifstream inputFile{filePath};
            ASSERT_TRUE(inputFile.is_open());

            std::string fileContent;
            std::getline(inputFile, fileContent);
            EXPECT_EQ(fileContent.front(), '[');
            EXPECT_NE(fileContent.find(" UTC]["), std::string::npos);
            EXPECT_NE(fileContent.find("\033["), std::string::npos);
            EXPECT_NE(fileContent.find("\033[0m"), std::string::npos);
            EXPECT_NE(fileContent.find("Error"), std::string::npos);
        }

        std::filesystem::remove(filePath);
    }


    TEST(CMagneto_Core_logger_sinks_File, CanPrintAppIdentityPrefix) {
        const std::filesystem::path filePath = makeTemporaryFilePath();

        {
            File sink{filePath, false, "DishSW::ContactHolder::GUI"};
            ASSERT_TRUE(sink.write(makeTestRecord()));

            std::ifstream inputFile{filePath};
            ASSERT_TRUE(inputFile.is_open());

            std::string fileContent;
            std::getline(inputFile, fileContent);
            EXPECT_NE(
                fileContent.find(" UTC][Error][DishSW::ContactHolder::GUI][Core] Test message"),
                std::string::npos
            );
        }

        std::filesystem::remove(filePath);
    }


    TEST(CMagneto_Core_logger_sinks_File, CreatesMissingDirectoryAndWritesRecord) {
        const std::filesystem::path filePath =
            std::filesystem::temp_directory_path() /
            "CMagneto_Test_LoggerSinks_MissingDir" /
            "missing.log";

        std::filesystem::remove_all(filePath.parent_path());

        {
            File sink{filePath};
            EXPECT_TRUE(sink.errorMessage().empty());
            EXPECT_TRUE(sink.write(makeTestRecord()));
            EXPECT_TRUE(std::filesystem::exists(filePath));
        }

        std::filesystem::remove_all(filePath.parent_path());
    }


    TEST(CMagneto_Core_logger_sinks_File, ExposesErrorMessageWhenFilePathIsADirectory) {
        const std::filesystem::path directoryPath =
            std::filesystem::temp_directory_path() /
            "CMagneto_Test_LoggerSinks_DirectoryPath";

        std::filesystem::create_directories(directoryPath);

        File sink{directoryPath};

        EXPECT_FALSE(sink.write(makeTestRecord()));
        EXPECT_FALSE(sink.errorMessage().empty());

        std::filesystem::remove_all(directoryPath);
    }


} // namespace CMagneto::Core::logger::sinks
