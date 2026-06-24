@echo off
setlocal

echo.
echo ======================================
echo   blackcow-codex-swap installer
echo ======================================
echo.

set "DEST=%USERPROFILE%\.codex\profile.ps1"
set "SRC=%~dp0win\profile.ps1"

if not exist "%SRC%" (
    echo [ERROR] win\profile.ps1 not found.
    echo Make sure you run this from the blackcow-codex-swap folder.
    pause
    exit /b 1
)

echo Copying profile.ps1 ...
copy /Y "%SRC%" "%DEST%" >nul

echo Updating PowerShell profile ...
powershell -NoProfile -Command "
    `$line = '. \"$env:USERPROFILE\.codex\profile.ps1\"'
    if (-not (Test-Path `$PROFILE)) {
        New-Item -ItemType File -Path `$PROFILE -Force | Out-Null
    }
    if (-not (Select-String -Path `$PROFILE -Pattern 'profile.ps1' -SimpleMatch -Quiet)) {
        Add-Content -Path `$PROFILE -Value `$line
    }
"

echo.
echo ======================================
echo   Done!
echo.
echo   Close this window and open a new
echo   PowerShell. Then run:
echo.
echo     codex-pick
echo.
echo   Or if this is your first setup:
echo     codex-add
echo ======================================
echo.
pause
