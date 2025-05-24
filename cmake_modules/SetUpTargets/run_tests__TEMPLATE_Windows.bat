@echo off

rem If you found this file in ./build or ./install directory or subdirectories: don't distrubute it.
rem The file runs "set_env" script, which contains variables in the section "Template parameters".
rem Values of these variables are specific to the machine the project was built on and set during the process (look into SetUpTargets.cmake).
rem Replaced values of these variables must not contain `\n`. The character is reserved to mark substrings to replace during build.


rem SECTION<Template parameters>START
set "DIR_WITH_CTESTTESTFILE=param\nDIR_WITH_CTESTTESTFILE\nparam"
set "BUILD_CONFIG=param\nBUILD_CONFIG\nparam"
set "REPORT_PATH=param\nREPORT_PATH\nparam"
rem SECTION<Template parameters>END


rem Check if a template parameter contains '\n'.
echo %DIR_WITH_CTESTTESTFILE%%BUILD_CONFIG% | findstr "\n" >nul
if %errorlevel% equ 0 (
    echo Incorrectly generated script ^(template parameter contains "\n"^): %0
) else if not defined DIR_WITH_CTESTTESTFILE (
    echo Incorrectly generated script ^(no test directory specified^): %0
) else if not defined BUILD_CONFIG (
    echo Incorrectly generated script ^(no build configuration specified^): %0
) else if not defined REPORT_PATH (
    echo Incorrectly generated script ^(no report path specified^): %0
) else (
    call "%~dp0/set_env.bat"
    rem Multi-config generator (e.g. Visual Studio) requires a build configuration to be defined.
    rem For single-config generator (e.g. MinGW) it is redundant, but does not affect anything.
    ctest --test-dir "%~dp0/%DIR_WITH_CTESTTESTFILE%" --output-on-failure --build-config %BUILD_CONFIG% --output-junit "%~dp0/%REPORT_PATH%" %*
)