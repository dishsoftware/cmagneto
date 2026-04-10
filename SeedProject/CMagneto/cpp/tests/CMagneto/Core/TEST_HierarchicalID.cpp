#include "CMagneto/Core/HierarchicalID.hpp"

#include <gtest/gtest.h>

#include <array>
#include <list>
#include <string_view>
#include <vector>


namespace CMagneto::Core {
    TEST(CMagneto_Core_HierarchicalID, ConstructsFromRelativeLeafString) {
        const HierarchicalID mainWindow{"/MainWindow"};
        const HierarchicalID settingsWindow{mainWindow, "Settings/Fonts"};

        EXPECT_EQ(settingsWindow.stringID(), "/MainWindow/Settings/Fonts");

        const std::vector<std::string> expectedLeafs{"MainWindow", "Settings", "Fonts"};
        EXPECT_EQ(settingsWindow.leafs(), expectedLeafs);
    }


    TEST(CMagneto_Core_HierarchicalID, ReturnsRelativeLeafsOfThisToAncestor) {
        const HierarchicalID mainWindow{"/MainWindow"};
        const HierarchicalID settingsWindow{mainWindow, "Settings/Fonts"};

        const std::vector<std::string> expectedLeafs{"Settings", "Fonts"};
        EXPECT_EQ(settingsWindow.relativeLeafs(mainWindow), expectedLeafs);
        EXPECT_EQ(settingsWindow.relativeLeafsAsString(mainWindow), "Settings/Fonts");
        EXPECT_EQ(settingsWindow.relativeLeafsAsStringView(mainWindow), "Settings/Fonts");

        const std::span<const std::string> relativeLeafsSpan = settingsWindow.relativeLeafsAsSpan(mainWindow);
        ASSERT_EQ(relativeLeafsSpan.size(), expectedLeafs.size());
        EXPECT_EQ(relativeLeafsSpan[0], "Settings");
        EXPECT_EQ(relativeLeafsSpan[1], "Fonts");

        const HierarchicalID otherWindow{"/OtherWindow"};
        EXPECT_TRUE(settingsWindow.relativeLeafs(otherWindow).empty());
        EXPECT_TRUE(settingsWindow.relativeLeafsAsString(otherWindow).empty());
        EXPECT_TRUE(settingsWindow.relativeLeafsAsStringView(otherWindow).empty());
        EXPECT_TRUE(settingsWindow.relativeLeafsAsSpan(otherWindow).empty());
    }


    TEST(CMagneto_Core_HierarchicalID, GenericRangeConstructorAcceptsNonVectorRanges) {
        const HierarchicalID mainWindow{"/MainWindow"};

        const std::array<std::string_view, 2> settingsLeafs{"Settings", "Fonts"};
        const HierarchicalID settingsWindow{mainWindow, settingsLeafs};
        EXPECT_EQ(settingsWindow.stringID(), "/MainWindow/Settings/Fonts");

        const std::list<std::string> dialogLeafs{"Dialogs", "OpenFile"};
        const HierarchicalID dialogWindow{mainWindow, dialogLeafs};
        EXPECT_EQ(dialogWindow.stringID(), "/MainWindow/Dialogs/OpenFile");
    }
} // namespace CMagneto::Core
