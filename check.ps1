<#
.SYNOPSIS
    ULTWEAKS - System Optimization Status Checker
.DESCRIPTION
    Checks if Windows has been optimized for gaming performance
.NOTES
    Run as Administrator for complete results
#>

#region INITIALIZATION
Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTWEAKS - System Optimization Checker"

$Green = [ConsoleColor]::Green
$Red = [ConsoleColor]::Red
$Yellow = [ConsoleColor]::Yellow
$Cyan = [ConsoleColor]::Cyan
$White = [ConsoleColor]::White

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║    ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗                                    ║
║   ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝                                    ║
║   ██║     ███████║█████╗  ██║     █████╔╝                                     ║
║   ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗                                     ║
║   ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗                                    ║
║    ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝                                    ║
║                                                                               ║
║    ╔═══════════════════════════════════════════════════════════════════════╗  ║
║    ║                  SYSTEM OPTIMIZATION STATUS CHECKER                   ║  ║
║    ║                         VERSION 1.0 - ULTWEAKS                        ║  ║
║    ╚═══════════════════════════════════════════════════════════════════════╝  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor $Cyan

Write-Host ""
Write-Host "                        CHECKING OPTIMIZATION STATUS" -ForegroundColor $Yellow
Write-Host ""

# Check Admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($IsAdmin) {
    Write-Host "[✓] Running as Administrator" -ForegroundColor $Green
} else {
    Write-Host "[!] Not running as Administrator - some checks may be incomplete" -ForegroundColor $Red
}
Write-Host ""

#region VARIABLES
$totalChecks = 0
$passedChecks = 0
$failedChecks = 0
#endregion

#region 1. CPU PRIORITY CHECK
$totalChecks++
Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 1. CPU & PERFORMANCE SETTINGS                                         ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Win32PrioritySeparation
$cpuPriority = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
if ($cpuPriority.Win32PrioritySeparation -eq 38) {
    Write-Host "  [✓] CPU Priority Separation . . . . . . . . . . . . . . . . . OPTIMIZED (38)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] CPU Priority Separation . . . . . . . . . . . . . . . . . DEFAULT ($($cpuPriority.Win32PrioritySeparation))" -ForegroundColor $Red
    $failedChecks++
}

# Visual Effects
$visualFX = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
if ($visualFX.VisualFXSetting -eq 2) {
    Write-Host "  [✓] Visual Effects . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Visual Effects . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Transparency
$transparency = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -ErrorAction SilentlyContinue
if ($transparency.EnableTransparency -eq 0) {
    Write-Host "  [✓] Transparency Effects . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Transparency Effects . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 2. GAME BAR & DVR
$totalChecks++
Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 2. GAME BAR & GAME DVR                                                 ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Game Bar
$gameBar = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" -Name "UseGameBar" -ErrorAction SilentlyContinue
if ($gameBar.UseGameBar -eq 0) {
    Write-Host "  [✓] Game Bar . . . . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Game Bar . . . . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Game DVR
$gameDVR = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue
if ($gameDVR.AppCaptureEnabled -eq 0) {
    Write-Host "  [✓] Game DVR (Capture) . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Game DVR (Capture) . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 3. POWER PLAN
$totalChecks++
Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 3. POWER PLAN & ENERGY SETTINGS                                        ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$activePlan = powercfg /getactivescheme
if ($activePlan -match "High performance" -or $activePlan -match "Ultimate Performance") {
    Write-Host "  [✓] Active Power Plan . . . . . . . . . . . . . . . . . . . . OPTIMIZED (High Performance)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Active Power Plan . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Balanced/Power Saver)" -ForegroundColor $Red
    $failedChecks++
}

# Hibernation
$hiberFile = Get-ChildItem -Path "C:\hiberfil.sys" -ErrorAction SilentlyContinue
if (-not $hiberFile) {
    Write-Host "  [✓] Hibernation . . . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Hibernation . . . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 4. SERVICES STATUS
$totalChecks++
Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 4. BLOAT SERVICES (Disabled = Optimized)                               ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$services = @{
    "SysMain" = "Superfetch"
    "WSearch" = "Windows Search"
    "DiagTrack" = "Diagnostic Tracking"
    "XblAuthManager" = "Xbox Live Auth"
    "WerSvc" = "Windows Error Reporting"
    "WpnService" = "Push Notifications"
}

foreach ($svc in $services.Keys) {
    $serviceStatus = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($serviceStatus.StartType -eq "Disabled") {
        Write-Host "  [✓] $($services[$svc]) . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] $($services[$svc]) . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED ($($serviceStatus.StartType))" -ForegroundColor $Red
        $failedChecks++
    }
}

Write-Host ""
#endregion

#region 5. TELEMETRY & NOTIFICATIONS
$totalChecks++
Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 5. TELEMETRY & NOTIFICATIONS                                            ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Telemetry
$telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
if ($telemetry.AllowTelemetry -eq 0) {
    Write-Host "  [✓] Telemetry . . . . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Telemetry . . . . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Level $($telemetry.AllowTelemetry))" -ForegroundColor $Red
    $failedChecks++
}

# Notifications
$notifications = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
if ($notifications.ToastEnabled -eq 0) {
    Write-Host "  [✓] Push Notifications . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Push Notifications . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 6. WINDOWS 11 SPECIFIC
$OSBuild = [Environment]::OSVersion.Version.Build
if ($OSBuild -ge 22000) {
    $totalChecks++
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "  ║ 6. WINDOWS 11 SPECIFIC OPTIMIZATIONS                                   ║" -ForegroundColor $Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
    Write-Host ""

    # Widgets
    $widgets = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue
    if ($widgets.TaskbarDa -eq 0) {
        Write-Host "  [✓] Widgets . . . . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Widgets . . . . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }

    # Chat (Teams)
    $chat = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -ErrorAction SilentlyContinue
    if ($chat.TaskbarMn -eq 0) {
        Write-Host "  [✓] Chat (Teams) . . . . . . . . . . . . . . . . . . . . . OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Chat (Teams) . . . . . . . . . . . . . . . . . . . . . NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }
    Write-Host ""
}
#endregion

#region SUMMARY
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "║                                   SUMMARY                                     ║" -ForegroundColor $Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$percentOptimized = [math]::Round(($passedChecks / $totalChecks) * 100)

if ($percentOptimized -ge 80) {
    Write-Host "  STATUS: FULLY OPTIMIZED! (${percentOptimized}%)" -ForegroundColor $Green
    Write-Host "  Your PC is ready for maximum gaming performance." -ForegroundColor $Green
} elseif ($percentOptimized -ge 50) {
    Write-Host "  STATUS: PARTIALLY OPTIMIZED (${percentOptimized}%)" -ForegroundColor $Yellow
    Write-Host "  Some optimizations applied, but not all." -ForegroundColor $Yellow
} else {
    Write-Host "  STATUS: NOT OPTIMIZED (${percentOptimized}%)" -ForegroundColor $Red
    Write-Host "  Your PC needs optimization for better gaming performance." -ForegroundColor $Red
}

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────────────────────────┐" -ForegroundColor $White
Write-Host "  │  📊 Total Checks: $totalChecks    [✓] Optimized: $passedChecks    [✗] Not Optimized: $failedChecks  │" -ForegroundColor $White
Write-Host "  └─────────────────────────────────────────────────────────────────────────┘" -ForegroundColor $White
Write-Host ""

Write-Host "  ╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
Write-Host "  ║                              RECOMMENDATION                               ║" -ForegroundColor $Yellow
Write-Host "  ╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
Write-Host ""

if ($failedChecks -gt 0) {
    Write-Host "  To apply all optimizations, run:" -ForegroundColor $White
    Write-Host "  iex (irm https://raw.githubusercontent.com/ItsAGENT007/ultweaks/refs/heads/main/ultweaks.ps1)" -ForegroundColor $Cyan
} else {
    Write-Host "  ✓ Your PC is already fully optimized! No action needed." -ForegroundColor $Green
}

Write-Host ""
Read-Host "Press Enter to exit"
#endregion
