<!--
Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

![Framework Banner](./SeedProject/CMagneto/doc/assets/header/Header.jpg)
# CMagneto Framework

<!--
Note for developers

Keep this snippet in sync with the same snippets in
- CMagneto project root README.md;
- CMagneto framework root README.md;
- project desciption on GitLab, GitHub, BitBucket etc.
-->
CMagneto is a framework for rapid initialization of C++ projects.<br>
It is designed to set up CMake-backed projects with ease and enforce a unified modular structure, build logic, and tooling integration,<br>
including VS Code, Graphviz, Qt, GoogleTest, LCOV, CPack, Docker and GitLab CI.

🔗 GitLab repository: [gitlab.com/dishsoftware/cmagneto](https://gitlab.com/dishsoftware/cmagneto)<br>
🔗 GitHub mirror: [github.com/dishsoftware/cmagneto](https://github.com/dishsoftware/cmagneto)


## Structure of the repository
- The framework code is mixed with a code of a seed (template) project under [`./SeedProject/`](./SeedProject/).
- Core files of the CMagneto framework is in [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/).

This file is a proxy for the actual [CMagneto framework README.md](./SeedProject/CMagneto/README.md).


## Glossary
- `CMagneto project root (dir)` - [this (`./`)](.) dir.
- `Seed project root (dir)` - [`./SeedProject/`](./SeedProject/) dir.
-  In all files under the [`seed project root`](./SeedProject/) itself is referred to as `project root (dir)`.
- `CMagneto framework root (dir)` - [`./SeedProject/CMagneto/`](./SeedProject/CMagneto/) dir.
- `Test project root (dir)` - [dir with a test project under `./tests/testProjects/`](./tests/testProjects/).
- `CMagneto framework root (dir) of the project` in context of a test project is `./CMagneto/` subdir inside the `test project root`.


## License
Look into [`License` section of CMagneto framework `README.md`](./SeedProject/CMagneto/README.md#license).<br>
The license file [`./LICENSE`](./LICENSE) and the license file [`./SeedProject/CMagneto/LICENSE`](./SeedProject/CMagneto/LICENSE) are identical.


## Git History Policy
Avoid resetting even non-protected branches, except when fixing trivial issues (e.g., typos in recent commits).<br>
Preserving full commit history — including mistakes and work-in-progress — serves several important purposes:
* 🛡 **Protect against fraudulent forks or mirrors**: If history is rewritten, bad actors could replicate the project, strip or rewrite authorship, and falsely claim original ownership or prior invention.
* 🧠 **Document the development process**: Mistakes and revisions are part of real-world software development. Keeping them in the history shows how decisions evolved.
* 📊 **Communicate progress transparently**: The Git log itself reflects the status and evolution of a feature, reducing reliance on external tracking tools.

In short: **commit freely, but rewrite with caution**. Let the repo tell the whole story.
