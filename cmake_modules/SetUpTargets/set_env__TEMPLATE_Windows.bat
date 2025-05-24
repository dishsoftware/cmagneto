@echo off

rem If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
rem The file contains variables in the section "Template parameters".
rem Values of these variables are specific to the machine the project was built on and set during the process (look into SetUpTargets.cmake).
rem Replaced values of these variables must not contain `\n`. The character is reserved to mark substrings to replace during build.


rem SECTION<Template parameters>START
rem Directories must be separated with ";".
set "SHARED_LIB_DIRS_STRING=param\nSHARED_LIB_DIRS_STRING\nparam"
rem SECTION<Template parameters>END


rem Check if SHARED_LIB_DIRS_STRING contains '\n'.
echo %SHARED_LIB_DIRS_STRING% | findstr "\n" >nul
if %errorlevel% equ 0 (
    rem SHARED_LIB_DIRS_STRING contains "\n", which is reserved to mark substrings to be replaced during build.
    echo Incorrectly generated script: %0
) else (
    set "Path=%SHARED_LIB_DIRS_STRING%;%Path%"
)