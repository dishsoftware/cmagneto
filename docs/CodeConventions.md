# Code Conventions
- Place sources of a module under `./src/{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/`.
- The project endorses inclusions of headers of other modules within the project as:
  ```c++
  #include "{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp"
  ```
  and inclusions in consumer projects as:
   ```c++
  #include <{CompanyName_SHORT}/{ProjectNameBase}/{ModuleName}/{HeaderNameWE}.hpp>
  ```
- The CMagneto CMake module requires all target headers, sources and resources to be placed under the target root source directory (the same dir where the target's `CMakeLists.txt` resides).
  Sources of the target can also be generated under the target build root directory.


## CMake Conventions
### CMake Naming Conventions
- File of a module: `cmake/modules/ModuleName.cmake`.
- File of a module's submodule: `cmake/modules/ModuleName/SubModule.cmake`.
- Script file: `script_file.cmake`.
- Function in a module: `ModuleName__function_name`.<br>
  But, e.g. `CMagneto__find__Qt_TOOL_EXE` is also fine: the function name part must start according to the convention and may be appended with anything after the last `_`.
- Function in a module, intended for usage only within the module: `ModuleNameInternal__function_name`.<br>
  But, e.g. `CMagnetoInternal__find__Qt_TOOL_EXE` is also fine: the function name part must start according to the convention and may be appended with anything after the last `_`.
- Variable in a module, outside of function: `ModuleName__varName`.
- Constant in a module, outside of function: `ModuleName__CONST_NAME`.
- Variable in a module, outside of function, intended for usage only within the module: `ModuleNameInternal__varName`.
- Constant in a module, outside of function, intended for usage only within the module: `ModuleNameInternal__CONST_NAME`.
- Parameters of functions:
    * Purely input parameter: `iParamName`.
    * Purely output parameter: `oParamName`.
- Variable in a function, macro, script or CMakeLists.txt: `_varName`.
- Constant in a function, macro, script or CMakeLists.txt: `_CONST_NAME`.


## C++ Conventions
### C++ Naming Conventions
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
        namespace Enow::Contacts::GUI {
            ...
        } // namespace Enow::Contacts::GUI
        ```
    * Namespace, encapsulating `enum class Enum` or its helper functions: CamelCase.
        ```c++
        namespace Enow::Contacts::Contacts::FieldType {
            enum class CONTACTS_EXPORT Enum : std::uint8_t {
                kString, // Generic string without restrictions.
                kPhoneNumber
            };

            CONTACTS_EXPORT const QString& toString(const Enum iEnum);
        } // namespace Enow::Contacts::Contacts::FieldType
        ```
    * Other namspaces: camelCase.
- Subdirectory structure and header naming convention follows naming conventions of entity or namespace the header contains:
    * Header contains a class, struct or enum:
        ```c++
        // src/Enow/Contacts/Contacts/fields/EmailAddress.hpp
        namespace Enow::Contacts::Contacts::fields {
            class CONTACTS_EXPORT EmailAddress {
            ...
            };
        } // namespace Enow::Contacts::Contacts::fields
        ```
    * Header contains `enum class Enum` or its helper functions:
        ```c++
        // src/Enow/Contacts/Contacts/FieldType.hpp
        namespace Enow::Contacts::Contacts::FieldType {
            enum class CONTACTS_EXPORT Enum : std::uint8_t {
                kString, // Generic string without restrictions.
                kPhoneNumber
            };
        } // namespace Enow::Contacts::Contacts::FieldType
        ```
        ```c++
        // src/Enow/Contacts/Contacts/FieldTypeExtension.hpp
        namespace Enow::Contacts::Contacts::FieldType {
            CONTACTS_EXPORT const QString& toString(const Enum iEnum);
        } // namespace Enow::Contacts::Contacts::FieldType
        ```
    * Header contains a namespace with standalone functions (which are not helpers of `enum class Enum`) or a standalone function:
        ```c++
        // src/Enow/Contacts/GUI/namespaceWithStandaloneFunctions.hpp
        namespace Enow::Contacts::GUI::namespaceWithStandaloneFunctions {
            const QString& standaloneFunction();
        } // namespace Enow::Contacts::GUI::namespaceWithStandaloneFunctions
        ```
        ```c++
        // src/Enow/Contacts/GUI/standaloneFunction.hpp
        namespace Enow::Contacts::GUI {
            const QString& standaloneFunction();
        } // namespace Enow::Contacts::GUI
        ```
    * Names of headers, containing module-related definitions, are appended with `_DEFS`.

#### `#include` Directives
- A corresponding header for the current .cpp file, or a header, containing module-related definitions, for the current .hpp file.
- This project's headers.
- Third-party library headers (e.g., Qt, Boost).
- Standard library headers (<vector>, <iostream>, <stdexcept>, etc.).
- The first `#include` directive is separated from the header include guard `#pragma once` with a blank line.
- Each group is separated with a blank line.
- The last `#include` directive is separated from the following code with two blank lines.
- Inside each group, headers are sorted alphabetically.
- Use `#include "..."` for this project's headers, and `#include <...>` for system/third-party/standard headers.

#### Blank Lines
- Look into [`#include` Directives](#include-directives) section.
- Class, its fields and methods are separated with two blank lines from anything which is not field or method of the class.

#### Classes and structs
Explicitly declare the special member functions, even when default behavior is acceptable. Use `= default` or `= delete` to show your intent.
- Default constructor (if it is possible)
- Destructor
- Copy constructor
- Move constructor
- Copy assignment operator
- Move assignment operator