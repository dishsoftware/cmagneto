#include "DishSW/CMagneto/Qt/FrameworkInfo.hpp"

#include "DishSW/CMagneto/Core/FrameworkInfo.hpp"

#include <QString>


namespace DishSW::CMagneto::Qt {
    QString frameworkName() {
        const auto frameworkName = DishSW::CMagneto::Core::frameworkName();
        return QString::fromUtf8(frameworkName.data(), static_cast<qsizetype>(frameworkName.size()));
    }
} // namespace DishSW::CMagneto::Qt
