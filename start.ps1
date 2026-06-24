Clear-Host
$ErrorActionPreference = "SilentlyContinue"

# =================================================================
#                 ONLINE LICENSE & GATEWAY LOCK
# =================================================================
$BaseApiUrl = "https://script.google.com/macros/s/AKfycbwubezdjjeeWz3nCFhsGmiSE8pldISEpuuLM_-V2WMl6ZQ8sZ-_6aicnFkmOroIIG7t6A/exec"
$MachineHWID = (Get-CimInstance Win32_ComputerSystemProduct).UUID

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       SYSTEM PERFORMANCE BOOSTER v1.0 - CORE      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Machine Hardware ID: $MachineHWID" -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan

# รับค่าคีย์จากผู้ใช้งาน
$UserKey = (Read-Host "[*] Please enter your License Key").Trim()

if ([string]::IsNullOrWhiteSpace($UserKey)) {
    Write-Host "[!] Verification Error: Key cannot be empty." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

Write-Host "`n[*] Synchronizing with cloud environment database..." -ForegroundColor Yellow

# ตรวจสอบสิทธิ์และเวลาการใช้งานกับ Google Sheets เบื้องหลัง
$RequestUrl = "$BaseApiUrl`?key=$UserKey&hwid=$MachineHWID"
try {
    $ApiResponse = Invoke-WebRequest -Uri $RequestUrl -Method Get -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    $ApiResponse = $ApiResponse.Trim()
} catch {
    Write-Host "[!] Gateway Error: Secure database connection failed." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# -----------------------------------------------------------------
# [SMART SCAN] ระบบตรวจจับตำแหน่งตัวเกมอัตโนมัติ (สแกนเร็วลึก 4 ชั้น)
# -----------------------------------------------------------------
$Drives = @("C:\", "D:\", "E:\", "F:\", "G:\")
$GamePath = $null

foreach ($Drive in $Drives) {
    if (Test-Path $Drive) {
        $FindFolder = Get-ChildItem -Path $Drive -Filter "WarZ*" -Recurse -Depth 4 -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object -First 1
        if ($FindFolder) {
            $CheckPath = Join-Path $FindFolder.FullName "Data"
            if (Test-Path $CheckPath) {
                $GamePath = $CheckPath
                break
            }
        }
    }
}

# -----------------------------------------------------------------
# [SAFETY OVERRIDE] หากระบบค้นหาไม่พบ ให้ผู้ใช้กรอกข้อมูลเองเพื่อป้องกันการระเบิดตัวแดง
# -----------------------------------------------------------------
if ($null -eq $GamePath) {
    Write-Host "`n[!] Notice: Automatic game directory detection bypassed." -ForegroundColor Yellow
    $UserPath = Read-Host "[*] Please input your main game directory path manually"
    $UserPath = $UserPath.Trim()
    if (Test-Path $UserPath) {
        if ($UserPath -like "*Data*") {
            $GamePath = $UserPath
        } elseif (Test-Path (Join-Path $UserPath "WarZTH\Data")) {
            $GamePath = Join-Path $UserPath "WarZTH\Data"
        } elseif (Test-Path (Join-Path $UserPath "Data")) {
            $GamePath = Join-Path $UserPath "Data"
        } else {
            $GamePath = Join-Path $UserPath "Data"
        }
    } else {
        Write-Host "[!] Fatal Error: Destination path does not exist." -ForegroundColor Red
        Read-Host "Press [Enter] to exit"; exit
    }
}

# -----------------------------------------------------------------
# EVALUATE CLOUD GATEWAY RESPONSE
# -----------------------------------------------------------------
if ($ApiResponse -eq "INVALID_KEY") {
    Write-Host "[!] Authorization Failed: Invalid client product key." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "HWID_MISMATCH") {
    Write-Host "`n[!] Security Violation Detected!" -ForegroundColor Red
    Write-Host "[-] This product license is strictly locked to another machine hardware configuration." -ForegroundColor Red
    Write-Host "[*] Account sharing policy violation. Access denied." -ForegroundColor Yellow
    Read-Host "`nPress [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "KEY_EXPIRED") {
    Write-Host "`n[!] License Period Expired: Revoking access permission." -ForegroundColor Red
    Write-Host "[*] Reverting environment variables and cleaning modules..." -ForegroundColor Yellow
    
    # ดำเนินการลบไฟล์ทันทีเมื่อคีย์หมดอายุ
    if (Test-Path $GamePath) {
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        if (Test-Path $TargetMenu) { Remove-Item $TargetMenu -Recurse -Force }
        if (Test-Path $TargetObjects) { Remove-Item $TargetObjects -Recurse -Force }
    }
    
    # คำสั่งทำลายตัวเอง (Self-Deletion) ลบสคริปต์นี้ทิ้งทันที
    Start-Process cmd -ArgumentList "/c del `"$PSCommandPath`"" -WindowStyle Hidden
    Write-Host "[DONE] Cleanup cycle completed successfully." -ForegroundColor Green
    Read-Host "`nPress [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "REGISTERED_SUCCESS" -or $ApiResponse -eq "ACCESS_GRANTED") {
    Write-Host "[DONE] Security Token Validated. Session Authorized." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
else {
    Write-Host "[!] Unhandled Kernel Error: $ApiResponse" -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# =================================================================
#                         MAIN DASHBOARD INTERFACE
# =================================================================
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "         FPS BOOSTER & OPTIMIZER UTILITY v1.0     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Target Storage Locked -> $GamePath" -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  [1] INJECT FPS OVERLOAD MODULE                  " -ForegroundColor Green
Write-Host "  [2] RESTORE & CLEAN CACHE SYSTEM                " -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Cyan

do {
    $Choice = Read-Host "Select execution mode (1/2)"
} while ($Choice -ne "1" -and $Choice -ne "2")

$DownloadUrl = "https://raw.githubusercontent.com/mastergamerk/Key-Warz/refs/heads/main/BootFPS.zip"
$TempZip = "$env:TEMP\warz_esp_temp.zip"

# MODE 1: ดาวน์โหลด ติดตั้ง และซ่อนไฟล์ระบบล่องหนเพื่อความปลอดภัย
if ($Choice -eq "1") {
    Write-Host "`n[*] Downloading performance assets from secure repository..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -ErrorAction Stop
        
        Write-Host "[*] Extracting and deploying optimization assets..." -ForegroundColor Yellow
        Expand-Archive -Path $TempZip -DestinationPath $GamePath -Force
        
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        
        # ล็อกแอตทริบิวต์เป็นไฟล์ระบบซ่อนล่องหน (Hidden + System)
        if (Test-Path $TargetMenu) { 
            Set-ItemProperty -Path $TargetMenu -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
        }
        if (Test-Path $TargetObjects) { 
            Set-ItemProperty -Path $TargetObjects -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
        }

        Write-Host "`n[DONE] Execution Success: Performance patch deployed smoothly." -ForegroundColor Green
    } catch {
        Write-Host "[!] Critical Deployment Failure: $_" -ForegroundColor Red
    }
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }

# MODE 2: เคลียร์ระบบให้สะอาดและตั้งค่าคืนสภาพเดิม
} elseif ($Choice -eq "2") {
    Write-Host "`n[*] Starting data integrity cleanup engine..." -ForegroundColor Yellow
    $TargetMenu = Join-Path $GamePath "Menu"
    $TargetObjects = Join-Path $GamePath "ObjectsDepot"
    
    if (Test-Path $TargetMenu) { 
        Remove-Item $TargetMenu -Recurse -Force
        Write-Host "[DONE] System cache database optimized successfully." -ForegroundColor DarkYellow 
    } else {
        Write-Host "[-] Main engine cache status: Verified Clean." -ForegroundColor Gray
    }
    
    if (Test-Path $TargetObjects) { 
        Remove-Item $TargetObjects -Recurse -Force
        Write-Host "[DONE] Game environment configuration restored." -ForegroundColor DarkYellow 
    } else {
        Write-Host "[-] Secondary storage database status: Verified Clean." -ForegroundColor Gray
    }
    
    Write-Host "`n[DONE] System environment restoration completely completed!" -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Read-Host "Press [Enter] to terminate dashboard session"
