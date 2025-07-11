# Code Conventions


## 1. CMake Conventions
### 1.1. CMake Naming Conventions
- File of a module: `cmake/ModuleName.cmake`.
- File of a module's submodule: `cmake/ModuleName/SubModule.cmake`.
- File of a module's submodule with internal functions, constants and variables,<br>
  intended for usage only within the module: `cmake/ModuleName/SubModule_Internals.cmake`.
- Script file: `script_file.cmake`.
- Function in a module: `ModuleName__function_name`.
- Function in a module, intended for usage only within the module: `ModuleNameInternal__function_name`.
- Variable in a module, outside of function: `ModuleName__VarName`.
- Constant in a module, outside of function: `ModuleName__CONST_NAME`.
- Variable in a module, outside of function, intended for usage only within the module: `ModuleNameInternal__VarName`.
- Constant in a module, outside of function, intended for usage only within the module: `ModuleNameInternal__CONST_NAME`.
- Parameters of functions:
    * Purely input parameter: `iParamName`.
    * Purely output parameter: `oParamName`.
- Variable in a function, macro, script or CMakeLists.txt: `_varName` or `_VarName`.
- Constant in a function, macro, script or CMakeLists.txt: `_CONST_NAME`.
- **Names must start according to the conventions, and may be appended with anything after a trailing `_`**.
  E.g. `CMagneto__find__Qt_TOOL_EXE`, `_Qt_TOOL_EXE`, `CMagnetoInternal__PathsToSharedLibs__GUI` are also fine.


## 2. Python Conventions
### 2.1. Python Naming Conventions
- Module (file) name: `module_name.py`.
    > **Note:** CMagneto framework Python files are under `CMagneto/py/` dir.<br>
    > Thus, import names of CMagneto Python packages are `CMagneto.py.*` and are exceptions from this convention.
- Class, struct, enum: `ClassName`.
- Protected member of a class: prepended with `__`.
- Private member of a class: prepended with `_`.
- Non-static field of a class/struct: `classFieldName`.
- Static non-const field of a class/struct: `sClassFieldName`.
- Static const field of a class/struct, enum option, const standalone variable: `CONST_NAME`.
- Standalone non-const variable: `varName`.
- Function's/method's parameter:
    * Purely input parameter: `iParamName`.
    * Purely output parameter: `oParamName`.
    * Parameter that serves as both input and output: `ioParamName`.
- Standalone function or class'/struct' method (static or regular): `functionName`.

### 2.2. `import` And `from` Directives Order And Blank Lines
- Sort lexicographically.
- Python file example:
    ```python
    # License text.

    """
    Module doc.
    """

    from typing import cast
    import inspect


    # Actual code (functions, classes, vars and consts) are separated from `import` section with 2 blank lines.
    class Outer:
        """Classes, even inners ones, are separated with two blank lines from anything which is not field or method of the class."""


        class Inner:
            __sInstance = None

            def __new__(cls):
                if cls.__sInstance is None:
                    cls.__sInstance = super().__new__(cls)
                    cls.__sInstance.__initialized = False
                return cls.__sInstance

            def __init__(self):
                if self.__initialized:
                    return
                self.__initialized = True

    ```

### 2.3. Types
- Use type hints consistently across function signatures, class attributes, and variables. Prefer explicit typing over relying on inference, especially in public APIs.
- All code must pass static type checking in VS Code with the setting:
    ```json
    "python.analysis.typeCheckingMode": "standard"
    ```
- Use `mypy` or `pyright` (the engine behind VS Code’s type checker) to ensure compatibility and catch type errors early.
- Annotate all function arguments and return types, including those for lambda functions where applicable.
- For variables with complex or unclear types, prefer explicit annotations:
    ```python
    users: list[User] = []
    config: dict[str, Any] = dict()
    ```
- Use `T | None` instead of leaving values implicitly nullable.
- Avoid `Any` unless necessary. If unavoidable, isolate its use and document the reasoning.
- Prefer `collections.abc` interfaces (`Iterable`, `Mapping`, etc.) over concrete types like `list`, `dict`, when only behavior is required.


## 3. C++ Conventions
- Place sources of a module under `./src/{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/`.
- The project endorses inclusions of headers of other modules within the project as:
  ```c++
  #include "{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp"
  ```
  and inclusions in consumer projects as:
   ```c++
  #include <{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp>
  ```
- The [`CMagneto CMake module imposes restrictions on locations of files`](./../README.md#project-structure).

### 3.1. C++ Naming Conventions
- Target/module (library, executable): `ModuleName`.
- Class, struct, enum: `ClassName`.
- Non-static field of a class/struct: `mClassFieldName`.
- Static non-const field of a class/struct: `sClassFieldName`.
- Static const field of a class/struct, enum option, const standalone variable: `kConstName`.
- Standalone non-const variable: `varName`.
- Function's/method's parameter:
    * Purely input parameter: `iParamName`.
    * Purely output parameter: `oParamName`.
    * Parameter that serves as both input and output: `ioParamName`.
- Standalone function or class'/struct' method (static or regular): `functionName`.
- Namespace:
    * Namespaces, encapsulating entities of a module, are composed as: `{CompanyName_SHORT}::{ProjectNameBase}::{ModuleName}`.
        ```c++
        namespace Enow::ContactHolder::GUI {
            ...
        } // namespace Enow::ContactHolder::GUI
        ```
    * Namespace, encapsulating `enum class Enum` or its helper functions: CamelCase.
        ```c++
        namespace Enow::ContactHolder::Contacts::FieldType {
            enum class CONTACTS_EXPORT Enum : std::uint8_t {
                kString, // Generic string without restrictions.
                kPhoneNumber
            };

            CONTACTS_EXPORT const QString& toString(const Enum iEnum);
        } // namespace Enow::ContactHolder::Contacts::FieldType
        ```
    * Other namspaces: camelCase.
- Subdirectory structure and header naming convention follows naming conventions of entity or namespace the header contains:
    * Header contains a class, struct or enum:
        ```c++
        // src/Enow/ContactHolder/Contacts/fields/EmailAddress.hpp
        namespace Enow::ContactHolder::Contacts::fields {
            class CONTACTS_EXPORT EmailAddress {
            ...
            };
        } // namespace Enow::ContactHolder::Contacts::fields
        ```
    * Header contains `enum class Enum` or its helper functions:
        ```c++
        // src/Enow/ContactHolder/Contacts/FieldType.hpp
        namespace Enow::ContactHolder::Contacts::FieldType {
            enum class CONTACTS_EXPORT Enum : std::uint8_t {
                kString, // Generic string without restrictions.
                kPhoneNumber
            };
        } // namespace Enow::ContactHolder::Contacts::FieldType
        ```
        ```c++
        // src/Enow/ContactHolder/Contacts/FieldTypeExtension.hpp
        namespace Enow::ContactHolder::Contacts::FieldType {
            CONTACTS_EXPORT const QString& toString(const Enum iEnum);
        } // namespace Enow::ContactHolder::Contacts::FieldType
        ```
    * Header contains a namespace with standalone functions (which are not helpers of `enum class Enum`) or a standalone function:
        ```c++
        // src/Enow/ContactHolder/GUI/namespaceWithStandaloneFunctions.hpp
        namespace Enow::ContactHolder::GUI::namespaceWithStandaloneFunctions {
            const QString& standaloneFunction();
        } // namespace Enow::ContactHolder::GUI::namespaceWithStandaloneFunctions
        ```
        ```c++
        // src/Enow/ContactHolder/GUI/standaloneFunction.hpp
        namespace Enow::ContactHolder::GUI {
            const QString& standaloneFunction();
        } // namespace Enow::ContactHolder::GUI
        ```
    * Names of headers, containing module-related definitions, are appended with `_DEFS`.

### 3.2. `#include` Directives Order And Blank Lines
- A corresponding header for the current .cpp file, or a header, containing module-related definitions, for the current .hpp file.
- This project's headers.
- Third-party library headers (e.g., Qt, Boost).
- Standard library headers (<vector>, <iostream>, <stdexcept>, etc.).
- The first `#include` directive is separated from the header include guard `#pragma once` with a blank line.
- Each group is separated with a blank line.
- The last `#include` directive is separated from the following code with two blank lines.
- Inside each group, headers are sorted alphabetically.
- Use `#include "..."` for this project's headers, and `#include <...>` for system/third-party/standard headers.
- Class, its fields and methods are separated with two blank lines from anything which is not field or method of the class.

### 3.3. Classes And Structs
Explicitly declare the special member functions of `class`es, even when default behavior is acceptable. Use `= default` or `= delete` to show your intent.
- Default constructor (if it is possible)
- Destructor
- Copy constructor
- Move constructor
- Copy assignment operator
- Move assignment operator

Use `struct` only for Plain Data Structures, i.e. if they:
- Have only public data members (no private/protected fields).
- Have no user-defined constructors, destructors, or virtual methods.
- Contain only other POD types (like ints, doubles, or other POD structs).