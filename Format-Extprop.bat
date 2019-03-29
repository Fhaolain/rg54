@echo off
set currentDir=%~dp0
Powershell -C "get-content ${env:currentDir}\snowflake.extprop | convertfrom-JSON | convertto-JSON | set-content ${env:currentDir}\snowflake.compare -force"
pause
