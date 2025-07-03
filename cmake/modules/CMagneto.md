<!--
Copyright (c) 2025 Dmitrii Shvydkoi ("Dim Shvydkoy")
SPDX-License-Identifier: MIT

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
-->

# CMagneto CMake Module
## General CMake Knowledge
Why was this section even added?

A developer seldom sets up projects - starting from scratch is even rarer. As a result, deep CMake knowledge is unlikely to land into a developer's procedural memory. The situation is aggravated by how extremely unintuitive CMake is as a language: ask someone unfamiliar with it, what `CMAKE_CURRENT_LIST_DIR` and `CMAKE_CURRENT_SOURCE_DIR` variables are or try to use a comma-containing string variable in a generator expression.<br>

At the same time, the [`official CMake documentation`](https://cmake.org/documentation/) **sucks**. At best, it helps clarify minor details - like function arguments and options - but beyond that, it’s practically useless. There’s little to no explanation of how features are intended to be used or what the recommended practices are. And I can't say any other material I've come across, devoted to CMake, is good enough either. I recommend [`Scott C. Professional CMake: A Practical Guide [Internet]. 2018`](https://crascit.com/professional-cmake/). But even after reading the book, a developer still needs to vigorously experiment, google, and chat with AI bots to figure out how things actually work. And I hate that. I want clear, concise instructions all in one place and available offline. At least, this section covers the major sources of confusion.


## CMake variables
### `CMAKE_CURRENT_LIST_DIR`, `CMAKE_CURRENT_SOURCE_DIR` and `CMAKE_SOURCE_DIR`
Consider these variables not as variables, but rather as getter functions: their returned values vary depending on the call context without explicit reassignment.

`CMAKE_CURRENT_LIST_DIR`<br>
**Definition**: The directory of the currently parsed CMake file, which can be a `CMakeLists.txt` or any included `.cmake` file or script.<br>
**Scope**: changes whenever<br>
1) CMake enters a new file, including modules or scripts included by include() or find_package();
2)  `CMAKE_CURRENT_LIST_DIR` is evaluated in file outside of a function.<br>
    If `CMAKE_CURRENT_LIST_DIR` is evaluated in a function, it evaluates to the directory of a file where the function is called (recursively).<br>

**Typical use**: To refer to the directory of the script file currently being executed, often used inside .cmake modules to locate helper files or resources relative to the module.

`CMAKE_CURRENT_SOURCE_DIR`<br>
**Definition**: The directory where the currently processed CMakeLists.txt file is located.<br>
**Scope**: Changes when CMake processes a new CMakeLists.txt via `add_subdirectory()` or similar.<br>
**Typical use**: To refer to the current source directory of the build, usually the directory of the current subproject or subdirectory being configured.

`CMAKE_SOURCE_DIR` equals `CMAKE_CURRENT_SOURCE_DIR`, if:
1) The project is not nested within a parent project directory (the project is the top level project);
2) Even if the project is nested within a parent project directory, the nested project is considered top level, if:
    * 2.1) CMake is run from the nested project root directory;
    * 2.2) The parent project calls `ExternalProject_Add()` to add the nested project.

Proper names that should have been used instead of the confusing-as-hell CMake variable names mentioned above:<br>
`CMAKE_CURRENT_LIST_DIR`   is `CMAKE_CURRENT_SCRIPT_DIR`.<br>
`CMAKE_CURRENT_SOURCE_DIR` is `CMAKE_CURRENT_CMAKELISTS_DIR`.<br>
`CMAKE_SOURCE_DIR `        is `CMAKE_ROOT_CMAKELISTS_DIR`.<br>


## CMake Commands
### Setting Up A Target
#### `PRIVATE`, `INTERFACE` and `PUBLIC`
In CMake, the keywords `PRIVATE`, `INTERFACE`, and `PUBLIC` control the propagation of properties such as sources, include directories, compile definitions, and compile options between targets:
- `PRIVATE`: The property is used only when compiling the target itself. It is not exposed to consumers of the target.
- `INTERFACE`: The property is not used when compiling the target, but is used by targets that link against the target.
- `PUBLIC`: The property is used both when compiling the target and when compiling consumers that link against the target.
In other words, PUBLIC is effectively a union of `PRIVATE` and `INTERFACE`.

#### Adding source files to an existing target
```cmake
target_sources(${iLibName}
    PUBLIC
        $<BUILD_INTERFACE:${iPublicHeadersAbsolutePaths}>
        # Absolute path means something like $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/algo.h>.
        # See https://crascit.com/2016/01/31/enhanced-source-file-handling-with-target_sources/ .
        $<INSTALL_INTERFACE:${iPublicHeaders}>
    INTERFACE
        $<BUILD_INTERFACE:${iInterfaceHeaders}>
        $<INSTALL_INTERFACE:${iInterfaceHeaders}>
    PRIVATE
        $<BUILD_INTERFACE:${iPrivateHeaders}>
        $<BUILD_INTERFACE:${iSources}>
        # iSources should always be PRIVATE, because they are part of library's internal implementation, not its public interface.
        # When to mark .cpp as PUBLIC sources:
        # 1) You want them to appear in IDEs under both iLibName and consumer targets;
        # 2) You want to share source files across multiple libraries and compile them in multiple targets.
)
```


| A file marked with a keyword | Compiled into iLibName | Shown in IDE as a file of iLibName | Shown in IDE as a file of consumer targets within the same project | Exported via `install(EXPORT)` [^1] | Compiled by consumers [^2] |
| ----------- | ---------- | --------- | ---------- | ---------- | -----------------------|
| `PRIVATE`   | ✅ Yes    | ✅ Yes    | ❌ No     | ❌ No      | ❌ No                  |
| `PUBLIC`    | ✅ Yes    | ✅ Yes    | ✅ Yes    | ✅ Yes     | ❌ No                  |
| `INTERFACE` | ❌ No     | ❌ No     | ✅ Yes    | ✅ Yes     | ❌ Yes, if `#include`d |

[^1]: Compilation, installed files, and included paths are not affected. Essentially, `INTERFACE` or `PUBLIC` file is shown in IDEs as a file of consumer targets within consumer projects.<br>
A BS-explanation: a metadata, added to *Config.cmake files, if a file is marked is marked with `INTERFACE` or `PUBLIC`, is used only by CMake-aware IDEs and tooling for display/navigation purposes.

[^2]: Depends on what functions are in the header:
| Function in header                       | Compiled by         | Safe? | Note                                                                   |
| ---------------------------------------- | ------------------- | ----- | ---------------------------------------------------------------------- |
| Template                                 | Consumer            | ✅   | Must be header-defined                                                 |
| Inline non-template                      | Consumer            | ✅   | One (same signature) definition allowed across translation units (TUs) |
| Static non-template                      | Consumer            | ✅   | Separate copy per TU                                                   |
| Regular non-template (not inline/static) | Consumer & iLibName | ❌   | Causes multiple definitions — **don't do this**                        |

or what class methods are in the header:
| Method in header                          | Compiled by                   | Safe? | Notes                                                      |
| ----------------------------------------- | ----------------------------- | ----- | ---------------------------------------------------------- |
| Class declaration (no method definitions) | iLibName                      | ✅   | Header-only declarations are fine                          |
| Class with inline method definitions      | Consumer                      | ✅   | Like inline functions — must be same across TUs            |
| Class with template method definitions    | Consumer                      | ✅   | Must be header-only (or explicitly instantiated elsewhere) |
| Class with non-inline method definitions  | ❌ Linker error if in header | ❌   | Multiple definitions across TUs — ODR violation            |
| Class with only static methods in header  | Consumer                      | ✅   | Each TU gets its own copy (like static functions)          |
