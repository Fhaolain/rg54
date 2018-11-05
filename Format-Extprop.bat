@echo off
set currentDir=%~dp0
Powershell -C "move-item ${env:currentDir}\snowflake.extprop ${env:currentDir}\snowflake.extprop.old"
Powershell -C "get-content ${env:currentDir}\snowflake.extprop.old | convertfrom-JSON | convertto-JSON | set-content ${env:currentDir}\snowflake.extprop"
pause
