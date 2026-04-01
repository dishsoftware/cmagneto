"""
linux_package_verifier.py

Linux package verification helpers used by the presets-first build flow.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import cast
import json
import re
import shutil
import tarfile

from CMagneto.py.cmake.build_platform import BuildPlatform
from CMagneto.py.metadata_holder import MetadataHolder
from CMagneto.py.utils.log import Log
from CMagneto.py.utils.process import Process


class ExternalSharedLibraryInstallMode(Enum):
    EXPECT_ON_TARGET_MACHINE = "EXPECT_ON_TARGET_MACHINE"
    BUNDLE_WITH_PACKAGE = "BUNDLE_WITH_PACKAGE"


@dataclass(frozen=True)
class _ExternalSharedLibraryDeploymentEntry:
    importedTargetName: str
    paths: tuple[Path, ...]


@dataclass(frozen=True)
class _ExtractedLinuxPackage:
    packagePath: Path
    extractDir: Path
    installRoot: Path


def verifyGeneratedLinuxPackages(
    iBuildDir: Path,
    iExeDir: Path,
    iBuildTypeName: str,
    iPackagesSubDir: Path,
    iExecutableSubDir: Path,
    iSharedLibSubDir: Path,
    iRuntimeDependencyManifestFileName: str
) -> None:
    """Extract generated Linux packages and verify external shared-library deployment policy."""
    if BuildPlatform().hostOS() != BuildPlatform.OS.Linux:
        return

    deploymentEntriesByMode = _loadRuntimeDependencyManifestDeploymentEntries(iExeDir, iRuntimeDependencyManifestFileName)
    if all(not deploymentEntries for deploymentEntries in deploymentEntriesByMode.values()):
        return

    text = f"Verifying generated packages ({iBuildTypeName})"
    Log.status(text + "...")

    packagesDir = iBuildDir / iPackagesSubDir
    extractedPackages = _extractSupportedLinuxPackages(packagesDir)
    if not extractedPackages:
        Log.error(f"No supported Linux packages with runtime payload were found in \"{packagesDir}\".")

    for extractedPackage in extractedPackages:
        _verifyExternalSharedLibrariesInLinuxPackage(
            extractedPackage,
            deploymentEntriesByMode,
            iExecutableSubDir,
            iSharedLibSubDir
        )

    Log.status(text + " finished.\n")


def _loadRuntimeDependencyManifestDeploymentEntries(
    iExeDir: Path,
    iRuntimeDependencyManifestFileName: str
) -> dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]]:
    """Load imported shared-library deployment expectations from the canonical runtime dependency manifest."""
    manifestPath = iExeDir / iRuntimeDependencyManifestFileName
    if not manifestPath.exists():
        Log.warning(f"Runtime dependency manifest file was not found: \"{manifestPath}\".")
        return {
            ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE: tuple(),
            ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE: tuple()
        }

    with manifestPath.open("r", encoding="utf-8") as manifestFile:
        manifest = json.load(manifestFile)

    if not isinstance(manifest, dict):
        Log.error(f"Invalid runtime dependency manifest file: \"{manifestPath}\".")
    manifestDict = cast(dict[str, object], manifest)

    rawImportedSharedLibraries = manifestDict.get("ImportedSharedLibraries", [])
    if not isinstance(rawImportedSharedLibraries, list):
        Log.error(f"Invalid ImportedSharedLibraries section in \"{manifestPath}\".")
    importedSharedLibraries = cast(list[object], rawImportedSharedLibraries)

    entriesByMode: dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]] = {}
    for installMode in ExternalSharedLibraryInstallMode:
        parsedEntries: list[_ExternalSharedLibraryDeploymentEntry] = []
        for rawEntry in importedSharedLibraries:
            if not isinstance(rawEntry, dict):
                Log.error(f"Invalid imported shared-library entry in \"{manifestPath}\": {rawEntry!r}.")
            rawEntryDict = cast(dict[str, object], rawEntry)

            importedTargetName = rawEntryDict.get("ImportedTarget")
            rawInstallMode = rawEntryDict.get("InstallMode")
            rawPaths = rawEntryDict.get("Paths")
            if not isinstance(importedTargetName, str):
                Log.error(f"Invalid imported target name in \"{manifestPath}\": {rawEntry!r}.")
            if not isinstance(rawInstallMode, str):
                Log.error(f"Invalid install mode in \"{manifestPath}\": {rawEntry!r}.")
            if not isinstance(rawPaths, list):
                Log.error(f"Invalid imported target paths in \"{manifestPath}\": {rawEntry!r}.")
            if rawInstallMode != installMode.value:
                continue

            rawPathList = cast(list[object], rawPaths)
            pathListItems: list[str] = []
            for rawPath in rawPathList:
                if not isinstance(rawPath, str):
                    Log.error(f"Invalid imported target path item in \"{manifestPath}\": {rawEntry!r}.")
                pathListItems.append(rawPath)
            pathList = tuple(pathListItems)

            parsedEntries.append(
                _ExternalSharedLibraryDeploymentEntry(
                    importedTargetName=importedTargetName,
                    paths=tuple(Path(path) for path in pathList)
                )
            )

        entriesByMode[installMode] = tuple(parsedEntries)

    return entriesByMode


def _linuxPackageInstallPrefixRelativePath() -> Path:
    """Return the runtime payload root inside Linux packages generated by the current project metadata."""
    companyNameShort = MetadataHolder().getMetadataValue(Path("./Project.json"), ["CompanyName_SHORT"])
    projectNameBase = MetadataHolder().getMetadataValue(Path("./Project.json"), ["ProjectNameBase"])
    if not (isinstance(companyNameShort, str) and isinstance(projectNameBase, str)):
        Log.error("linux_package_verifier: can't get required project metadata for package verification.")

    return Path("opt") / companyNameShort / projectNameBase


def _extractSupportedLinuxPackages(iPackagesDir: Path) -> tuple[_ExtractedLinuxPackage, ...]:
    """Extract supported Linux package formats and return only packages that contain the runtime payload."""
    installPrefixRelativePath = _linuxPackageInstallPrefixRelativePath()
    extractionRoot = iPackagesDir / ".tmp" / "package_verification"

    extractedPackages: list[_ExtractedLinuxPackage] = []
    for packagePath in sorted(iPackagesDir.rglob("*")):
        if not packagePath.is_file():
            continue
        if "_CPack_Packages" in packagePath.parts:
            continue
        if not (
            packagePath.name.endswith(".deb") or
            packagePath.name.endswith(".tgz") or
            packagePath.name.endswith(".tar.gz")
        ):
            continue

        extractDir = extractionRoot / packagePath.name
        _extractLinuxPackage(packagePath, extractDir)

        installRoot = extractDir / installPrefixRelativePath
        if not installRoot.exists():
            Log.warning(f"Skipping package without runtime payload at \"{installPrefixRelativePath}\": \"{packagePath}\".")
            continue

        extractedPackages.append(
            _ExtractedLinuxPackage(
                packagePath=packagePath,
                extractDir=extractDir,
                installRoot=installRoot
            )
        )

    return tuple(extractedPackages)


def _extractLinuxPackage(iPackagePath: Path, iExtractDir: Path) -> None:
    """Extract one supported Linux package into iExtractDir."""
    if iExtractDir.exists():
        shutil.rmtree(iExtractDir)
    iExtractDir.mkdir(parents=True, exist_ok=True)

    if iPackagePath.name.endswith(".deb"):
        Process.runCommand(["dpkg-deb", "-x", str(iPackagePath), str(iExtractDir)])
        return

    if iPackagePath.name.endswith(".tgz") or iPackagePath.name.endswith(".tar.gz"):
        with tarfile.open(iPackagePath, "r:*") as packageArchive:
            packageArchive.extractall(iExtractDir)
        return

    Log.error(f"Unsupported Linux package format: \"{iPackagePath}\".")


def _verifyExternalSharedLibrariesInLinuxPackage(
    iExtractedPackage: _ExtractedLinuxPackage,
    iDeploymentEntriesByMode: dict[ExternalSharedLibraryInstallMode, tuple[_ExternalSharedLibraryDeploymentEntry, ...]],
    iExecutableSubDir: Path,
    iSharedLibSubDir: Path
) -> None:
    """Check that bundled and externally provided shared libraries resolve as configured inside one extracted package."""
    elfFiles = (
        *_findElfFilesUnder(iExtractedPackage.installRoot / iExecutableSubDir),
        *_findElfFilesUnder(iExtractedPackage.installRoot / iSharedLibSubDir)
    )
    if not elfFiles:
        Log.warning(f"Skipping package verification because no ELF runtime files were found in \"{iExtractedPackage.packagePath}\".")
        return

    packagedFilesByName: dict[str, set[Path]] = {}
    for packagedFile in iExtractedPackage.installRoot.rglob("*"):
        if not packagedFile.is_file():
            continue
        packagedFilesByName.setdefault(packagedFile.name, set()).add(packagedFile)

    resolvedLibrariesByName = _collectResolvedLinuxSharedLibraries(tuple(elfFiles), iExtractedPackage.packagePath)

    for deploymentEntry in iDeploymentEntriesByMode[ExternalSharedLibraryInstallMode.BUNDLE_WITH_PACKAGE]:
        candidateLibraryNames = _sharedLibraryNamesForPaths(deploymentEntry.paths)
        packagedPaths = _pathsForLibraryNames(candidateLibraryNames, packagedFilesByName)
        if not packagedPaths:
            Log.error(
                f"Bundled imported shared library \"{deploymentEntry.importedTargetName}\" is missing from package "
                f"\"{iExtractedPackage.packagePath}\". Expected one of: {sorted(candidateLibraryNames)}."
            )

        resolvedPaths = _pathsForLibraryNames(candidateLibraryNames, resolvedLibrariesByName)
        if not any(resolvedPath.is_relative_to(iExtractedPackage.installRoot) for resolvedPath in resolvedPaths):
            Log.error(
                f"Bundled imported shared library \"{deploymentEntry.importedTargetName}\" was not resolved from within "
                f"the extracted package \"{iExtractedPackage.packagePath}\"."
            )

    for deploymentEntry in iDeploymentEntriesByMode[ExternalSharedLibraryInstallMode.EXPECT_ON_TARGET_MACHINE]:
        candidateLibraryNames = _sharedLibraryNamesForPaths(deploymentEntry.paths)
        packagedPaths = _pathsForLibraryNames(candidateLibraryNames, packagedFilesByName)
        if packagedPaths:
            Log.error(
                f"Imported shared library \"{deploymentEntry.importedTargetName}\" is expected on the target machine, "
                f"but package \"{iExtractedPackage.packagePath}\" contains {sorted(str(path) for path in packagedPaths)}."
            )

        resolvedPaths = _pathsForLibraryNames(candidateLibraryNames, resolvedLibrariesByName)
        if not any(not resolvedPath.is_relative_to(iExtractedPackage.installRoot) for resolvedPath in resolvedPaths):
            Log.error(
                f"Imported shared library \"{deploymentEntry.importedTargetName}\" was expected to resolve outside the "
                f"package \"{iExtractedPackage.packagePath}\", but no such resolution was observed."
            )


def _findElfFilesUnder(iRoot: Path) -> tuple[Path, ...]:
    """Return ELF files found recursively under iRoot."""
    if not iRoot.exists():
        return tuple()

    elfFiles: list[Path] = []
    for path in sorted(iRoot.rglob("*")):
        if not path.is_file():
            continue
        try:
            with path.open("rb") as binaryFile:
                if binaryFile.read(4) == b"\x7fELF":
                    elfFiles.append(path)
        except OSError:
            continue

    return tuple(elfFiles)


def _collectResolvedLinuxSharedLibraries(iElfFiles: tuple[Path, ...], iPackagePath: Path) -> dict[str, set[Path]]:
    """Run ldd for packaged ELF files and collect resolved shared libraries by library name."""
    resolvedLibrariesByName: dict[str, set[Path]] = {}
    for elfFile in iElfFiles:
        lddOutput = Process.runCommand(["ldd", str(elfFile)], iCaptureOutput=True, iCheck=False)
        assert lddOutput is not None

        for line in lddOutput.stdout.splitlines():
            if "=>" not in line:
                continue

            libraryName, resolvedPart = line.split("=>", maxsplit=1)
            libraryName = libraryName.strip()
            resolvedPathStr = resolvedPart.split("(", maxsplit=1)[0].strip()
            if resolvedPathStr == "not found":
                Log.error(f"Shared library \"{libraryName}\" required by \"{elfFile}\" was not resolved in package \"{iPackagePath}\".")
            if resolvedPathStr == "":
                continue

            resolvedLibrariesByName.setdefault(libraryName, set()).add(Path(resolvedPathStr))

    return resolvedLibrariesByName


def _sharedLibraryNamesForPaths(iPaths: tuple[Path, ...]) -> set[str]:
    """Return possible runtime names for shared-library files, including SONAME values when available."""
    sharedLibraryNames: set[str] = set()
    for path in iPaths:
        sharedLibraryNames.add(path.name)
        if path.exists():
            sharedLibraryNames.add(path.resolve().name)

            sonameOutput = Process.runCommand(["readelf", "-d", str(path)], iCaptureOutput=True, iCheck=False)
            assert sonameOutput is not None
            for line in sonameOutput.stdout.splitlines():
                match = re.search(r"Library soname: \[(.+)\]", line)
                if match is not None:
                    sharedLibraryNames.add(match.group(1))
                    break

    return sharedLibraryNames


def _pathsForLibraryNames(iLibraryNames: set[str], iPathsByName: dict[str, set[Path]]) -> set[Path]:
    """Return all paths whose file names match any name from iLibraryNames."""
    matchedPaths: set[Path] = set()
    for libraryName in iLibraryNames:
        matchedPaths.update(iPathsByName.get(libraryName, set()))
    return matchedPaths
