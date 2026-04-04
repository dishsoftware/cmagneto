# Testing In CMagneto

CMagneto configures the project's `./tests/` tree as part of the CMake project,
but test targets are added with `EXCLUDE_FROM_ALL`.

That means:
- test targets are known to CMake;
- helper targets such as `build_tests` and helper scripts such as `run_tests`
  are generated;
- tests are not built as part of the normal default application build.

## Does Enabling Tests Slow Down The Built Application?

Usually no.

Enabling tests in a CMagneto-based project does not, by itself, inject test code
or extra test instructions into normal production binaries.

The typical setup is:
- application and library targets are defined under `./src/`;
- test executables are defined separately under `./tests/`;
- the optional Python build frontend builds tests only when the `CompileTests`
  or `RunTests` stages are requested.

As a result:
- runtime performance of the final application is not degraded just because
  tests are enabled in the project;
- normal non-test builds are not forced to compile test executables;
- enabling tests does add some configure-time overhead, because the `./tests/`
  subtree is still processed by CMake and GoogleTest may be found or fetched.

## What Actually Adds Overhead To Production Binaries?

Extra instructions in production binaries usually come from other features, for
example:
- code coverage instrumentation;
- sanitizers;
- debug-only tracing or assertions deliberately compiled into production targets;
- custom test-specific compile definitions attached to non-test targets.

In CMagneto, the clearest example is coverage mode enabled through `build.py`
with `--coverage`. That instrumentation is separate from merely enabling tests.

## Practical Summary

- Tests enabled in the project: small configure-time overhead.
- Tests compiled: more build time and disk usage.
- Tests run: additional execution time.
- Final application runtime: normally unchanged.
