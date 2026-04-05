# 3rdParty

This directory stores 3rd-party dependencies that are kept in the repository.

- `sources/` contains vendored 3rd-party source code that is compiled or included from source as part of the project build.
- `prebuilt/` contains 3rd-party binary artifacts that are stored in the repository when source builds are unavailable or impractical.

Recommended conventions:

- Keep project-owned code under `sources/`, not under `3rdParty/`.
- Keep generated build or install outputs out of `3rdParty/`; they belong in the build tree.
- For each dependency, document its upstream source, version, license, and update procedure near the dependency itself or in a dedicated metadata file.
- `VENDORED.md` is the recommended name for a per-dependency metadata note stored next to vendored content.
