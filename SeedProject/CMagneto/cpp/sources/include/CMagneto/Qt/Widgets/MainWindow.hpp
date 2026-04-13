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

#include "CMagneto/Qt/Widgets/mixins/WithGeometryAndStateSettings.hpp"

#include <QMainWindow>


namespace CMagneto::Qt::Widgets {


    class AppContext;


    class MainWindow
    :
        public QMainWindow,
        public CMagneto::Qt::Widgets::mixins::WithGeometryAndStateSettings
    {
    public:
        explicit MainWindow(
            CMagneto::Qt::Widgets::AppContext& iAppContext,
            CMagneto::Core::HierarchicalID iNestingID,
            QWidget* iParent = nullptr
        );

        void loadSettings();

    protected:
        void closeEvent(QCloseEvent* iEvent) override;
    };


} // namespace CMagneto::Qt::Widgets
