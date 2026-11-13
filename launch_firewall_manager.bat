@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: 1. Check for Administrator privileges
openfiles >nul 2>&1
if %errorlevel%==0 goto :execute

:: 2. Self-elevate via temporary UAC VBS wrapper
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "cmd.exe", "/c ""cd /d """%~dp0""" && ""%~f0""""", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /b

:execute
:: 3. Launch PowerShell script with controlled absolute path
echo Launching Windows Firewall Maintenance Tool...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0firewall_maintenance.ps1'"
pause
