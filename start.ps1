Clear-Host
$ErrorActionPreference = "SilentlyContinue"

# =================================================================
#                 ONLINE API GATEWAY LOCK
# =================================================================
$BaseApiUrl = "https://script.google.com/macros/s/AKfycbx70s0osxkl4yUHb0O0nIpXZD85cGBiwc02VCgV_yCUsYCOG54q90PLwXqUJ4qSM8rhrQ/exec"

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
# ระบบสแกนหาโฟลเดอร์เกมอัจฉริยะ (รองรับทุกชื่อโฟลเดอร์แบบมี/ไม่มีเว้นวรรค)
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
# ประเมินผลลัพธ์การตอบกลับจาก Google Sheet
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
    
    if ($null -ne $GamePath) {
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
Write-Host "  [1] INSTALL                                     " -ForegroundColor Green
Write-Host "  [2] CLEAN                                       " -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Cyan

do {
    $Choice = Read-Host "Select an option (1/2)"
} while ($Choice -ne "1" -and $Choice -ne "2")

if ($null -eq $GamePath) {
    Write-Host "[!] Unable to detect game directory automatically." -ForegroundColor Red
    $UserPath = Read-Host "Please enter your main game path (e.g., D:\WarZTH_FullClient)"
    if (Test-Path $UserPath) {
        $GamePath = Join-Path $UserPath "WarZTH\Data"
    } else {
        Write-Host "[!] Invalid path directory. Execution aborted." -ForegroundColor Red
        Read-Host "Press [Enter] to exit"; exit
    }
} else {
    Write-Host "[✓] Target directory locked: $GamePath" -ForegroundColor Green
}

$TempZip = "$env:TEMP\warz_esp_temp.zip"

# โหมดที่ 1: ดึงไฟล์แบบปลอดภัย และติดตั้งซ่อนระบบ
if ($Choice -eq "1") {
    Write-Host "`n[*] Requesting secure modules from remote gateway..." -ForegroundColor Yellow
    try {
        # ยิงขอไฟล์แบบปลอดภัย ส่งคำสั่ง action=download ไปที่หลังบ้าน
        $SecureRequestUrl = "$BaseApiUrl`?key=$UserKey&hwid=$MachineHWID&action=download"
        $Base64Data = Invoke-WebRequest -Uri $SecureRequestUrl -Method Get -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
        $Base64Data = $Base64Data.Trim()
        
        if ($Base64Data -like "ERROR*" -or $Base64Data -eq "INVALID_KEY" -or $Base64Data -eq "KEY_EXPIRED" -or $Base64Data -eq "HWID_MISMATCH") {
            Write-Host "[!] Secure download verification failed: $Base64Data" -ForegroundColor Red
            Read-Host "Press [Enter] to exit"; exit
        }
        
        Write-Host "[*] Reassembling binary assets..." -ForegroundColor Yellow
        # แปลงรหัสไฟล์ Base64 กลับมาเป็นไฟล์ Zip จบในแรมและเขียนลง Temp
        $Bytes = [System.Convert]::FromBase64String($Base64Data)
        [System.IO.File]::WriteAllBytes($TempZip, $Bytes)
        
        Write-Host "[*] Extracting module assets into system storage..." -ForegroundColor Yellow
        Expand-Archive -Path $TempZip -DestinationPath $GamePath -Force
        
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        
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

# โหมดที่ 2: คลีนเกมสะอาด
} elseif ($Choice -eq "2") {
    Write-Host "`n[*] Purging injected modules from directory database..." -ForegroundColor Yellow
    $TargetMenu = Join-Path $GamePath "Menu"
    $TargetObjects = Join-Path $GamePath "ObjectsDepot"
    
    if (Test-Path $TargetMenu) { Remove-Item $TargetMenu -Recurse -Force; Write-Host "[✓] 'Menu' module unlinked." -ForegroundColor DarkYellow }
    if (Test-Path $TargetObjects) { Remove-Item $TargetObjects -Recurse -Force; Write-Host "[✓] 'ObjectsDepot' module unlinked." -ForegroundColor DarkYellow }
    
    Write-Host "`n[✓] Environment restoration completely success!" -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Read-Host "Press [Enter] to terminate program"
