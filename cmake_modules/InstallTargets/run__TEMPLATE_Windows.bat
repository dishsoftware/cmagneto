@echo off

rem If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
rem The file contains variables in the section "Template parameters".
rem Values of these variables are specific to the machine the project was built on and set during the process (look into InstallTargets.cmake).
rem Replaced values of these variables must not contain `\n`. The character is reserved to mark strings to replace.


rem SECTION<Template parameters>START
set "EXECUTABLE_NAME_WE=param\nEXECUTABLE_NAME_WE\nparam"
rem SECTION<Template parameters>END


rem Check if EXECUTABLE_NAME_WE contains '\0'
echo %EXECUTABLE_NAME_WE% | findstr "\n" >nul
if %errorlevel% equ 0 (
    rem EXECUTABLE_NAME_WE contains "\n", which is reserved to mark substring to be replaced.
    echo Incorrectly generated script: %0
) else (
    call set_env.bat
    %EXECUTABLE_NAME_WE%.exe
)