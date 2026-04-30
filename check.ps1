<#
.SYNOPSIS
    ULTWEAKS - System Optimization Status Checker (PowerShell Version)
.DESCRIPTION
    Checks if Windows has been optimized for gaming performance
.NOTES
    Run as Administrator for complete results
#>

Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTWEAKS - System Optimization Checker"

# Colors
$Green = [ConsoleColor]::Green
$Red = [ConsoleColor]::Red
$Yellow = [ConsoleColor]::Yellow
$Cyan = [ConsoleColor]::Cyan
$White = [ConsoleColor]::White

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "║                    ULTWEAKS OPTIMIZATION STATUS CHECKER                     ║" -ForegroundColor $Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

# Check Admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($IsAdmin) {
    Write-Host "[✓] Running as Administrator" -ForegroundColor $Green
} else {
    Write-Host "[!] Not running as Administrator - some checks may be incomplete" -ForegroundColor $Red
}
Write-Host ""

$totalChecks = 0
$passedChecks = 0
$failedChecks = 0

# 1. CPU Priority
$totalChecks++
$cpuPriority = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
if ($cpuPriority.Win32PrioritySeparation -eq 38) {
    Write-Host "[✓] CPU Priority Separation: OPTIMIZED (38)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] CPU Priority Separation: DEFAULT ($($cpuPriority.Win32PrioritySeparation))" -ForegroundColor $Red
    $failedChecks++
}

# 2. Visual Effects
$totalChecks++
$visualFX = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
if ($visualFX.VisualFXSetting -eq 2) {
    Write-Host "[✓] Visual Effects: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Visual Effects: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# 3. Transparency
$totalChecks++
$transparency = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -ErrorAction SilentlyContinue
if ($transparency.EnableTransparency -eq 0) {
    Write-Host "[✓] Transparency Effects: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Transparency Effects: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# 4. Game Bar
$totalChecks++
$gameBar = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" -Name "UseGameBar" -ErrorAction SilentlyContinue
if ($gameBar.UseGameBar -eq 0) {
    Write-Host "[✓] Game Bar: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Game Bar: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# 5. Game DVR
$totalChecks++
$gameDVR = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue
if ($gameDVR.AppCaptureEnabled -eq 0) {
    Write-Host "[✓] Game DVR: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Game DVR: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# 6. Power Plan
$totalChecks++
$activePlan = powercfg /getactivescheme
if ($activePlan -match "High performance" -or $activePlan -match "Ultimate Performance") {
    Write-Host "[✓] Power Plan: OPTIMIZED (High Performance)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Power Plan: NOT OPTIMIZED (Balanced/Power Saver)" -ForegroundColor $Red
    $failedChecks++
}

# 7. Hibernation
$totalChecks++
$hiberFile = Get-ChildItem -Path "C:\hiberfil.sys" -ErrorAction SilentlyContinue
if (-not $hiberFile) {
    Write-Host "[✓] Hibernation: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Hibernation: NOT OPTIMIZED (Enabled)" -ForegroundColor $Red
    $failedChecks++
}

# 8. Services Check
$services = @(
    @{Name="SysMain"; Display="SysMain (Superfetch)"},
    @{Name="WSearch"; Display="Windows Search"},
    @{Name="DiagTrack"; Display="Diagnostic Tracking"},
    @{Name="XblAuthManager"; Display="Xbox Services"}
)

foreach ($svc in $services) {
    $totalChecks++
    $serviceStatus = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($serviceStatus.StartType -eq "Disabled") {
        Write-Host "[✓] $($svc.Display): OPTIMIZED (Disabled)" -ForegroundColor $Green
        $passedChecks++
    } else {
        Write-Host "[✗] $($svc.Display): NOT OPTIMIZED ($($serviceStatus.StartType))" -ForegroundColor $Red
        $failedChecks++
    }
}

# 9. Telemetry
$totalChecks++
$telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
if ($telemetry.AllowTelemetry -eq 0) {
    Write-Host "[✓] Telemetry: OPTIMIZED (Disabled)" -ForegroundColor $Green
    $passedChecks++
} else {
    Write-Host "[✗] Telemetry: NOT OPTIMIZED (Level $($telemetry.AllowTelemetry))" -ForegroundColor $Red
    $failedChecks++
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Yellow
$percentOptimized = [math]::Round(($passedChecks / $totalChecks) * 100)

if ($percentOptimized -ge 80) {
    Write-Host "STATUS: FULLY OPTIMIZED! ($percentOptimized%)" -ForegroundColor $Green
} elseif ($percentOptimized -ge 50) {
    Write-Host "STATUS: PARTIALLY OPTIMIZED ($percentOptimized%)" -ForegroundColor $Yellow
} else {
    Write-Host "STATUS: NOT OPTIMIZED ($percentOptimized%)" -ForegroundColor $Red
}

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor $Yellow
Write-Host ""
Write-Host "Total Checks: $totalChecks | [✓] Optimized: $passedChecks | [✗] Not Optimized: $failedChecks"
Write-Host ""

if ($failedChecks -gt 0) {
    Write-Host "To apply all optimizations, run:" -ForegroundColor $White
    Write-Host "iex (irm https://raw.githubusercontent.com/ItsAGENT007/ultweaks/refs/heads/main/ultweaks.ps1)" -ForegroundColor $Cyan
} else {
    Write-Host "✓ Your PC is already fully optimized!" -ForegroundColor $Green
}
Write-Host ""
Read-Host "Press Enter to exit"
