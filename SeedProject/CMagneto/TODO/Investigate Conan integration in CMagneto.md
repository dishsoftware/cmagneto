```markdown
## Investigate Conan integration in CMagneto

### Goal
Understand how Conan can complement (not replace) CMagneto for dependency management and toolchain setup.

### Key idea
- **CMagneto** → project structure, CMake architecture, conventions
- **Conan** → dependencies, toolchain, compiler settings, packaging support

### Tasks
- Create a minimal CMagneto project with Conan
- Test `CMakeToolchain` + `CMakeDeps`
- Try real deps (e.g. Qt + zlib)
- Check DLL/.so collection for deployment
- Compare:
  - CMagneto only vs CMagneto + Conan
- Evaluate CI impact (GitLab CI)

### Decision
Define clear boundary:
> CMagneto = architecture
> Conan = dependencies + environment

Decide:
- optional vs built-in support
- what logic to keep vs delegate
```
