# SeedProject System Tests

This directory is reserved for system-level test drivers and scripts.

Typical checks here exercise workflows around the project rather than a single
native test binary, for example:

- configure/build/install smoke checks;
- linking an external fixture project against the installed package;
- runtime packaging checks.

Fixture projects for these scripts belong under `../@TestProjects/`.
