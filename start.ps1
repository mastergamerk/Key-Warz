Clear-Host
$ErrorActionPreference = "SilentlyContinue"

# =================================================================
#                     ONLINE API GATEWAY LOCK
# =================================================================
$BaseApiUrl = "https://script.google.com/macros/s/AKfycbzzyUPzlxq7ahufC_vvNF4VU5KhWApMKWrr54Oy7_rxdXpOkx5AGr_joPJnsiWfan_tBA/exec"

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

# ประเมินผลลัพธ์การตอบกลับจาก Google Sheet
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
elseif ($ApiResponse -eq "REGISTERED_SUCCESS") {
    Write-Host "[✓] First time activation success! Locked to this PC." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
elseif ($ApiResponse -eq "ACCESS_GRANTED") {
    Write-Host "[✓] Access Granted! Verified Hardware ID." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
else {
    Write-Host "[!] Unknown Error: $ApiResponse" -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# =================================================================
#        MAIN INTERFACE (RUNS ONLY IF VALIDATED SUCCESS)
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

# ระบบสแกนหาโฟลเดอร์เกมอัตโนมัติทุกไดรฟ์
Write-Host "`n[*] Scanning storage drives for game directories..." -ForegroundColor Yellow

$Drives = @("C:\", "D:\", "E:\", "F:\", "G:\")
$GamePath = $null

foreach ($Drive in $Drives) {
    if (Test-Path $Drive) {
        $FindFolder = Get-ChildItem -Path $Drive -Filter "WarZTH_FullClient" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($FindFolder) {
            $GamePath = Join-Path $FindFolder.FullName "WarZTH\Data"
            break
        }
    }
}

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

# ลิงก์ดาวน์โหลดไฟล์มอด Zip จากหน้า GitHub ของคุณ
$DownloadUrl = "https://raw.githubusercontent.com/ชื่อผู้ใช้/ชื่อคลัง/main/PIRIYA%20V1.zip" 
$TempZip = "$env:TEMP\warz_esp_temp.zip"

# โหมดที่ 1: แตกไฟล์ติดตั้ง และสั่งซ่อนระบบล่องหนทันที
if ($Choice -eq "1") {
    Write-Host "`n[*] Fetching core modules from remote server..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -ErrorAction Stop
        
        Write-Host "[*] Extracting module assets into system storage..." -ForegroundColor Yellow
        Expand-Archive -Path $TempZip -DestinationPath $GamePath -Force
        
        $TargetMenu = Join-Path $GamePath "Menu"
        $TargetObjects = Join-Path $GamePath "ObjectsDepot"
        
        # ล็อกโฟลเดอร์เป็นไฟล์ระบบขั้นสุด (Hidden + System) หายวับทันทีไม่ต้องไปติ๊กค่าใดๆ ใน Windows
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

# โหมดที่ 2: เจาะทะลุไฟล์ซ่อนระบบสั่งทำลายทิ้ง คลีนเกมสะอาด
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
