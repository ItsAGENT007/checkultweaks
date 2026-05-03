#Requires -RunAsAdministrator
<#
.SYNOPSIS
    ULTWEAKS - System Optimization Checker v3.0
.DESCRIPTION
    Cek status optimisasi sesuai dengan ULTWEAKS v11.0 + GPU Optimizer v5.0
    40+ poin dicek, output berwarna, ringkasan persentase
.NOTES
    Version: 3.0
    Diselaraskan dengan: ULTWEAKS_v11_FIXED.ps1 + ULTWEAKS_GPU_v5.ps1
#>

Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTWEAKS - System Checker v3.0"

$Green   = [ConsoleColor]::Green
$Red     = [ConsoleColor]::Red
$Yellow  = [ConsoleColor]::Yellow
$Cyan    = [ConsoleColor]::Cyan
$White   = [ConsoleColor]::White
$Gray    = [ConsoleColor]::Gray
$Magenta = [ConsoleColor]::Magenta

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║    ULTWEAKS - SYSTEM OPTIMIZATION CHECKER v3.0                  ║" -ForegroundColor $Cyan
Write-Host "  ║    Sesuai ULTWEAKS v11 + GPU Optimizer v5  |  50+ Poin          ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if ($IsAdmin) {
    Write-Host "  [OK] Berjalan sebagai Administrator — semua check tersedia" -ForegroundColor $Green
} else {
    Write-Host "  [!] Bukan Administrator — beberapa check tidak bisa dijalankan" -ForegroundColor $Red
    Write-Host "  Klik kanan PowerShell → Run as Administrator untuk hasil lengkap" -ForegroundColor $Yellow
}
Write-Host ""

# ── Counter ──────────────────────────────────────────────────────────────────
$total   = 0
$passed  = 0
$failed  = 0
$warning = 0
$skipped = 0

# Helper functions
function Check-OK   ($msg) { Write-Host "  [✓] $msg" -ForegroundColor $Green;   $script:passed++; $script:total++ }
function Check-FAIL ($msg) { Write-Host "  [✗] $msg" -ForegroundColor $Red;    $script:failed++; $script:total++ }
function Check-WARN ($msg) { Write-Host "  [!] $msg" -ForegroundColor $Yellow; $script:warning++; $script:total++ }
function Check-SKIP ($msg) { Write-Host "  [–] $msg" -ForegroundColor $Gray;   $script:skipped++; $script:total++ }
function Check-INFO ($msg) { Write-Host "  [i] $msg" -ForegroundColor $White }

function Section ($title) {
    Write-Host ""
    Write-Host "  ━━━ $title ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Cyan
}

function RegGet ($path, $name) {
    try { return (Get-ItemProperty -Path $path -Name $name -EA Stop).$name }
    catch { return $null }
}

#region SYSTEM INFO
Section "INFORMASI SISTEM"

$OSBuild  = [Environment]::OSVersion.Version.Build
$IsWin11  = $OSBuild -ge 22000
$OSName   = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue).ProductName
$CPU      = (Get-WmiObject Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name
$RAM      = [math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory / 1GB, 1)
$GPU      = Get-WmiObject Win32_VideoController -EA SilentlyContinue |
            Where-Object { $_.Name -notlike "*Mirror*" -and $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Basic*" } |
            Select-Object -First 1
$GPUName  = if ($GPU) { $GPU.Name } else { "Tidak terdeteksi" }
$IsNVIDIA = $GPUName -match "NVIDIA|GeForce|RTX|GTX"
$IsAMD    = $GPUName -match "AMD|Radeon|RX "

Check-INFO "OS      : $OSName (Build $OSBuild) $(if($IsWin11){'— Windows 11'}else{'— Windows 10'})"
Check-INFO "CPU     : $($CPU -replace '\s+',' ')"
Check-INFO "RAM     : ${RAM}GB"
Check-INFO "GPU     : $GPUName"

$disk = Get-PSDrive -Name C -EA SilentlyContinue
if ($disk) {
    $freeGB   = [math]::Round($disk.Free / 1GB, 1)
    $totalGB  = [math]::Round(($disk.Used + $disk.Free) / 1GB, 1)
    $freePct  = [math]::Round($freeGB / $totalGB * 100)
    Check-INFO "Disk C  : $freeGB GB free / $totalGB GB ($freePct% free)"
    if ($freePct -lt 15) { Check-WARN "Disk C hampir penuh (<15% free) — bisa memperlambat sistem" }
}
#endregion

#region POWER PLAN
Section "POWER PLAN & ENERGY"

# Active power plan
$activePlan = powercfg /getactivescheme 2>$null
if ($activePlan -match "Ultimate Performance") {
    Check-OK "Power Plan: Ultimate Performance (TERBAIK untuk gaming)"
} elseif ($activePlan -match "High performance") {
    Check-WARN "Power Plan: High Performance (bagus, tapi Ultimate lebih baik)"
} elseif ($activePlan -match "Balanced") {
    Check-FAIL "Power Plan: Balanced (tidak optimal untuk gaming)"
} else {
    Check-FAIL "Power Plan: Power Saver atau tidak dikenal (buruk untuk gaming)"
}

# Hibernation
$hib = Get-ChildItem "C:\hiberfil.sys" -EA SilentlyContinue
if (-not $hib) { Check-OK "Hibernation: Disabled (hemat disk)" }
else {
    $hibGB = [math]::Round($hib.Length / 1GB, 1)
    Check-WARN "Hibernation: Enabled (menggunakan ${hibGB}GB disk)"
}

# Sleep timeout
$sleepQ = powercfg -query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null
if ($sleepQ -match "0x00000000") { Check-OK "Sleep Timeout: Disabled" }
else { Check-WARN "Sleep Timeout: Enabled (PC bisa sleep saat game loading)" }

# USB Selective Suspend
$usbQ = powercfg -query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>$null
if ($usbQ -match "0x00000000") { Check-OK "USB Selective Suspend: Disabled (kurangi input lag)" }
else { Check-FAIL "USB Selective Suspend: Enabled (bisa tambah input lag)" }

# PCIe ASPM
$pcieQ = powercfg -query SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 2>$null
if ($pcieQ -match "0x00000000") { Check-OK "PCIe Link State Power Mgmt: Disabled" }
else { Check-WARN "PCIe Link State Power Mgmt: Enabled" }

# CPU Throttle max
$cpuThrotQ = powercfg -query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 2>$null
if ($cpuThrotQ -match "0x00000064") { Check-OK "CPU Max Performance: 100%" }
else { Check-FAIL "CPU Max Performance: Di bawah 100% (throttle aktif)" }
#endregion

#region CPU & REGISTRY
Section "CPU PRIORITY & REGISTRY PERFORMANCE"

$v = RegGet "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation"
if ($v -eq 38) { Check-OK "CPU Priority Separation: 38 (optimal gaming)" }
elseif ($v -eq 26 -or $v -eq 2) { Check-WARN "CPU Priority Separation: $v (default)" }
else { Check-FAIL "CPU Priority Separation: $v (tidak optimal)" }

$v = RegGet "HKCU:\Control Panel\Desktop" "ForegroundLockTimeout"
if ($v -eq 0) { Check-OK "Foreground Lock Timeout: 0" }
else { Check-WARN "Foreground Lock Timeout: $v (bukan 0)" }

$mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$v = RegGet $mmPath "SystemResponsiveness"
if ($v -eq 0) { Check-OK "SystemResponsiveness: 0 (game prioritas penuh)" }
else { Check-FAIL "SystemResponsiveness: $v (bukan 0)" }

$v = RegGet $mmPath "NetworkThrottlingIndex"
if ($v -eq 4294967295) { Check-OK "Network Throttling Index: Disabled" }
else { Check-FAIL "Network Throttling Index: Masih aktif ($v)" }

$gamePath = "$mmPath\Tasks\Games"
$gpuPrio  = RegGet $gamePath "GPU Priority"
$taskPrio = RegGet $gamePath "Priority"
$schedCat = RegGet $gamePath "Scheduling Category"
if ($gpuPrio -eq 8 -and $taskPrio -eq 6 -and $schedCat -eq "High") {
    Check-OK "Multimedia Games Task: GPU Priority 8, Priority 6, Scheduling High"
} else {
    Check-FAIL "Multimedia Games Task: Belum dioptimasi (GPU=$gpuPrio, Prio=$taskPrio, Sched=$schedCat)"
}

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec"
if ($v -eq 0) { Check-OK "Explorer Startup Delay: 0ms" }
else { Check-WARN "Explorer Startup Delay: Default (belum dihilangkan)" }
#endregion

#region VISUAL EFFECTS
Section "VISUAL EFFECTS & UI"

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting"
if ($v -eq 2) { Check-OK "Visual Effects: Performance mode (semua efek off)" }
elseif ($v -eq 1) { Check-WARN "Visual Effects: Let Windows choose" }
else { Check-FAIL "Visual Effects: Masih aktif (menggunakan resource)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency"
if ($v -eq 0) { Check-OK "Transparency Effects: Disabled" }
else { Check-FAIL "Transparency Effects: Enabled (buang resource GPU)" }

$v = RegGet "HKCU:\Control Panel\Desktop" "MenuShowDelay"
if ($v -eq "0" -or $v -eq 0) { Check-OK "Menu Show Delay: 0ms" }
elseif ([int]$v -le 100) { Check-WARN "Menu Show Delay: ${v}ms (belum 0)" }
else { Check-FAIL "Menu Show Delay: ${v}ms (default, tidak optimal)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations"
if ($v -eq 0) { Check-OK "Taskbar Animations: Disabled" }
else { Check-FAIL "Taskbar Animations: Enabled" }

$v = RegGet "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate"
if ($v -eq "0" -or $v -eq 0) { Check-OK "Window Minimize/Maximize Animations: Disabled" }
else { Check-FAIL "Window Minimize/Maximize Animations: Enabled" }
#endregion

#region GAME BAR & DVR
Section "GAME BAR & DVR"

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" "UseGameBar"
if ($v -eq 0) { Check-OK "Game Bar: Disabled" }
else { Check-FAIL "Game Bar: Enabled (buang resource)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled"
if ($v -eq 0) { Check-OK "Game DVR Capture: Disabled" }
else { Check-FAIL "Game DVR Capture: Enabled (recording background)" }

$v = RegGet "HKCU:\System\GameConfigStore" "GameDVR_Enabled"
if ($v -eq 0) { Check-OK "GameDVR Background: Disabled" }
else { Check-FAIL "GameDVR Background: Enabled" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameBar" "AutoGameModeEnabled"
if ($v -eq 0) { Check-OK "Auto Game Mode: Disabled (bisa konflik dengan beberapa game)" }
else { Check-WARN "Auto Game Mode: Enabled (umumnya tidak masalah, tapi matikan jika ada lag)" }
#endregion

#region GPU
Section "GPU OPTIMIZATION"

# MPO
$v = RegGet "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"
if ($v -eq 5) { Check-OK "MPO (Multi-Plane Overlay): Disabled — fix stuttering" }
else { Check-FAIL "MPO: Masih aktif (penyebab stuttering di NVIDIA & AMD)" }

# TDR
$tdrLevel = RegGet "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrLevel"
$tdrDelay = RegGet "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay"
if ($tdrLevel -eq 3 -and $tdrDelay -ge 10) {
    Check-OK "GPU TDR: Level=3 (recovery aktif), Delay=${tdrDelay}s — aman"
} elseif ($tdrLevel -eq 0) {
    Check-WARN "GPU TDR Level=0 — recovery MATI (GPU hang = langsung BSOD/freeze, berbahaya)"
} else {
    Check-WARN "GPU TDR: Level=$tdrLevel, Delay=$tdrDelay (tidak optimal)"
}

# HAGS
$hags = RegGet "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
if ($IsNVIDIA -or $IsAMD) {
    if ($hags -eq 2) { Check-OK "HAGS (Hardware Accelerated GPU Scheduling): Enabled" }
    else { Check-FAIL "HAGS: Disabled (aktifkan untuk NVIDIA RTX/AMD RX 5000+)" }
} else {
    Check-SKIP "HAGS: GPU tidak terdeteksi sebagai NVIDIA/AMD"
}

# NVIDIA specific
if ($IsNVIDIA) {
    $adapterBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $nvidiaPath  = $null
    foreach ($i in @("0000","0001","0002","0003")) {
        $p    = "$adapterBase\$i"
        $desc = RegGet $p "DriverDesc"
        if ($desc -and $desc -match "NVIDIA|GeForce|RTX|GTX") { $nvidiaPath = $p; break }
    }

    if ($nvidiaPath) {
        $pmSrc = RegGet $nvidiaPath "PerfLevelSrc"
        $pmLvl = RegGet $nvidiaPath "PowerMizerLevel"
        if ($pmSrc -eq 0x2222 -and $pmLvl -eq 1) {
            Check-OK "NVIDIA PowerMizer: Prefer Maximum Performance (PerfLevelSrc=0x2222)"
        } else {
            Check-FAIL "NVIDIA PowerMizer: Belum diset ke Max Performance (PerfLevelSrc=$pmSrc)"
        }

        $nvParam = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters"
        $v = RegGet $nvParam "DisableDynamicPstate"
        if ($v -eq 1) { Check-OK "NVIDIA Dynamic Pstate: Disabled (clock lebih stabil)" }
        else { Check-WARN "NVIDIA Dynamic Pstate: Enabled (clock bisa turun saat idle game)" }
    } else {
        Check-SKIP "NVIDIA registry path tidak ditemukan"
    }

    # Telemetry service
    $nts = Get-Service -Name "NvTelemetryContainer" -EA SilentlyContinue
    if ($nts -and $nts.StartType -eq "Disabled") {
        Check-OK "NVIDIA Telemetry Service: Disabled"
    } else {
        Check-WARN "NVIDIA Telemetry Service: Masih aktif (buang resource kecil)"
    }
}

# AMD specific
if ($IsAMD) {
    $adapterBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $amdPath = $null
    foreach ($i in @("0000","0001","0002","0003")) {
        $p    = "$adapterBase\$i"
        $desc = RegGet $p "DriverDesc"
        if ($desc -and $desc -match "AMD|Radeon|RX ") { $amdPath = $p; break }
    }

    if ($amdPath) {
        $v = RegGet $amdPath "EnableUlps"
        if ($v -eq 0) { Check-OK "AMD ULPS: Disabled (GPU tidak sleep saat idle)" }
        else { Check-FAIL "AMD ULPS: Enabled (penyebab micro-stutter saat GPU idle)" }

        $v = RegGet $amdPath "PP_DeepSleepDisable"
        if ($v -eq 1) { Check-OK "AMD Deep Sleep: Disabled" }
        else { Check-WARN "AMD Deep Sleep: Enabled" }

        $v = RegGet $amdPath "DisableDMACopy"
        if ($v -eq 1) { Check-OK "AMD DMA Copy overhead: Disabled" }
        else { Check-WARN "AMD DMA Copy: Enabled (sedikit overhead)" }

        $v = RegGet $amdPath "KMD_EnableComputePreemption"
        if ($v -eq 0) { Check-OK "AMD Compute Preemption: Disabled (FPS lebih stabil)" }
        else { Check-WARN "AMD Compute Preemption: Enabled" }
    } else {
        Check-SKIP "AMD registry path tidak ditemukan"
    }
}

# DWM MaxPreRendered
$v = RegGet "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "MaxPreRendered"
if ($v -eq 1) { Check-OK "DWM MaxPreRendered: 1 (lower input latency)" }
else { Check-WARN "DWM MaxPreRendered: Default (belum diset ke 1)" }
#endregion

#region NETWORK
Section "NETWORK OPTIMIZATION"

# DNS
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if ($adapters) {
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapters.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).ServerAddresses
    if ($dns -contains "1.1.1.1") { Check-OK "DNS: Cloudflare (1.1.1.1) — fast & private" }
    elseif ($dns -contains "8.8.8.8") { Check-WARN "DNS: Google (8.8.8.8) — bagus tapi Cloudflare lebih cepat" }
    else { Check-WARN "DNS: $($dns -join ', ') (bukan Cloudflare/Google)" }
}

# Nagle's Algorithm — cek interface yang punya IP
$nagles = $false
$tcpIfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" -EA SilentlyContinue
foreach ($iface in $tcpIfaces) {
    $ip = RegGet $iface.PSPath "DhcpIPAddress"
    if ($ip -and $ip -ne "0.0.0.0") {
        $ack = RegGet $iface.PSPath "TcpAckFrequency"
        $nd  = RegGet $iface.PSPath "TCPNoDelay"
        if ($ack -eq 1 -and $nd -eq 1) { $nagles = $true; break }
    }
}
if ($nagles) { Check-OK "Nagle's Algorithm: Disabled (TcpAckFrequency=1, TCPNoDelay=1)" }
else { Check-FAIL "Nagle's Algorithm: Enabled (tambah latency 10-20ms)" }

# TCP RSS
$rss = netsh int tcp show global 2>$null | Select-String "Receive-Side Scaling"
if ($rss -match "enabled") { Check-OK "TCP RSS (Receive-Side Scaling): Enabled" }
else { Check-WARN "TCP RSS: Disabled" }

# P2P Windows Update
$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode"
if ($v -eq 0) { Check-OK "Windows Update P2P Delivery: Disabled (tidak pakai bandwidth)" }
else { Check-WARN "Windows Update P2P: Enabled (berbagi bandwidth ke orang lain)" }

# Windows Update mode
$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions"
if ($v -eq 2) { Check-OK "Windows Update: Notify Only (tidak auto-download)" }
elseif ($v -eq 1) { Check-WARN "Windows Update: Disabled penuh (tidak direkomendasikan, security risk)" }
else { Check-WARN "Windows Update: Auto-download aktif (bisa mengganggu saat gaming)" }
#endregion

#region SERVICES
Section "BLOAT SERVICES (Disabled = Optimal)"

$serviceChecks = @(
    @{Name="DiagTrack";     Label="Connected User Experiences & Telemetry"},
    @{Name="DPS";           Label="Diagnostic Policy Service"},
    @{Name="WdiServiceHost";Label="Diagnostic Service Host"},
    @{Name="WdiSystemHost"; Label="Diagnostic System Host"},
    @{Name="WerSvc";        Label="Windows Error Reporting"},
    @{Name="XblAuthManager";Label="Xbox Live Auth Manager"},
    @{Name="XboxNetApiSvc"; Label="Xbox Live Networking"},
    @{Name="XboxGipSvc";    Label="Xbox Accessory Management"},
    @{Name="BcastDVRUserService"; Label="GameDVR Broadcast Service"},
    @{Name="WSearch";       Label="Windows Search (Indexing)"},
    @{Name="RemoteRegistry";Label="Remote Registry"},
    @{Name="RemoteAccess";  Label="Routing & Remote Access"},
    @{Name="Fax";           Label="Fax Service"},
    @{Name="WMPNetworkSvc"; Label="Windows Media Player Network"},
    @{Name="lfsvc";         Label="Geolocation Service"},
    @{Name="MapsBroker";    Label="Downloaded Maps Manager"},
    @{Name="CDPSvc";        Label="Connected Devices Platform"},
    @{Name="WpnService";    Label="Windows Push Notifications"},
    @{Name="PcaSvc";        Label="Program Compatibility Assistant"},
    @{Name="RetailDemo";    Label="Retail Demo Service"},
    @{Name="SysMain";       Label="SysMain/Superfetch"}
)

# Yang HARUS tetap Running (safety check)
$mustRun = @("WlanSvc","AudioSrv","AudioEndpointBuilder","EventLog","PlugPlay","RpcSs","Dhcp","Dnscache","BFE","mpssvc")
Write-Host "  [i] WiFi, Audio, dan service penting lain dikecualikan dari check ini" -ForegroundColor $White

foreach ($svc in $serviceChecks) {
    $s = Get-Service -Name $svc.Name -EA SilentlyContinue
    if (-not $s) {
        Check-SKIP "$($svc.Label): Tidak ada di sistem ini"
        continue
    }
    if ($s.StartType -eq "Disabled") {
        Check-OK "$($svc.Label): Disabled"
    } elseif ($s.StartType -eq "Manual") {
        Check-WARN "$($svc.Label): Manual (bukan Disabled)"
    } else {
        Check-FAIL "$($svc.Label): Running (buang resource)"
    }
}

# Safety check — pastikan service penting masih jalan
Write-Host ""
Write-Host "  [i] Safety check — service penting:" -ForegroundColor $White
foreach ($svcName in @("WlanSvc","AudioSrv","EventLog")) {
    $s = Get-Service -Name $svcName -EA SilentlyContinue
    if ($s -and $s.Status -eq "Running") {
        Write-Host "  [✓] $svcName (${($s.DisplayName)}): Running (BENAR)" -ForegroundColor $Green
    } elseif ($s -and $s.Status -ne "Running") {
        Write-Host "  [!] $svcName (${($s.DisplayName)}): $($s.Status) — SEHARUSNYA RUNNING!" -ForegroundColor $Red
    }
}
#endregion

#region PRIVACY & TELEMETRY
Section "PRIVACY & TELEMETRY"

$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
if ($v -eq 0) { Check-OK "Telemetry: Disabled (level 0)" }
elseif ($v -eq 1) { Check-WARN "Telemetry: Basic (level 1)" }
else { Check-FAIL "Telemetry: Full (level $v — mengirim data ke Microsoft)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled"
if ($v -eq 0) { Check-OK "Toast Notifications: Disabled" }
else { Check-WARN "Toast Notifications: Enabled (bisa muncul saat game)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled"
if ($v -eq 1) { Check-OK "Background Apps: Disabled" }
else { Check-FAIL "Background Apps: Enabled (berjalan di background)" }

$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"
if ($v -eq 0) { Check-OK "Cortana: Disabled" }
else { Check-WARN "Cortana: Enabled (berjalan di background)" }

$v = RegGet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled"
if ($v -eq 0) { Check-OK "Bing Search di Start Menu: Disabled" }
else { Check-WARN "Bing Search: Enabled (menggunakan internet saat search)" }

$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy"
if ($v -eq 1) { Check-OK "Advertising ID: Disabled" }
else { Check-WARN "Advertising ID: Enabled" }

$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"
if ($v -eq 0) { Check-OK "Activity History: Disabled" }
else { Check-WARN "Activity History: Enabled" }

$v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
if ($v -eq 1) { Check-OK "Windows Copilot: Disabled" }
else { Check-WARN "Windows Copilot: Enabled" }
#endregion

#region MEMORY
Section "MEMORY & STORAGE"

$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory / 1GB)
$mmMgmt = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

$v = RegGet $mmMgmt "DisablePagingExecutive"
if ($ramGB -ge 8) {
    if ($v -eq 1) { Check-OK "Kernel Paging Disabled: Ya (RAM=${ramGB}GB — aman)" }
    else { Check-WARN "Kernel Paging: Masih aktif (RAM ${ramGB}GB, bisa dimatikan)" }
} else {
    if ($v -eq 1) { Check-WARN "Kernel Paging Disabled: Ya — tapi RAM hanya ${ramGB}GB, berisiko!" }
    else { Check-OK "Kernel Paging: Aktif (RAM hanya ${ramGB}GB — ini benar)" }
}

$v = RegGet $mmMgmt "LargeSystemCache"
if ($v -eq 0) { Check-OK "LargeSystemCache: 0 (benar untuk gaming)" }
elseif ($v -eq 1) { Check-WARN "LargeSystemCache: 1 (setting server, bukan optimal untuk gaming)" }
else { Check-WARN "LargeSystemCache: Default" }

$lastAccess = fsutil behavior query disablelastaccess 2>$null
if ($lastAccess -match "1") { Check-OK "NTFS Last Access Time: Disabled (akses file lebih cepat)" }
else { Check-WARN "NTFS Last Access Time: Enabled" }

$dot3 = fsutil behavior query disable8dot3 2>$null
if ($dot3 -match "1") { Check-OK "NTFS 8.3 Filename: Disabled" }
else { Check-WARN "NTFS 8.3 Filename: Enabled" }
#endregion

#region MOUSE
Section "MOUSE & INPUT"

$spd = RegGet "HKCU:\Control Panel\Mouse" "MouseSpeed"
$t1  = RegGet "HKCU:\Control Panel\Mouse" "MouseThreshold1"
$t2  = RegGet "HKCU:\Control Panel\Mouse" "MouseThreshold2"
if (($spd -eq "0" -or $spd -eq 0) -and ($t1 -eq "0" -or $t1 -eq 0) -and ($t2 -eq "0" -or $t2 -eq 0)) {
    Check-OK "Mouse Acceleration: Disabled (pointer precision off — aim lebih konsisten)"
} else {
    Check-FAIL "Mouse Acceleration: Enabled (Speed=$spd, T1=$t1, T2=$t2)"
}
#endregion

#region WINDOWS 11 SPECIFIC
if ($IsWin11) {
    Section "WINDOWS 11 SPECIFIC"

    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    $v = RegGet $adv "TaskbarDa"
    if ($v -eq 0) { Check-OK "Widgets: Disabled (hemat RAM/CPU)" }
    else { Check-FAIL "Widgets: Enabled (berjalan di background)" }

    $v = RegGet $adv "TaskbarMn"
    if ($v -eq 0) { Check-OK "Chat (Teams) Taskbar: Disabled" }
    else { Check-WARN "Chat (Teams): Enabled di taskbar" }

    $v = RegGet $adv "EnableSnapAssistFlyout"
    if ($v -eq 0) { Check-OK "Snap Assist Flyout: Disabled" }
    else { Check-WARN "Snap Assist Flyout: Enabled" }

    $v = RegGet $adv "Start_IrisRecommendations"
    if ($v -eq 0) { Check-OK "Recommended Files di Start: Disabled" }
    else { Check-WARN "Recommended Files: Enabled" }

    $v = RegGet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
    if ($v -eq 1) { Check-OK "Windows Copilot: Disabled" }
    else { Check-WARN "Copilot: Enabled (buang resource)" }
}
#endregion

#region SCHEDULED TASKS
Section "TELEMETRY SCHEDULED TASKS (Disabled = Optimal)"

$taskChecks = @(
    @{Path="\Microsoft\Windows\Customer Experience Improvement Program\"; Name="Consolidator"},
    @{Path="\Microsoft\Windows\Customer Experience Improvement Program\"; Name="KernelCeipTask"},
    @{Path="\Microsoft\Windows\Customer Experience Improvement Program\"; Name="UsbCeip"},
    @{Path="\Microsoft\Windows\Application Experience\";                  Name="ProgramDataUpdater"},
    @{Path="\Microsoft\Windows\Application Experience\";                  Name="StartupAppTask"},
    @{Path="\Microsoft\Windows\DiskDiagnostic\";                          Name="Microsoft-Windows-DiskDiagnosticDataCollector"},
    @{Path="\Microsoft\Windows\Feedback\Siuf\";                           Name="DmClient"},
    @{Path="\Microsoft\Windows\Location\";                                Name="Notifications"},
    @{Path="\Microsoft\Windows\Maps\";                                    Name="MapsUpdateTask"}
)

foreach ($t in $taskChecks) {
    $task = Get-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -EA SilentlyContinue
    if (-not $task) {
        Check-SKIP "$($t.Name): Tidak ada"
    } elseif ($task.State -eq "Disabled") {
        Check-OK "$($t.Name): Disabled"
    } else {
        Check-WARN "$($t.Name): $($task.State) (belum dimatikan)"
    }
}
#endregion

#region FINAL SUMMARY
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "  ║                        HASIL SUMMARY                            ║" -ForegroundColor $Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
Write-Host ""

$pctOptimized = if ($total -gt 0) { [math]::Round($passed / ($total - $skipped) * 100) } else { 0 }

Write-Host "  Total Check  : $total" -ForegroundColor $White
Write-Host "  ✓ Optimal    : $passed" -ForegroundColor $Green
Write-Host "  ✗ Tidak OK   : $failed" -ForegroundColor $Red
Write-Host "  ! Warning    : $warning" -ForegroundColor $Yellow
Write-Host "  – Skip       : $skipped" -ForegroundColor $Gray
Write-Host ""

if ($pctOptimized -ge 85) {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Green
    Write-Host "  ║  STATUS: FULLY OPTIMIZED ($pctOptimized%) — Siap gaming maksimal! ║" -ForegroundColor $Green
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Green
} elseif ($pctOptimized -ge 65) {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
    Write-Host "  ║  STATUS: SEBAGIAN OPTIMAL ($pctOptimized%) — Ada yang perlu fix  ║" -ForegroundColor $Yellow
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
} elseif ($pctOptimized -ge 40) {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Yellow
    Write-Host "  ║  STATUS: CUKUP ($pctOptimized%) — Banyak yang bisa ditingkatkan  ║" -ForegroundColor $Yellow
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Yellow
} else {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $Red
    Write-Host "  ║  STATUS: BELUM OPTIMAL ($pctOptimized%) — Jalankan ULTWEAKS!     ║" -ForegroundColor $Red
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $Red
}

Write-Host ""
if ($failed -gt 0 -or $warning -gt 0) {
    Write-Host "  Untuk apply semua optimisasi sekaligus, jalankan:" -ForegroundColor $Yellow
    Write-Host "  1. ULTWEAKS_v11_FIXED.ps1   — System optimizer utama" -ForegroundColor $White
    Write-Host "  2. ULTWEAKS_GPU_v5.ps1      — GPU optimizer" -ForegroundColor $White
    Write-Host ""
    Write-Host "  Klik kanan file .ps1 → Run with PowerShell → pilih Y" -ForegroundColor $White
}

Write-Host ""
Read-Host "  Tekan Enter untuk keluar"
#endregion
