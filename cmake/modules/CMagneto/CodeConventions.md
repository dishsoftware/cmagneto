# Code Conventions


## 1. CMake Conventions
### 1.1. CMake Naming Conventions
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