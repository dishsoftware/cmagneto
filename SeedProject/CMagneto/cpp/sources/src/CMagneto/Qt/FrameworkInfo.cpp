#include "CMagneto/Qt/FrameworkInfo.hpp"

#include "CMagneto/Core/FrameworkInfo.hpp"

#include <QString>


namespace CMagneto::Qt {
    QString frameworkName() {
        const auto frameworkName = CMagneto::Core::frameworkName();
        return QString::fromUtf8(frameworkName.data(), static_cast<qsizetype>(frameworkName.size()));
    }
} // namespace CMagneto::Qt
