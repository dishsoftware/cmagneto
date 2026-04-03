# Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
# SPDX-License-Identifier: MIT
#
# This file is part of the CMagneto framework.
# It is licensed under the MIT license found in the LICENSE file
# located at the root directory of the CMagneto framework.
#
# By default, the CMagneto framework root resides at the root of the project where it is used,
# but consumers may relocate it as needed.

include_guard(GLOBAL)

function(CMagnetoInternal__ifw__escape_js_string iInputText oEscapedText)
    set(_text "${iInputText}")
    string(REPLACE "\\" "\\\\" _text "${_text}")
    string(REPLACE "\"" "\\\"" _text "${_text}")
    string(REPLACE "\r" "" _text "${_text}")
    string(REPLACE "\n" "\\n" _text "${_text}")
    set(${oEscapedText} "${_text}" PARENT_SCOPE)
endfunction()

function(CMagnetoInternal__ifw__generate_license_page_component_script oScriptPath)
    set(_bundleFileEntries ${CMagneto__LICENSE_BUNDLE_FILE_ENTRIES})
    if(NOT _bundleFileEntries)
        get_property(_bundleFileEntries GLOBAL PROPERTY CMagneto__LICENSE_BUNDLE_FILE_ENTRIES)
    endif()

    list(LENGTH _bundleFileEntries _entriesCount)
    if(_entriesCount EQUAL 0)
        set(${oScriptPath} "" PARENT_SCOPE)
        return()
    endif()

    cmake_path(SET _generatedScriptPath NORMALIZE "${CMAKE_CURRENT_BINARY_DIR}/CMagnetoGeneratedIfwLicensePageComponentScript.qs")
    file(WRITE "${_generatedScriptPath}" [=[
var CMagnetoInternal__ifw_legalFiles = [
]=])

    set(_isFirstLegalFile TRUE)
    math(EXPR _lastEntryIndex "${_entriesCount} - 5")
    foreach(_entryIndex RANGE 0 ${_lastEntryIndex} 5)
        math(EXPR _kindIndex "${_entryIndex} + 2")
        math(EXPR _installRelIndex "${_entryIndex} + 3")
        math(EXPR _sourceAbsIndex "${_entryIndex} + 4")

        list(GET _bundleFileEntries ${_kindIndex} _kind)
        list(GET _bundleFileEntries ${_installRelIndex} _installRel)
        list(GET _bundleFileEntries ${_sourceAbsIndex} _sourceAbs)

        file(READ "${_sourceAbs}" _fileText)
        CMagnetoInternal__ifw__escape_js_string("${_kind}" _kindEscaped)
        CMagnetoInternal__ifw__escape_js_string("${_installRel}" _installRelEscaped)
        CMagnetoInternal__ifw__escape_js_string("${_fileText}" _fileTextEscaped)

        string(CONCAT _legalFileObjectText
            "    {\n"
            "        kind: \"${_kindEscaped}\",\n"
            "        installRel: \"${_installRelEscaped}\",\n"
            "        text: \"${_fileTextEscaped}\"\n"
            "    }"
        )
        if(NOT _isFirstLegalFile)
            file(APPEND "${_generatedScriptPath}" ",\n")
        endif()
        file(APPEND "${_generatedScriptPath}" "${_legalFileObjectText}")
        set(_isFirstLegalFile FALSE)
    endforeach()

    file(APPEND "${_generatedScriptPath}" [=[
];

function Component()
{
    if (installer.isInstaller()) {
        installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
        component.loaded.connect(this, Component.prototype.CMagnetoInternal__ifw_initializeLicensePage);
    }
}

Component.prototype.CMagnetoInternal__ifw_initializeLicensePage = function()
{
    if (!installer.addWizardPage(component, "LicenseBundleWidget", QInstaller.LicenseCheck))
        return;

    var widget = gui.pageWidgetByObjectName("DynamicLicenseBundleWidget");
    if (widget == null)
        return;

    Component.prototype.CMagnetoInternal__ifw_initializeLicenseBundleWidget(widget);
}

Component.prototype.CMagnetoInternal__ifw_initializeLicenseBundleWidget = function(widget)
{
    if (widget == null)
        return;

    if (widget.CMagnetoInternal__ifw_initialized) {
        widget.complete = widget.acceptProjectLicenseCheckBox.checked;
        return;
    }

    widget.windowTitle = "Licenses";
    widget.complete = false;
    var acceptCheckBox = gui.findChild(widget, "acceptProjectLicenseCheckBox");
    var legalFilesTreeBrowser = gui.findChild(widget, "legalFilesTreeBrowser");
    var mainSplitter = gui.findChild(widget, "mainSplitter");
    var treeContainerWidget = gui.findChild(widget, "treeContainerWidget");
    var textContainerWidget = gui.findChild(widget, "textContainerWidget");

    if (acceptCheckBox == null || legalFilesTreeBrowser == null || mainSplitter == null
            || treeContainerWidget == null || textContainerWidget == null)
        return;

    acceptCheckBox.checked = false;

    try {
        legalFilesTreeBrowser.setOpenLinks(false);
    } catch (e) {
    }

    try {
        legalFilesTreeBrowser.setOpenExternalLinks(false);
    } catch (e) {
    }

    try {
        treeContainerWidget.minimumHeight = 110;
        textContainerWidget.minimumHeight = 180;
    } catch (e) {
    }

    try {
        mainSplitter.setSizes([160, 320]);
    } catch (e) {
    }

    try {
        acceptCheckBox.toggled.connect(this, Component.prototype.CMagnetoInternal__ifw_licenseAcceptedToggled);
    } catch (e) {
    }

    try {
        legalFilesTreeBrowser.anchorClicked.connect(this, Component.prototype.CMagnetoInternal__ifw_selectedLegalFileLinkChanged);
    } catch (e) {
    }

    try {
        Component.prototype.CMagnetoInternal__ifw_populateLegalFilesBrowser(widget);
    } catch (e) {
        return;
    }
    widget.CMagnetoInternal__ifw_initialized = true;
    widget.complete = acceptCheckBox.checked;
}

Component.prototype.DynamicLicenseBundleWidgetCallback = function()
{
    var widget = gui.pageWidgetByObjectName("DynamicLicenseBundleWidget");
    Component.prototype.CMagnetoInternal__ifw_initializeLicenseBundleWidget(widget);
}

Component.prototype.CMagnetoInternal__ifw_licenseAcceptedToggled = function(checked)
{
    var widget = gui.pageWidgetByObjectName("DynamicLicenseBundleWidget");
    if (widget != null)
        widget.complete = checked;
}

Component.prototype.CMagnetoInternal__ifw_findLegalFile = function(installRel)
{
    for (var i = 0; i < CMagnetoInternal__ifw_legalFiles.length; ++i) {
        if (CMagnetoInternal__ifw_legalFiles[i].installRel === installRel)
            return CMagnetoInternal__ifw_legalFiles[i];
    }
    return null;
}

Component.prototype.CMagnetoInternal__ifw_htmlEscape = function(text)
{
    var escaped = text;
    escaped = escaped.replace(/&/g, "&amp;");
    escaped = escaped.replace(/</g, "&lt;");
    escaped = escaped.replace(/>/g, "&gt;");
    escaped = escaped.replace(/\"/g, "&quot;");
    return escaped;
}

Component.prototype.CMagnetoInternal__ifw_selectedLegalFileLinkChanged = function(url)
{
    var widget = gui.pageWidgetByObjectName("DynamicLicenseBundleWidget");
    if (widget == null)
        return;

    var legalFilesTreeBrowser = gui.findChild(widget, "legalFilesTreeBrowser");
    var selectedFilePathLabel = gui.findChild(widget, "selectedFilePathLabel");
    var licenseTextEdit = gui.findChild(widget, "licenseTextEdit");
    if (legalFilesTreeBrowser == null || selectedFilePathLabel == null || licenseTextEdit == null)
        return;

    var installRel = "";
    try {
        installRel = url.toString();
    } catch (e) {
        installRel = "" + url;
    }

    if (installRel == null || installRel === "") {
        selectedFilePathLabel.text = "Select a legal file from the tree.";
        licenseTextEdit.setPlainText("");
        return;
    }

    var legalFile = Component.prototype.CMagnetoInternal__ifw_findLegalFile(installRel);
    if (legalFile == null) {
        selectedFilePathLabel.text = installRel;
        licenseTextEdit.setPlainText("");
        return;
    }

    selectedFilePathLabel.text = installRel;
    licenseTextEdit.setPlainText(legalFile.text);
    legalFilesTreeBrowser.setHtml(Component.prototype.CMagnetoInternal__ifw_makeLegalFilesTreeHtml().html);
}

Component.prototype.CMagnetoInternal__ifw_makeLegalFilesTreeHtml = function()
{
    var htmlLines = [];
    htmlLines.push("<html><body style=\"font-family:'Segoe UI'; font-size:10pt;\">");
    htmlLines.push("<div style=\"font-family:'Consolas','Courier New',monospace; white-space:nowrap;\">");

    var emittedDirs = {};
    var firstInstallRel = "";
    for (var fileIndex = 0; fileIndex < CMagnetoInternal__ifw_legalFiles.length; ++fileIndex) {
        var legalFile = CMagnetoInternal__ifw_legalFiles[fileIndex];
        var parts = legalFile.installRel.split("/");
        var currentDirPath = "";
        for (var partIndex = 0; partIndex < parts.length - 1; ++partIndex) {
            currentDirPath = currentDirPath === "" ? parts[partIndex] : currentDirPath + "/" + parts[partIndex];
            if (!emittedDirs[currentDirPath]) {
                htmlLines.push("<div>" + new Array(partIndex * 4 + 1).join("&nbsp;")
                    + Component.prototype.CMagnetoInternal__ifw_htmlEscape(parts[partIndex]) + "/</div>");
                emittedDirs[currentDirPath] = true;
            }
        }

        var fileIndent = new Array((parts.length - 1) * 4 + 1).join("&nbsp;");
        var fileName = parts[parts.length - 1];
        htmlLines.push("<div>" + fileIndent
            + "<a href=\"" + Component.prototype.CMagnetoInternal__ifw_htmlEscape(legalFile.installRel) + "\">"
            + Component.prototype.CMagnetoInternal__ifw_htmlEscape(fileName) + "</a></div>");
        if (firstInstallRel === "")
            firstInstallRel = legalFile.installRel;
    }

    htmlLines.push("</div></body></html>");
    return {
        html: htmlLines.join(""),
        firstInstallRel: firstInstallRel
    };
}

Component.prototype.CMagnetoInternal__ifw_populateLegalFilesBrowser = function(widget)
{
    var treeData = Component.prototype.CMagnetoInternal__ifw_makeLegalFilesTreeHtml();
    var legalFilesTreeBrowser = gui.findChild(widget, "legalFilesTreeBrowser");
    var selectedFilePathLabel = gui.findChild(widget, "selectedFilePathLabel");
    var licenseTextEdit = gui.findChild(widget, "licenseTextEdit");
    if (legalFilesTreeBrowser == null || selectedFilePathLabel == null || licenseTextEdit == null)
        return;

    legalFilesTreeBrowser.setHtml(treeData.html);

    if (treeData.firstInstallRel !== "") {
        var firstLegalFile = Component.prototype.CMagnetoInternal__ifw_findLegalFile(treeData.firstInstallRel);
        selectedFilePathLabel.text = treeData.firstInstallRel;
        if (firstLegalFile != null)
            licenseTextEdit.setPlainText(firstLegalFile.text);
    } else {
        selectedFilePathLabel.text = "No legal files were provided by the selected bundle.";
        licenseTextEdit.setPlainText("");
    }
}
]=])
    set(${oScriptPath} "${_generatedScriptPath}" PARENT_SCOPE)
endfunction()
