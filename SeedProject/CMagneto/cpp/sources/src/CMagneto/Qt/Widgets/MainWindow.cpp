// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#include "CMagneto/Qt/Widgets/MainWindow.hpp"

#include "CMagneto/Qt/Widgets/AppContext.hpp"

#include <QCloseEvent>

#include <utility>


namespace CMagneto::Qt::Widgets {


    MainWindow::MainWindow(
        CMagneto::Qt::Widgets::AppContext& iAppContext,
        CMagneto::Core::HierarchicalID iNestingID,
        QWidget* iParent
    ) :
        QMainWindow{iParent},
        WithGeometryAndStateSettings{
            iAppContext,
            std::move(iNestingID)
        }
    {}


    void MainWindow::loadSettings() {
        loadGeometrySettings(*this);
        loadStateSettings(*this);
    }


    void MainWindow::closeEvent(QCloseEvent* iEvent) {
        saveStateSettings(*this);
        saveGeometrySettings(*this);
        QMainWindow::closeEvent(iEvent);
    }


} // namespace CMagneto::Qt::Widgets
