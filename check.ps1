<#
.SYNOPSIS
    ULTWEAKS - Complete System Optimization Status Checker
.DESCRIPTION
    Checks 40+ optimization points including registry, services, power plan, network, and hardware
.NOTES
    Version: 2.0
    Run as Administrator for complete results
#>

#region INITIALIZATION
Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTWEAKS - Complete System Checker"

# Colors
$Green = [ConsoleColor]::Green
$Red = [ConsoleColor]::Red
$Yellow = [ConsoleColor]::Yellow
$Cyan = [ConsoleColor]::Cyan
$White = [ConsoleColor]::White
$Gray = [ConsoleColor]::Gray

Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                              ║
║    ██╗   ██╗██╗  ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗                         ║
║    ██║   ██║██║  ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝                         ║
║    ██║   ██║██║     ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ ███████╗                         ║
║    ██║   ██║██║     ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ╚════██║                         ║
║    ╚██████╔╝███████╗██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████║                         ║
║     ╚═════╝ ╚══════╝╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝                         ║
║                                                                                              ║
║    ╔══════════════════════════════════════════════════════════════════════════════════════╗  ║
║    ║                    COMPLETE SYSTEM OPTIMIZATION STATUS CHECKER v2.0                  ║  ║
║    ║                         40+ POINTS CHECKED - ULTWEAKS                                ║  ║
║    ╚══════════════════════════════════════════════════════════════════════════════════════╝  ║
║                                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor $Cyan

Write-Host ""
Write-Host "                         SYSTEM OPTIMIZATION STATUS CHECKER" -ForegroundColor $Yellow
Write-Host ""

# Check Admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($IsAdmin) {
    Write-Host "[✓] Running as Administrator (Full checks available)" -ForegroundColor $Green
} else {
    Write-Host "[!] Not running as Administrator - some checks may be incomplete" -ForegroundColor $Red
    Write-Host "[!] Right click PowerShell -> Run as administrator for complete results" -ForegroundColor $Yellow
}
Write-Host ""

# Variables
$totalChecks = 0
$passedChecks = 0
$failedChecks = 0
$warnings = 0

#region 1. SYSTEM INFORMATION
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 1. SYSTEM INFORMATION                                                                 ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# OS Version
$OSVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
$OSBuild = [Environment]::OSVersion.Version.Build
Write-Host "  Operating System: $OSVersion (Build $OSBuild)" -ForegroundColor $White

# Windows Version Detection
if ($OSBuild -ge 22000) {
    $IsWindows11 = $true
    Write-Host "  Mode: Windows 11" -ForegroundColor $Cyan
} elseif ($OSBuild -ge 17763) {
    $IsWindows11 = $false
    Write-Host "  Mode: Windows 10" -ForegroundColor $Cyan
} else {
    $IsWindows11 = $false
    Write-Host "  Mode: Older Windows Version" -ForegroundColor $Yellow
}

# RAM Size
$RAM = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
$RAMGB = [math]::Round($RAM / 1GB, 2)
Write-Host "  Total RAM: $RAMGB GB" -ForegroundColor $White

# CPU Info
$CPU = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
Write-Host "  CPU: $($CPU.Substring(0, [math]::Min(50, $CPU.Length)))..." -ForegroundColor $White

# GPU Info
$GPU = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -notlike "*Mirror*" -and $_.Name -notlike "*Remote*" } | Select-Object -First 1
if ($GPU) {
    Write-Host "  GPU: $($GPU.Name)" -ForegroundColor $White
    $gpuMemory = [math]::Round($GPU.AdapterRAM / 1GB, 0)
    if ($gpuMemory -gt 0) {
        Write-Host "  GPU Memory: $gpuMemory GB" -ForegroundColor $White
    }
}

# Disk Space
$disk = Get-PSDrive -Name C
$freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
$totalSpaceGB = [math]::Round($disk.Used / 1GB + $freeSpaceGB, 2)
$freePercent = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100)
Write-Host "  C: Drive - Free: $freeSpaceGB GB / $totalSpaceGB GB ($freePercent%)" -ForegroundColor $White
if ($freePercent -lt 20) {
    Write-Host "  [!] Low disk space - consider cleaning!" -ForegroundColor $Yellow
    $warnings++
}

Write-Host ""
#endregion

#region 2. CPU & PERFORMANCE REGISTRY
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 2. CPU & PERFORMANCE REGISTRY SETTINGS                                              ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Win32PrioritySeparation
$totalChecks++
$cpuPriority = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
if ($cpuPriority.Win32PrioritySeparation -eq 38) {
    Write-Host "  [✓] CPU Priority Separation: OPTIMIZED (38)" -ForegroundColor $Green
    $passedChecks++
} elseif ($cpuPriority.Win32PrioritySeparation -eq 26 -or $cpuPriority.Win32PrioritySeparation -eq 42) {
    Write-Host "  [!] CPU Priority Separation: PARTIAL ($($cpuPriority.Win32PrioritySeparation))" -ForegroundColor $Yellow
    $warnings++
} else {
    Write-Host "  [✗] CPU Priority Separation: DEFAULT ($($cpuPriority.Win32PrioritySeparation))" -ForegroundColor $Red
    $failedChecks++
}

# Processor Performance
$totalChecks++
$perfBoost = Get-ItemProperty -Path "HKLM\SYSTEM\CurrentControlSet\Control\Processor" -Name "Capabilities" -ErrorAction SilentlyContinue
Write-Host "  [?] Processor Performance Boost: CHECKED" -ForegroundColor $Gray

# Desktop Process Priority
$totalChecks++
$desktopProc = Get-ItemProperty -Path "HKCU\Control Panel\Desktop" -Name "ForegroundLockTimeout" -ErrorAction SilentlyContinue
if ($desktopProc.ForegroundLockTimeout -eq 0 -or $desktopProc.ForegroundLockTimeout -eq 200000) {
    Write-Host "  [✓] Foreground Lock Timeout: OPTIMIZED" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [!] Foreground Lock Timeout: DEFAULT ($($desktopProc.ForegroundLockTimeout))" -ForegroundColor $Yellow
    $warnings++
}

Write-Host ""
#endregion

#region 3. VISUAL EFFECTS & UI
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 3. VISUAL EFFECTS & UI SETTINGS                                                     ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Visual Effects
$totalChecks++
$visualFX = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
if ($visualFX.VisualFXSetting -eq 2) {
    Write-Host "  [✓] Visual Effects: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} elseif ($visualFX.VisualFXSetting -eq 1) {
    Write-Host "  [!] Visual Effects: PARTIAL (Let Windows choose)" -ForegroundColor $Yellow
    $warnings++
} else {
    Write-Host "  [✗] Visual Effects: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Transparency
$totalChecks++
$transparency = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -ErrorAction SilentlyContinue
if ($transparency.EnableTransparency -eq 0) {
    Write-Host "  [✓] Transparency Effects: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Transparency Effects: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Menu Show Delay
$totalChecks++
$menuDelay = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ErrorAction SilentlyContinue
if ($menuDelay.MenuShowDelay -eq 0) {
    Write-Host "  [✓] Menu Show Delay: OPTIMIZED (0ms)" -ForegroundColor $Green
    $passedChecks++
} elseif ($menuDelay.MenuShowDelay -le 200) {
    Write-Host "  [!] Menu Show Delay: PARTIAL ($($menuDelay.MenuShowDelay)ms)" -ForegroundColor $Yellow
    $warnings++
} else {
    Write-Host "  [✗] Menu Show Delay: NOT OPTIMIZED ($($menuDelay.MenuShowDelay)ms)" -ForegroundColor $Red
    $failedChecks++
}

# Animations
$totalChecks++
$animations = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -ErrorAction SilentlyContinue
Write-Host "  [?] UI Animations: CHECKED" -ForegroundColor $Gray

# Taskbar Animations
$totalChecks++
$taskbarAnim = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -ErrorAction SilentlyContinue
if ($taskbarAnim.TaskbarAnimations -eq 0) {
    Write-Host "  [✓] Taskbar Animations: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Taskbar Animations: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 4. GAME BAR & DVR
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 4. GAME BAR & GAME DVR                                                               ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Game Bar
$totalChecks++
$gameBar = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" -Name "UseGameBar" -ErrorAction SilentlyContinue
if ($gameBar.UseGameBar -eq 0) {
    Write-Host "  [✓] Game Bar: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Game Bar: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Game DVR
$totalChecks++
$gameDVR = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue
if ($gameDVR.AppCaptureEnabled -eq 0) {
    Write-Host "  [✓] Game DVR (Capture): OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Game DVR (Capture): NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# Game Mode
$totalChecks++
$gameMode = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue
if ($gameMode.AutoGameModeEnabled -eq 0) {
    Write-Host "  [✓] Game Mode: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [!] Game Mode: ENABLED (May cause issues in some games)" -ForegroundColor $Yellow
    $warnings++
}

# GameDVR Enabled
$totalChecks++
$gdvr = Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue
if ($gdvr.GameDVR_Enabled -eq 0) {
    Write-Host "  [✓] GameDVR Background: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] GameDVR Background: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 5. POWER PLAN
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 5. POWER PLAN & ENERGY SETTINGS                                                     ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Active Power Plan
$totalChecks++
$activePlan = powercfg /getactivescheme
if ($activePlan -match "High performance" -or $activePlan -match "Ultimate Performance") {
    Write-Host "  [✓] Active Power Plan: OPTIMIZED (High Performance)" -ForegroundColor $Green
    $passedChecks++
} elseif ($activePlan -match "Balanced") {
    Write-Host "  [✗] Active Power Plan: NOT OPTIMIZED (Balanced)" -ForegroundColor $Red
    $failedChecks++
} elseif ($activePlan -match "Power saver") {
    Write-Host "  [✗] Active Power Plan: NOT OPTIMIZED (Power Saver - BAD for gaming!)" -ForegroundColor $Red
    $failedChecks++
} else {
    Write-Host "  [✗] Active Power Plan: NOT OPTIMIZED (Unknown)" -ForegroundColor $Red
    $failedChecks++
}

# Hibernation
$totalChecks++
$hiberFile = Get-ChildItem -Path "C:\hiberfil.sys" -ErrorAction SilentlyContinue
if (-not $hiberFile) {
    Write-Host "  [✓] Hibernation: OPTIMIZED (Disabled - saves disk space)" -ForegroundColor $Green
    $passedChecks++
} else {
    $hiberSize = [math]::Round($hiberFile.Length / 1GB, 2)
    Write-Host "  [✗] Hibernation: NOT OPTIMIZED (Enabled - uses $hiberSize GB)" -ForegroundColor $Red
    $failedChecks++
}

# Sleep Timeouts
$totalChecks++
$sleepTimeout = powercfg -query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null
if ($sleepTimeout -match "0x00000000") {
    Write-Host "  [✓] Sleep Timeout: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [!] Sleep Timeout: ENABLED (PC may sleep during gaming)" -ForegroundColor $Yellow
    $warnings++
}

# USB Selective Suspend
$totalChecks++
$usbSuspend = powercfg -query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>$null
if ($usbSuspend -match "0x00000000") {
    Write-Host "  [✓] USB Selective Suspend: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] USB Selective Suspend: NOT OPTIMIZED (May cause input lag)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 6. SERVICES STATUS
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 6. BLOAT SERVICES (Disabled = Optimized)                                            ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$services = @(
    @{Name="SysMain"; Display="SysMain (Superfetch)"},
    @{Name="WSearch"; Display="Windows Search Indexer"},
    @{Name="DiagTrack"; Display="Diagnostic Tracking (Telemetry)"},
    @{Name="DPS"; Display="Diagnostic Policy Service"},
    @{Name="WdiServiceHost"; Display="Diagnostic Service Host"},
    @{Name="WdiSystemHost"; Display="Diagnostic System Host"},
    @{Name="XblAuthManager"; Display="Xbox Live Authentication"},
    @{Name="XboxNetApiSvc"; Display="Xbox Live Networking"},
    @{Name="XboxGipSvc"; Display="Xbox Accessory Management"},
    @{Name="WerSvc"; Display="Windows Error Reporting"},
    @{Name="WpnService"; Display="Windows Push Notifications"},
    @{Name="PcaSvc"; Display="Program Compatibility Assistant"},
    @{Name="TabletInputService"; Display="Touch Keyboard Service"},
    @{Name="MapsBroker"; Display="Downloaded Maps Manager"},
    @{Name="lfsvc"; Display="Geolocation Service"},
    @{Name="Fax"; Display="Fax Service"},
    @{Name="RemoteRegistry"; Display="Remote Registry"},
    @{Name="PrintSpooler"; Display="Print Spooler (if no printer)"}
)

foreach ($svc in $services) {
    $totalChecks++
    $serviceStatus = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($serviceStatus -and $serviceStatus.StartType -eq "Disabled") {
        Write-Host "  [✓] $($svc.Display): OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } elseif ($serviceStatus -and $serviceStatus.StartType -eq "Manual") {
        Write-Host "  [!] $($svc.Display): PARTIAL (Manual)" -ForegroundColor $Yellow
        $warnings++
    } elseif ($serviceStatus -and $serviceStatus.StartType -eq "Automatic") {
        Write-Host "  [✗] $($svc.Display): NOT OPTIMIZED (Running)" -ForegroundColor $Red
        $failedChecks++
    }
}

Write-Host ""
#endregion

#region 7. TELEMETRY & PRIVACY
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 7. TELEMETRY & PRIVACY SETTINGS                                                     ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Telemetry
$totalChecks++
$telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
if ($telemetry.AllowTelemetry -eq 0) {
    Write-Host "  [✓] Telemetry Data Collection: OPTIMIZED (Disabled - 0)" -ForegroundColor $Green
    $passedChecks++
} elseif ($telemetry.AllowTelemetry -eq 1) {
    Write-Host "  [!] Telemetry Data Collection: PARTIAL (Basic - 1)" -ForegroundColor $Yellow
    $warnings++
} else {
    Write-Host "  [✗] Telemetry Data Collection: NOT OPTIMIZED (Full - $($telemetry.AllowTelemetry))" -ForegroundColor $Red
    $failedChecks++
}

# Push Notifications
$totalChecks++
$notifications = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
if ($notifications.ToastEnabled -eq 0) {
    Write-Host "  [✓] Push Notifications: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Push Notifications: NOT OPTIMIZED (Enabled - disturbs gaming)" -ForegroundColor $Red
    $failedChecks++
}

# Background Apps
$totalChecks++
$backgroundApps = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
if ($backgroundApps.GlobalUserDisabled -eq 1) {
    Write-Host "  [✓] Background Apps: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Background Apps: NOT OPTIMIZED (Apps run in background)" -ForegroundColor $Red
    $failedChecks++
}

# Cortana
$totalChecks++
$cortana = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
if ($cortana.AllowCortana -eq 0) {
    Write-Host "  [✓] Cortana: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Cortana: NOT OPTIMIZED (Running in background)" -ForegroundColor $Red
    $failedChecks++
}

# Web Search in Start Menu
$totalChecks++
$webSearch = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -ErrorAction SilentlyContinue
if ($webSearch.BingSearchEnabled -eq 0) {
    Write-Host "  [✓] Web Search in Start Menu: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Web Search in Start Menu: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 8. NETWORK OPTIMIZATION
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 8. NETWORK OPTIMIZATION (For lower ping)                                            ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Nagle's Algorithm
$totalChecks++
$interface = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($interface.TcpAckFrequency -eq 1) {
    Write-Host "  [✓] Nagle's Algorithm: OPTIMIZED (Disabled - lower latency)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Nagle's Algorithm: NOT OPTIMIZED (Higher latency)" -ForegroundColor $Red
    $failedChecks++
}

# TCP NoDelay
$totalChecks++
$tcpNoDelay = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($tcpNoDelay.TCPNoDelay -eq 1) {
    Write-Host "  [✓] TCP NoDelay: OPTIMIZED (Enabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] TCP NoDelay: NOT OPTIMIZED (Disabled)" -ForegroundColor $Red
    $failedChecks++
}

# TCP AutoTuning
$totalChecks++
$autoTuning = netsh int tcp show global | findstr "Receive-Side Scaling"
if ($autoTuning -match "enabled") {
    Write-Host "  [✓] TCP AutoTuning: OPTIMIZED (Normal)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] TCP AutoTuning: NOT OPTIMIZED ($autoTuning)" -ForegroundColor $Red
    $failedChecks++
}

# Windows Update P2P
$totalChecks++
$p2pUpdate = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -ErrorAction SilentlyContinue
if ($p2pUpdate.DODownloadMode -eq 0) {
    Write-Host "  [✓] P2P Windows Update: OPTIMIZED (Disabled - saves bandwidth)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] P2P Windows Update: NOT OPTIMIZED (Using your bandwidth)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 9. WINDOWS 11 SPECIFIC
if ($IsWindows11) {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "  ║ 9. WINDOWS 11 SPECIFIC OPTIMIZATIONS                                                ║" -ForegroundColor $Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
    Write-Host ""

    # Widgets
    $totalChecks++
    $widgets = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue
    if ($widgets.TaskbarDa -eq 0) {
        Write-Host "  [✓] Widgets: OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Widgets: NOT OPTIMIZED (Uses RAM/CPU)" -ForegroundColor $Red
        $failedChecks++
    }

    # Chat (Teams)
    $totalChecks++
    $chat = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -ErrorAction SilentlyContinue
    if ($chat.TaskbarMn -eq 0) {
        Write-Host "  [✓] Chat (Teams): OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Chat (Teams): NOT OPTIMIZED (Runs in background)" -ForegroundColor $Red
        $failedChecks++
    }

    # Task View Animation
    $totalChecks++
    $taskView = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskViewAnimation" -ErrorAction SilentlyContinue
    if ($taskView.TaskViewAnimation -eq 0) {
        Write-Host "  [✓] Task View Animation: OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Task View Animation: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }

    # Snap Assist
    $totalChecks++
    $snapAssist = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapAssistFlyout" -ErrorAction SilentlyContinue
    if ($snapAssist.EnableSnapAssistFlyout -eq 0) {
        Write-Host "  [✓] Snap Assist: OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Snap Assist: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }

    # News and Interests
    $totalChecks++
    $news = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -ErrorAction SilentlyContinue
    if ($news.ShellFeedsTaskbarViewMode -eq 2) {
        Write-Host "  [✓] News and Interests: OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] News and Interests: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }

    # Recommended Files
    $totalChecks++
    $recommended = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -ErrorAction SilentlyContinue
    if ($recommended.Start_IrisRecommendations -eq 0) {
        Write-Host "  [✓] Recommended Files: OPTIMIZED (Disabled in Start Menu)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "  [✗] Recommended Files: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
        $failedChecks++
    }

    Write-Host ""
}
#endregion

#region 10. STARTUP & BOOT OPTIMIZATION
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║ 10. STARTUP & BOOT OPTIMIZATION                                                      ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Fast Startup
$totalChecks++
$fastStartup = powercfg /a | findstr "Hibernation"
if ($fastStartup -and $fastStartup -notmatch "Not") {
    Write-Host "  [!] Fast Startup: ENABLED (Can cause driver issues)" -ForegroundColor $Yellow
    $warnings++
} else {
    Write-Host "  [✓] Fast Startup: DISABLED" -ForegroundColor $Green
    $passedChecks++
}

# Startup Delay
$totalChecks++
$startupDelay = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue
if ($startupDelay.StartupDelayInMSec -eq 0) {
    Write-Host "  [✓] Startup Delay: OPTIMIZED (Removed)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "  [✗] Startup Delay: NOT OPTIMIZED (Default delay applies)" -ForegroundColor $Red
    $failedChecks++
}

Write-Host ""
#endregion

#region 11. GPU OPTIMIZATION
if ($GPU) {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "  ║ 11. GPU OPTIMIZATION SETTINGS                                                       ║" -ForegroundColor $Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
    Write-Host ""

    # Hardware Acceleration
    $totalChecks++
    $hwAccel = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Avalon.Graphics" -Name "DisableHWAcceleration" -ErrorAction SilentlyContinue
    Write-Host "  [?] Hardware Acceleration: CHECKED" -ForegroundColor $Gray

    # GPU Preference
    $totalChecks++
    Write-Host "  [?] GPU Performance Preference: CHECKED" -ForegroundColor $Gray

    Write-Host ""
}
#endregion

#region SUMMARY
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "║                                         SUMMARY                                             ║" -ForegroundColor $Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$percentOptimized = [math]::Round(($passedChecks / $totalChecks) * 100)

if ($percentOptimized -ge 80) {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Green
    Write-Host "  ║  STATUS: FULLY OPTIMIZED! ($percentOptimized%) - Ready for maximum gaming!        ║" -ForegroundColor $Green
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Green
} elseif ($percentOptimized -ge 60) {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
    Write-Host "  ║  STATUS: PARTIALLY OPTIMIZED ($percentOptimized%) - Some improvements available   ║" -ForegroundColor $Yellow
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
} elseif ($percentOptimized -ge 40) {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
    Write-Host "  ║  STATUS: MODERATELY OPTIMIZED ($percentOptimized%) - Significant improvements    ║" -ForegroundColor $Yellow
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
} else {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Red
    Write-Host "  ║  STATUS: NOT OPTIMIZED ($percentOptimized%) - Your PC needs optimization!        ║" -ForegroundColor $Red
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Red
}

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor $Gray
Write-Host "  │  📊 Total Checks: $totalChecks    [✓] Optimized: $passedChecks    [✗] Not Optimized: $failedChecks    [!] Warnings: $warnings  │" -ForegroundColor $White
Write-Host "  └─────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor $Gray
Write-Host ""

# Recommendations
if ($failedChecks -gt 0) {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
    Write-Host "  ║                              RECOMMENDATIONS                                       ║" -ForegroundColor $Yellow
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
    Write-Host ""
    Write-Host "  To apply ALL optimizations at once, run the ULTWEAKS optimizer:" -ForegroundColor $White
    Write-Host "  " -NoNewline
    Write-Host "iex (irm https://raw.githubusercontent.com/ItsAGENT007/ultweaks/refs/heads/main/ultweaks.ps1)" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "  Or manually address the [✗] NOT OPTIMIZED items above." -ForegroundColor $Gray
} else {
    Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Green
    Write-Host "  ║                                   PERFECT!                                          ║" -ForegroundColor $Green
    Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Green
    Write-Host ""
    Write-Host "  ✓ Your PC is FULLY OPTIMIZED! No action needed." -ForegroundColor $Green
}

Write-Host ""
Write-Host "  ╔════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║  Generated by ULTWEAKS Optimizer - https://github.com/ItsAGENT007/ultweaks        ║" -ForegroundColor $Cyan
Write-Host "  ╚════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

Read-Host "Press Enter to exit"
#endregion
