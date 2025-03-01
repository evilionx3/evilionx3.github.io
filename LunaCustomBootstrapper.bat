@echo off

title Luna Custom Bootstrapper - Made by Cheezit (szcx6)

openfiles >nul 2>nul
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Requesting Administrator permissions...
    powershell -Command "Start-Process cmd -ArgumentList '/c, %~s0' -Verb RunAs"
    exit /b
)

set "LunaFolder=%USERPROFILE%\Documents\Luna"
if not exist "%LunaFolder%" (
    echo Creating the "Luna" folder in Documents...
    mkdir "%LunaFolder%"
)

echo Adding "Luna" folder to Defender exclusions...
powershell -Command "Add-MpPreference -ExclusionPath '%LunaFolder%'"

echo.
echo Downloading Bootstrapper.zip...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/suffz/luna/raw/refs/heads/main/Bootstrapper.zip' -OutFile '%TEMP%\Bootstrapper.zip'"

echo Unzipping Bootstrapper.zip...
powershell -Command "Expand-Archive -Path '%TEMP%\Bootstrapper.zip' -DestinationPath '%TEMP%\Luna' -Force"

echo.
echo Moving Bootstrapper.exe to the main Luna folder...
move /Y "%TEMP%\Luna\Luna\Bootstrapper.exe" "%LunaFolder%\Bootstrapper.exe"

echo Cleaning up temporary files...
del "%TEMP%\Bootstrapper.zip"
rd /S /Q "%TEMP%\Luna"

echo.
echo Opening Luna...
start explorer "%LunaFolder%"
cd %LunaFolder%
start Bootstrapper.exe
echo.
echo Successfully created Defender exclusions for Luna executor,
echo Please enjoy!
