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
            CMagneto::Core::HierarchicalID iNestingID // TODO Perfect forwarding
        ):
            mNestingID{iNestingID}
        {}

    public:
        const CMagneto::Core::HierarchicalID& nestingID() {
            return mNestingID;
        }

    private:
        CMagneto::Core::HierarchicalID mNestingID;
    };


    class MixinWithGeometrySettings {
    protected:
        explicit MixinWithGeometrySettings(
            CMagneto::Core::HierarchicalID iNestingID
        );

        virtual void loadWidgetGeometrySettings(QWidget& iWidget) const;
        virtual void saveWidgetGeometrySettings(const QWidget& iWidget) const;
    };


} // namespace CMagneto::Qt::Widgets
