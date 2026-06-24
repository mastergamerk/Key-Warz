Clear-Host
$ErrorActionPreference = "SilentlyContinue"

# =================================================================
#                 ONLINE API GATEWAY LOCK
# =================================================================
# ลิงก์ Web App URL ตัวล่าสุดที่สหายเพิ่งคัดลอกมา
$BaseApiUrl = "https://script.google.com/macros/s/AKfycbxrb5Z-xY32hgYOFCCTrIqCMhoi5kvsGWFqK1SCxaIHWiUllWEg231RqflK6BAuttQi/exec"

# ดึงค่า HWID (UUID) ประจำเครื่องคอมพิวเตอร์ของลูกค้าอัตโนมัติ
$MachineHWID = (Get-CimInstance Win32_ComputerSystemProduct).UUID

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "         WarZ TH ESP Player - SECURITY            " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Your Machine HWID: $MachineHWID" -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan

# รับค่าคีย์จากลูกค้า
$UserKey = (Read-Host "[*] Please enter your License Key").Trim()

if ([string]::IsNullOrWhiteSpace($UserKey)) {
    Write-Host "[!] Key cannot be empty. Access Denied." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

Write-Host "[*] Connecting to cloud license database..." -ForegroundColor Yellow

# ยิงสอบถามและบันทึกข้อมูลกับระบบ Google Sheets เบื้องหลัง
$RequestUrl = "$BaseApiUrl`?key=$UserKey&hwid=$MachineHWID"
try {
    $ApiResponse = Invoke-WebRequest -Uri $RequestUrl -Method Get -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    $ApiResponse = $ApiResponse.Trim()
} catch {
    Write-Host "[!] Database Connection Error. Please try again later." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# -----------------------------------------------------------------
# 1. ระบบสแกนหาโฟลเดอร์เกมอัจฉริยะ (ย้ายขึ้นมาทำก่อนเพื่อป้องกันค่าว่าง)
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
# 2. ระบบเซฟตี้สำรอง: ถ้าตรวจจับออโต้ไม่เจอ ให้ลูกค้ากรอกเองทันทีตรงนี้ ป้องกันการระเบิดตัวแดง
# -----------------------------------------------------------------
if ($null -eq $GamePath) {
    Write-Host "`n[!] Unable to detect game directory automatically." -ForegroundColor Yellow
    $UserPath = Read-Host "[*] Please enter your main game folder path (e.g., D:\WarZTH_FullClient)"
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
        Write-Host "[!] Invalid path directory. Execution aborted." -ForegroundColor Red
        Read-Host "Press [Enter] to exit"; exit
    }
}

# -----------------------------------------------------------------
# 3. ประเมินผลลัพธ์การตอบกลับจาก Google Sheet
# -----------------------------------------------------------------
if ($ApiResponse -eq "INVALID_KEY") {
    Write-Host "[!] Invalid License Key! Access Denied." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "HWID_MISMATCH") {
    Write-Host "`n[!] Authentication Failed!" -ForegroundColor Red
    Write-Host "[-] This key is already registered to another PC hardware." -ForegroundColor Red
    Write-Host "[*] 1 Key = 1 PC Only. Sharing licenses is strictly prohibited." -ForegroundColor Yellow
    Read-Host "`nPress [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "KEY_EXPIRED") {
    Write-Host "`n[!] License Expired! Access Denied." -ForegroundColor Red
    Write-Host "[*] Purging active system modules from directory..." -ForegroundColor Yellow
    
    if (Test-Path $GamePath) {
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        if (Test-Path $TargetMenu) { Remove-Item $TargetMenu -Recurse -Force }
        if (Test-Path $TargetObjects) { Remove-Item $TargetObjects -Recurse -Force }
    }
    
    Start-Process cmd -ArgumentList "/c del `"$PSCommandPath`"" -WindowStyle Hidden
    Write-Host "[✓] System cleanup completed. License revoked." -ForegroundColor Green
    Read-Host "`nPress [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "REGISTERED_SUCCESS" -or $ApiResponse -eq "ACCESS_GRANTED") {
    Write-Host "[✓] Access Authorized! Verified." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
else {
    Write-Host "[!] Unknown Error: $ApiResponse" -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# =================================================================
#         MAIN INTERFACE (RUNS ONLY IF VALIDATED SUCCESS)
# =================================================================
  Clear-Host
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "         WarZ TH ESP Player Installer v1.0        " -ForegroundColor Cyan
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "Target Directory Locked: $GamePath" -ForegroundColor DarkGray
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "  [1] INSTALL                                     " -ForegroundColor Green
  Write-Host "  [2] CLEAN                                       " -ForegroundColor Red
  Write-Host "==================================================" -ForegroundColor Cyan

do {
    $Choice = Read-Host "Select an option (1/2)"
} while ($Choice -ne "1" -and $Choice -ne "2")

$TempZip = "$env:TEMP\warz_esp_temp.zip"

# โหมดที่ 1: ดึงไฟล์แบบปลอดภัยผ่านเว็บแอปหลังบ้าน (ปลอดภัยจาก AI และคนแกะลิงก์ 100%)
if ($Choice -eq "1") {
    Write-Host "`n[*] Requesting secure modules from remote gateway..." -ForegroundColor Yellow
    try {
        # ส่งคำสั่งขอไฟล์ดาวน์โหลดพ่วง action=download ไปที่ Google Apps Script
        $SecureRequestUrl = "$BaseApiUrl`?key=$UserKey&hwid=$MachineHWID&action=download"
        $Base64Data = Invoke-WebRequest -Uri $SecureRequestUrl -Method Get -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
        $Base64Data = $Base64Data.Trim()
        
        if ($Base64Data -like "ERROR*" -or $Base64Data -eq "INVALID_KEY" -or $Base64Data -eq "KEY_EXPIRED" -or $Base64Data -eq "HWID_MISMATCH") {
            Write-Host "[!] Secure download verification failed: $Base64Data" -ForegroundColor Red
            Read-Host "Press [Enter] to exit"; exit
        }
        
        Write-Host "[*] Reassembling binary assets..." -ForegroundColor Yellow
        # แปลงข้อมูล Base64 กลับมาเป็นไฟล์ Zip ในเครื่องคอมพิวเตอร์
        $Bytes = [System.Convert]::FromBase64String($Base64Data)
        [System.IO.File]::WriteAllBytes($TempZip, $Bytes)
        
        Write-Host "[*] Extracting module assets into system storage..." -ForegroundColor Yellow
        Expand-Archive -Path $TempZip -DestinationPath $GamePath -Force
        
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        
        # ตั้งค่าล่องหนขั้นสุด
        if (Test-Path $TargetMenu) { 
            Set-ItemProperty -Path $TargetMenu -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
        }
        if (Test-Path $TargetObjects) { 
            Set-ItemProperty -Path $TargetObjects -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
        }

        Write-Host "`n[✓] Installation completed! Assets successfully injected." -ForegroundColor Green
    } catch {
        Write-Host "[!] Critical Error encountered during execution: $_" -ForegroundColor Red
    }
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }

# โหมดที่ 2: คลีนเกมสะอาดแบบไร้เออร์เรอร์
} elseif ($Choice -eq "2") {
    Write-Host "`n[*] Purging injected modules from directory database..." -ForegroundColor Yellow
    $TargetMenu = Join-Path $GamePath "Menu"
    $TargetObjects = Join-Path $GamePath "ObjectsDepot"
    
    if (Test-Path $TargetMenu) { 
        Remove-Item $TargetMenu -Recurse -Force
        Write-Host "[✓] 'Menu' module unlinked." -ForegroundColor DarkYellow 
    } else {
        Write-Host "[-] 'Menu' module not found (Already clean)." -ForegroundColor Gray
    }
    
    if (Test-Path $TargetObjects) { 
        Remove-Item $TargetObjects -Recurse -Force
        Write-Host "[✓] 'ObjectsDepot' module unlinked." -ForegroundColor DarkYellow 
    } else {
        Write-Host "[-] 'ObjectsDepot' module not found (Already clean)." -ForegroundColor Gray
    }
    
    Write-Host "`n[✓] Environment restoration completely success!" -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Read-Host "Press [Enter] to terminate program"
