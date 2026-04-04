# IFW Asset Guide

This directory contains assets used by the Qt Installer Framework (IFW) packaging flow.

The current wiring lives in:

- `SeedProject/CMagneto/cmake/Packager/IFW/IFWConfig_before_include_CPack.cmake`
- `SeedProject/CMagneto/cmake/Packager/IFW/IFWConfig.cmake`

## What is used today

Current CMake logic looks for these files:

- `PackageInstallerIcon.ico`
  Windows installer application icon.
  Wired to `CPACK_IFW_PACKAGE_ICON`.

- `PackageWindowIcon.png`
  Installer window/taskbar icon on Windows and Linux.
  Wired to `CPACK_IFW_PACKAGE_WINDOW_ICON`.

- `PackageWizardLogo.png`
  Small header logo.
  Wired to `CPACK_IFW_PACKAGE_LOGO`, which maps to `QWizard::LogoPixmap`.

- `PackageBanner.png`
  Used when present.
  Maps to `QWizard::BannerPixmap`.

- `PackageWatermark.png`
  Used when present.
  Maps to `QWizard::WatermarkPixmap`.

- `PackageBackground.png`
  Used when present.
  Maps to `QWizard::BackgroundPixmap`.

- `Installer.qss`
  Used today.
  Controls the installer colors and widget styling.

- `Welcome.html`
  Used today.
  Injected into the Introduction page by the generated control script.

- `Finished.html`
  Used today.
  Injected into the Finished page by the generated control script.

- `LicenseBundleWidget.ui`
  Used today.
  Loaded as a custom IFW page for the runtime component.

## Supporting fallback assets

- `PackageLogo.png`
  Fallback asset.
  Used if `PackageWindowIcon.png` or `PackageWizardLogo.png` is not available.

- `PackageLogo.ico`
  Fallback asset for `PackageInstallerIcon.ico`.

## Current behavior by platform

### Windows

Windows is the most explicitly configured platform today:

- wizard style is forced to `Modern`
- wizard size is forced to `860x560`
- title color is set explicitly
- `PackageInstallerIcon.ico` is used
- `PackageWindowIcon.png` is used
- `PackageWizardLogo.png` is used
- `PackageBanner.png` is used when present

Practical note:

- IFW shows the page list by default
- when the page list is visible, IFW hides `Watermark`
- therefore `PackageWatermark.png` is not worth creating unless page-list behavior changes

### Linux

Linux can use:

- `PackageWindowIcon.png`
- `PackageWizardLogo.png`
- `PackageBanner.png` if the active wizard style honors `BannerPixmap`
- `PackageWatermark.png` only if the page list is hidden

According to Qt IFW docs:

- `InstallerApplicationIcon` has no effect on Unix
- `InstallerWindowIcon` is used on Windows and Linux

### macOS

macOS is different:

- `InstallerWindowIcon` has no effect
- `Background` is only relevant for `MacStyle`
- the installer application icon should be an `.icns` asset

Important limitation in the current repo:

- current CMake only wires `PackageInstallerIcon.ico` on Windows
- a small CMake follow-up is still needed for IFW to pick up `PackageInstallerIcon.icns`

So the asset set below is designed to be cross-platform, but macOS still needs a small CMake follow-up if you want a custom installer app icon there.

## Recommended canonical asset set

This is the asset set worth keeping long-term.

### 1. `PackageInstallerIcon.ico`

Purpose:

- Windows installer executable icon

Format:

- `.ico`

Recommended content:

- same symbol as the app icon
- no tiny text
- transparent or clean solid background

Recommended sizes inside the `.ico`:

- `16x16`
- `24x24`
- `32x32`
- `48x48`
- `64x64`
- `128x128`
- `256x256`

Recommendation:

- keep

### 2. `PackageInstallerIcon.icns`

Purpose:

- macOS installer application icon

Format:

- `.icns`

Recommended source artwork:

- start from a `1024x1024` square master
- export a proper `.icns` set from that master

Recommended content:

- same symbol as `PackageInstallerIcon.ico`
- no text
- good contrast against light and dark macOS surfaces

Recommendation:

- add
- current CMake does not wire it yet, but this is the right cross-platform asset to prepare

### 3. `PackageWindowIcon.png`

Purpose:

- window/taskbar icon on Windows and Linux

Format:

- `.png`

Recommended size:

- `256x256`

Recommended proportions:

- square

Recommended content:

- same symbol as the app icon
- transparent background
- no text

Recommendation:

- keep

### 4. `PackageWizardLogo.png`

Purpose:

- header logo
- maps to `QWizard::LogoPixmap`

Format:

- `.png`

Recommended size:

- `96x96` minimum
- `128x128` preferred if remade from scratch

Recommended proportions:

- square or slightly portrait
- transparent background

Recommended content:

- compact mark or very short lockup
- do not put a long wordmark here
- must read well on the light beige background used by `Installer.qss`

Recommendation:

- keep, but remaking it at `128x128` is reasonable

### 5. `PackageBanner.png`

Purpose:

- header banner in `ModernStyle`
- maps to `QWizard::BannerPixmap`

Format:

- `.png`

Recommended size for current Windows wizard:

- `860x84`
- `860x96`

Recommended proportions:

- very wide horizontal strip

Recommended content:

- subtle branded background, not a poster
- keep the left side calm enough for page title/subtitle
- keep the right side compatible with the separate logo pixmap
- avoid dense detail and avoid putting important text into the image

Recommendation:

- worth adding

### 6. `PackageBackground.png`

Purpose:

- full background image for `MacStyle`
- maps to `QWizard::BackgroundPixmap`

Format:

- `.png`

Recommended size:

- `860x560` if you want to match the current Windows wizard size
- larger is acceptable if exported cleanly, but avoid oversized files

Recommended proportions:

- landscape, matching the wizard window

Recommended content:

- soft, low-contrast background art
- no text
- avoid busy areas behind controls

Recommendation:

- useful for macOS readiness

### 7. `PackageWatermark.png`

Purpose:

- left-side artwork for `ClassicStyle` and `ModernStyle`
- maps to `QWizard::WatermarkPixmap`

Format:

- `.png`

Recommended size:

- around `180x460`
- or any similar tall ratio

Recommended proportions:

- tall portrait strip

Important note:

- IFW hides the watermark while the page list is visible
- because the page list is visible by default, this asset is usually not seen in the current setup

Recommendation:

- optional
- do not spend time on it unless page-list behavior changes

## Cross-platform asset strategy

If the goal is one clean asset set that works well across Windows, Linux, and macOS, use this baseline:

- `PackageInstallerIcon.ico`
- `PackageInstallerIcon.icns`
- `PackageWindowIcon.png`
- `PackageWizardLogo.png`
- `PackageBanner.png`
- `PackageBackground.png`

That gives:

- Windows: app icon, window icon, header logo, banner
- Linux: window icon, header logo, likely banner
- macOS: app icon after CMake support is added, background image for `MacStyle`, header logo where applicable

## Recommended visual direction

The existing `Installer.qss` already establishes a visual theme:

- background: warm paper-like beige `#f5f1e8`
- text: dark brown `#1f1a14`
- accent: teal `#1e9696`

To match that theme, the image assets should probably look like this:

- icons:
  one simple symbol based on contact cards, an address-book tab, initials, or a stylized person/contact glyph

- wizard logo:
  compact mark only, or mark plus a very short lockup

- banner:
  soft teal-and-paper gradient, maybe with subtle card/tab geometry
  no text baked into the bitmap

- background:
  even softer version of the banner language, with large quiet shapes and very low contrast

## Cleanup target

After the asset set is normalized, this directory should ideally contain:

- `Finished.html`
- `Installer.qss`
- `LicenseBundleWidget.ui`
- `PackageBanner.png`
- `PackageBackground.png`
- `PackageInstallerIcon.icns`
- `PackageInstallerIcon.ico`
- `PackageLogo.ico`
- `PackageLogo.png`
- `PackageWindowIcon.png`
- `PackageWizardLogo.png`
- `Welcome.html`

The parent `packaging/@resources/` directory should also contain:

- `ApplicationMenu.json`

Optional:

- `PackageWatermark.png`

## ApplicationMenu.json

`../ApplicationMenu.json` configures packaging-wide application-menu placement.

Current fields:

- `WindowsStartMenuDirectory`
  Name of the Start Menu folder used by IFW on Windows.

Notes:

- Individual menu entries are not configured in JSON. They are registered in CMake with `CMagneto__add_executable_to_application_menu(...)` or `CMagneto__add_installed_file_to_application_menu(...)`.
- IFW currently uses these registrations to create Start Menu shortcuts on Windows.
- If a registered item provides `WINDOWS_ICON`, CMagneto installs that icon asset and points the shortcut at it.
- Otherwise the shortcut uses the target file's default associated icon.
- ZIP packages do not create Start Menu entries.

## Small code follow-ups that would improve cross-platform behavior

These are not asset tasks, but they are worth remembering:

1. Add macOS wiring for `PackageInstallerIcon.icns`.
2. Decide whether Linux and macOS should keep platform-default wizard styles or use an explicitly chosen style.
3. If the page list stays enabled and branded artwork is wanted there, consider adding support for IFW `PageListPixmap`.

## References

- Qt Installer Framework global configuration:
  `https://doc.qt.io/qtinstallerframework/ifw-globalconfig.html`
- Qt `QWizard` pixmap roles:
  `https://doc.qt.io/qt-6/qwizard.html`
