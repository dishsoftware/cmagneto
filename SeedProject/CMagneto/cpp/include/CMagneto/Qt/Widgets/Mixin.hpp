#pragma once

#include "CMagneto/Core/HierarchicalID.hpp"

#include <QSettings>
#include <QWidget>

#include <string>
#include <vector>


namespace CMagneto::Qt::Widgets {


    class Mixin {
    protected:
        explicit Mixin(
            CMagneto::Core::HierarchicalID iID
        );

    public:
        const std::string& nestingID();

    private:
        std::string mNestingID;
    };


    class MixinWithGeometrySettings {
    protected:
        explicit MixinWithGeometrySettings(
            const std::string& iParentNestingID,
            const std::string& iNestingLeaf
        );

        void loadWidgetGeometry(QWidget& iWidget) const;
        void saveWidgetGeometry(const QWidget& iWidget) const;


    };


} // namespace CMagneto::Qt::Widgets
