@echo off
REM Check for Admin rights
CALL :isAdmin
IF %ERRORLEVEL% == 0 (
  GOTO :run
) ELSE (
  ECHO This script must be "Run as administrator" 
  ECHO Please right click the script and select "Run as administrator" or run this script from within an administrator cmd prompt.
  PAUSE
  EXIT /B
)
:isAdmin
fsutil dirty query %systemdrive% >nul
EXIT /B
:run
echo Powershell will attempt to set the Execution policy for the current process to be AllSigned.
echo This only effects the current process and is required to allow the running of powershell scripts.
set currentDir=%~dp0
Powershell -C "try { Set-ExecutionPolicy AllSigned -Scope Process -Confirm } catch {}; & $(join-path -path ${env:currentDir} -childPath 'FieldSolutions\import_fieldsolutions.ps1')"
pause
