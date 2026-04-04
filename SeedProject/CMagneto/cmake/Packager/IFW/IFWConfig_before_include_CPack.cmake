# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)  # Ensures this file is included only once.

include(CPackIFW)

cmake_path(SET _ifwPackageResourcesDir NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/IFW")

function(CMagnetoInternal__ifw_set_package_file_if_exists iVariable iFileName)
    cmake_path(SET _absPath NORMALIZE "${_ifwPackageResourcesDir}/${iFileName}")
    if(EXISTS "${_absPath}")
        set(${iVariable} "${_absPath}" PARENT_SCOPE)
    endif()
endfunction()

function(CMagnetoInternal__ifw_read_json_value_or_default iJsonText iKey iDefaultValue oValue)
    string(JSON _value ERROR_VARIABLE _error GET "${iJsonText}" "${iKey}")
    if(_error)
        set(${oValue} "${iDefaultValue}" PARENT_SCOPE)
        return()
    endif()

    set(${oValue} "${_value}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw_initialize_application_menu_options)
    set(CMagnetoInternal__IFW__WINDOWS_START_MENU_DIRECTORY "${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}" PARENT_SCOPE)

    cmake_path(SET _applicationMenuJsonPath NORMALIZE "${CMagneto__PACKAGE_RESOURCES_DIR}/ApplicationMenu.json")
    if(NOT EXISTS "${_applicationMenuJsonPath}")
        return()
    endif()

    file(READ "${_applicationMenuJsonPath}" _applicationMenuJsonText)

    CMagnetoInternal__ifw_read_json_value_or_default("${_applicationMenuJsonText}" "WindowsStartMenuDirectory" "${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}" _windowsStartMenuDirectory)
    if(_windowsStartMenuDirectory STREQUAL "")
        set(_windowsStartMenuDirectory "${CMagneto__PROJECT_JSON__COMPANY_NAME_SHORT}")
    endif()

    set(CMagnetoInternal__IFW__WINDOWS_START_MENU_DIRECTORY "${_windowsStartMenuDirectory}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw_make_text_expression iInputText oOutputExpression)
    set(_text "${iInputText}")
    string(REPLACE "\\" "\\\\" _text "${_text}")
    string(REPLACE "\"" "\\\"" _text "${_text}")
    string(REPLACE "\r" "" _text "${_text}")
    string(REPLACE "@ProjectNameForUI@" "${CMagneto__PROJECT_JSON__PROJECT_NAME_FOR_UI}" _text "${_text}")
    string(REPLACE "@ProjectHomepage@" "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}" _text "${_text}")
    string(REPLACE "@ProductName@" "\" + installer.value(\"ProductName\") + \"" _text "${_text}")
    string(REPLACE "@TargetDir@" "\" + installer.value(\"TargetDir\") + \"" _text "${_text}")
    string(REPLACE "\n" "\\n\"\n        + \"" _text "${_text}")
    set(${oOutputExpression} "${_text}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw_generate_default_control_script oScriptPath)
    cmake_path(SET _welcomePath NORMALIZE "${_ifwPackageResourcesDir}/Welcome.html")
    cmake_path(SET _finishedPath NORMALIZE "${_ifwPackageResourcesDir}/Finished.html")
    if(NOT EXISTS "${_welcomePath}" AND NOT EXISTS "${_finishedPath}")
        set(${oScriptPath} "" PARENT_SCOPE)
        return()
    endif()

    set(_scriptText [=[
function Controller()
{
    try {
        installer.setDefaultPageVisible(QInstaller.LicenseCheck, true);
    } catch (e) {
    }

    try {
        var introductionPage = gui.pageByObjectName("IntroductionPage");
        if (introductionPage) {
            introductionPage.entered.connect(this, Controller.prototype.CMagnetoInternal__ifw_customizeIntroductionPage);
        }

        var finishedPage = gui.pageByObjectName("FinishedPage");
        if (finishedPage) {
            finishedPage.entered.connect(this, Controller.prototype.CMagnetoInternal__ifw_customizeFinishedPage);
        }
    } catch (e) {
    }
}

function CMagnetoInternal__ifw_clear_widget_text_and_hide(widget)
{
    if (widget == null) {
        return;
    }

    try {
        if (typeof widget.setText === "function") {
            widget.setText("");
        }
    } catch (e) {
    }

    try {
        if (typeof widget.hide === "function") {
            widget.hide();
        } else {
            widget.visible = false;
        }
    } catch (e) {
    }
}

function CMagnetoInternal__ifw_prepare_message_label(widget)
{
    if (widget == null) {
        return;
    }

    try {
        widget.setTextFormat(1); // Qt.RichText
    } catch (e) {
    }

    try {
        widget.setTextInteractionFlags(13); // Qt.TextBrowserInteraction
    } catch (e) {
    }

    try {
        widget.setWordWrap(true);
    } catch (e) {
    }

    try {
        if (!widget.CMagnetoInternal__ifw_linksConnected && widget.linkActivated) {
            widget.linkActivated.connect(function(link) {
                QDesktopServices.openUrl(link);
            });
            widget.CMagnetoInternal__ifw_linksConnected = true;
        }
    } catch (e) {
    }
}

]=])

    if(EXISTS "${_welcomePath}")
        file(READ "${_welcomePath}" _welcomeText)
        CMagnetoInternal__ifw_make_text_expression("${_welcomeText}" _welcomeTextEscaped)
        string(APPEND _scriptText [=[
Controller.prototype.IntroductionPageCallback = function()
{
    Controller.prototype.CMagnetoInternal__ifw_customizeIntroductionPage();
}

Controller.prototype.CMagnetoInternal__ifw_customizeIntroductionPage = function()
{
    var widget = gui.currentPageWidget();
    if (widget != null && widget.MessageLabel) {
        CMagnetoInternal__ifw_prepare_message_label(widget.MessageLabel);
        widget.MessageLabel.setText("]=])
        string(APPEND _scriptText "${_welcomeTextEscaped}")
        string(APPEND _scriptText [=[");
    }
}

]=])
    endif()

    if(EXISTS "${_finishedPath}")
        file(READ "${_finishedPath}" _finishedText)
        CMagnetoInternal__ifw_make_text_expression("${_finishedText}" _finishedTextEscaped)
        string(APPEND _scriptText [=[
Controller.prototype.FinishedPageCallback = function()
{
    Controller.prototype.CMagnetoInternal__ifw_customizeFinishedPage();
}

Controller.prototype.CMagnetoInternal__ifw_customizeFinishedPage = function()
{
    var widget = gui.currentPageWidget();
    if (widget == null) {
        return;
    }

    if (widget.MessageLabel) {
        CMagnetoInternal__ifw_prepare_message_label(widget.MessageLabel);
        widget.MessageLabel.setText("]=])
        string(APPEND _scriptText "${_finishedTextEscaped}")
        string(APPEND _scriptText [=[");
    }

    CMagnetoInternal__ifw_clear_widget_text_and_hide(gui.findChild(widget, "FinishedText"));
    CMagnetoInternal__ifw_clear_widget_text_and_hide(gui.findChild(widget, "LocationLabel"));
    CMagnetoInternal__ifw_clear_widget_text_and_hide(gui.findChild(widget, "FinishText"));
    CMagnetoInternal__ifw_clear_widget_text_and_hide(gui.findChild(widget, "RunItCheckBox"));
}

]=])
    endif()

    cmake_path(SET _generatedScriptPath NORMALIZE "${CMAKE_CURRENT_BINARY_DIR}/CMagnetoGeneratedInstallerControlScript.qs")
    file(WRITE "${_generatedScriptPath}" "${_scriptText}")
    set(${oScriptPath} "${_generatedScriptPath}" PARENT_SCOPE)
endfunction()

set(CPACK_IFW_PACKAGE_NAME "${CMagneto__PACKAGING_JSON__PACKAGE_ID}")
set(CPACK_IFW_PACKAGE_TITLE "${CMagneto__PROJECT_JSON__PROJECT_NAME_FOR_UI} Installer")
set(CPACK_IFW_PACKAGE_PUBLISHER "${CPACK_PACKAGE_VENDOR}")
set(CPACK_IFW_PRODUCT_URL "${CMagneto__PROJECT_JSON__PROJECT_HOMEPAGE}")
CMagnetoInternal__ifw_initialize_application_menu_options()
set(CPACK_IFW_PACKAGE_START_MENU_DIRECTORY "${CMagnetoInternal__IFW__WINDOWS_START_MENU_DIRECTORY}")

# Force a consistent wizard presentation on Windows so the installer
# does not inherit unreadable dark host palette combinations.
if(WIN32)
    set(CPACK_IFW_PACKAGE_WIZARD_STYLE "Modern")
    set(CPACK_IFW_PACKAGE_TITLE_COLOR "#145b5b")
    set(CPACK_IFW_PACKAGE_WIZARD_DEFAULT_WIDTH 860)
    set(CPACK_IFW_PACKAGE_WIZARD_DEFAULT_HEIGHT 560)
endif()

if(WIN32)
    CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_ICON "PackageInstallerIcon.ico")
    if(NOT CPACK_IFW_PACKAGE_ICON)
        CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_ICON "PackageLogo.ico")
    endif()
endif()

CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_WINDOW_ICON "PackageWindowIcon.png")
if(NOT CPACK_IFW_PACKAGE_WINDOW_ICON)
    CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_WINDOW_ICON "PackageLogo.png")
endif()

CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_LOGO "PackageWizardLogo.png")
if(NOT CPACK_IFW_PACKAGE_LOGO)
    CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_LOGO "PackageLogo.png")
endif()

CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_WATERMARK "PackageWatermark.png")
CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_BANNER "PackageBanner.png")
CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_BACKGROUND "PackageBackground.png")
CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_STYLE_SHEET "Installer.qss")
CMagnetoInternal__ifw_set_package_file_if_exists(CPACK_IFW_PACKAGE_CONTROL_SCRIPT "InstallerControlScript.qs")
if(NOT CPACK_IFW_PACKAGE_CONTROL_SCRIPT)
    CMagnetoInternal__ifw_generate_default_control_script(_generatedControlScript)
    if(_generatedControlScript)
        set(CPACK_IFW_PACKAGE_CONTROL_SCRIPT "${_generatedControlScript}")
    endif()
endif()

cmake_path(SET _ifwPackageResourcesQrc NORMALIZE "${_ifwPackageResourcesDir}/InstallerResources.qrc")
if(EXISTS "${_ifwPackageResourcesQrc}")
    cpack_ifw_add_package_resources("${_ifwPackageResourcesQrc}")
endif()
