# Code Conventions


## 1. CMake Conventions
The same as [CMake Conventions of the `CMagneto` CMake module](./../cmake/modules/CMagneto/doc/CodeConventions.md).


## 2. C++ Conventions
- Place sources of a module under `./src/{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/`.
- The project endorses inclusions of headers of other modules within the project as:
  ```c++
  #include "{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp"
  ```
  and inclusions in consumer projects as:
   ```c++
  #include <{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp>
  ```
- The [`CMagneto CMake module imposes restrictions on locations of files`](./../cmake/modules/CMagneto/README.md#1-how-to-use-the-module).

### 2.1. C++ Naming Conventions
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

### 2.2. `#include` Directives Order And Blank Lines
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

### 2.3. Classes And Structs
Explicitly declare the special member functions, even when default behavior is acceptable. Use `= default` or `= delete` to show your intent.
- Default constructor (if it is possible)
- Destructor
- Copy constructor
- Move constructor
- Copy assignment operator
- Move assignment operator