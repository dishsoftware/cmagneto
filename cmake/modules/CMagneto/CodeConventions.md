# Code Conventions


## 1. CMake Conventions
### 1.1. CMake Naming Conventions
- File of a module: `cmake/modules/ModuleName.cmake`.
- File of a module's submodule: `cmake/modules/ModuleName/SubModule.cmake`.
- File of a module's submodule with internal functions, constants and variables,<br>
  intended for usage only within the module: `cmake/modules/ModuleName/SubModule_Internals.cmake`.
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