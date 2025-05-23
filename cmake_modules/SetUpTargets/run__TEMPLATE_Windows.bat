@echo off

rem If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
rem The file runs "set_env" script, which contains variables in the section "Template parameters".
rem Values of these variables are specific to the machine the project was built on and set during the process (look into SetUpTargets.cmake).
rem Replaced values of these variables must not contain `\n`. The character is reserved to mark substrings to replace during build.


rem SECTION<Template parameters>START
set "EXECUTABLE_NAME_WE=param\nEXECUTABLE_NAME_WE\nparam"
rem SECTION<Template parameters>END


rem Check if EXECUTABLE_NAME_WE contains '\n'.
echo %EXECUTABLE_NAME_WE% | findstr "\n" >nul
if %errorlevel% equ 0 (
    rem EXECUTABLE_NAME_WE contains "\n", which is reserved to mark substrings to be replaced during build.
    echo Incorrectly generated script: %0
) else (
    call "%~dp0/set_env.bat"
    "%EXECUTABLE_NAME_WE%.exe"
)