@echo off
title ULTWEAKS - Optimization Status Checker
color 0F
cls

echo ===============================================================
echo            ULTWEAKS OPTIMIZATION STATUS CHECKER
echo ===============================================================
echo.
echo Checking your PC optimization status...
echo.

:: Check CPU Priority
echo [1] CPU Priority Setting...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation 2^>nul ^| find "0x"') do (
        if "%%a"=="0x26" (echo   [OK] CPU Priority: OPTIMIZED (38)) else (echo   [XX] CPU Priority: NOT OPTIMIZED (%%a))
    )
) else (
    echo   [??] CPU Priority: Not found
)

:: Check Game Bar
echo.
echo [2] Game Bar Status...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\GameBar" /v UseGameBar >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\GameBar" /v UseGameBar 2^>nul ^| find "0x"') do (
        if "%%a"=="0x0" (echo   [OK] Game Bar: DISABLED) else (echo   [XX] Game Bar: ENABLED)
    )
) else (
    echo   [??] Game Bar: Not configured
)

:: Check Visual Effects
echo.
echo [3] Visual Effects...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting 2^>nul ^| find "0x"') do (
        if "%%a"=="0x2" (echo   [OK] Visual Effects: DISABLED) else (echo   [XX] Visual Effects: ENABLED)
    )
) else (
    echo   [??] Visual Effects: Not configured
)

:: Check Transparency
echo.
echo [4] Transparency Effects...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency 2^>nul ^| find "0x"') do (
        if "%%a"=="0x0" (echo   [OK] Transparency: DISABLED) else (echo   [XX] Transparency: ENABLED)
    )
) else (
    echo   [??] Transparency: Not configured
)

:: Check Power Plan
echo.
echo [5] Active Power Plan...
powercfg /getactivescheme | find "High performance" >nul
if %errorlevel% equ 0 (
    echo   [OK] Power Plan: HIGH PERFORMANCE
) else (
    powercfg /getactivescheme | find "Ultimate" >nul
    if %errorlevel% equ 0 (
        echo   [OK] Power Plan: ULTIMATE PERFORMANCE
    ) else (
        echo   [XX] Power Plan: NOT OPTIMIZED (use Balanced or Power Saver)
    )
)

:: Check Hibernation
echo.
echo [6] Hibernation Status...
powercfg /a | find "Hibernation" | find "Not" >nul
if %errorlevel% equ 0 (
    echo   [OK] Hibernation: DISABLED
) else (
    echo   [XX] Hibernation: ENABLED (uses disk space)
)

:: Check SysMain Service
echo.
echo [7] SysMain (Superfetch) Service...
sc query SysMain | find "STOPPED" >nul
if %errorlevel% equ 0 (
    echo   [OK] SysMain: DISABLED
) else (
    echo   [XX] SysMain: RUNNING
)

:: Check Windows Search
echo.
echo [8] Windows Search Service...
sc query WSearch | find "STOPPED" >nul
if %errorlevel% equ 0 (
    echo   [OK] Windows Search: DISABLED
) else (
    echo   [XX] Windows Search: RUNNING
)

:: Check Xbox Services
echo.
echo [9] Xbox Services...
sc query XblAuthManager | find "STOPPED" >nul
if %errorlevel% equ 0 (
    echo   [OK] Xbox Services: DISABLED
) else (
    echo   [XX] Xbox Services: RUNNING
)

:: Summary
echo.
echo ===============================================================
echo                    CHECK COMPLETE
echo ===============================================================
echo.
echo To apply all optimizations, run ULTWEAKS:
echo Run: iex (irm https://raw.githubusercontent.com/ItsAGENT007/ultweaks/refs/heads/main/ultweaks.ps1)
echo.
echo ===============================================================
pause
