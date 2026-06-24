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

$UserKey = (Read-Host "[*] Please enter your License Key").Trim()

if ([string]::IsNullOrWhiteSpace($UserKey)) {
    Write-Host "[!] Verification Error: Key cannot be empty." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

Write-Host "`n[*] Synchronizing with cloud environment database..." -ForegroundColor Yellow

$RequestUrl = "$BaseApiUrl`?key=$UserKey&hwid=$MachineHWID"
try {
    $ApiResponse = Invoke-WebRequest -Uri $RequestUrl -Method Get -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    $ApiResponse = $ApiResponse.Trim()
} catch {
    Write-Host "[!] Gateway Error: Secure database connection failed." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}

# -----------------------------------------------------------------
# [PRECISE SCAN V4] ค้นหาห้อง Data ตัวเกมจริง
# -----------------------------------------------------------------
$Drives = @("D:\", "C:\", "E:\", "F:\", "G:\")
$GamePath = $null

foreach ($Drive in $Drives) {
    if (Test-Path $Drive) {
        $AllDataFolders = Get-ChildItem -Path $Drive -Filter "Data" -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*WarZ*" }
        foreach ($Folder in $AllDataFolders) {
            $FullPath = $Folder.FullName
            if ($FullPath -like "*\Downloads\*" -or $FullPath -like "*\Desktop\*" -or $FullPath -like "*\`$Recycle.Bin*") { continue }
            $GamePath = $FullPath
            break
        }
    }
    if ($null -ne $GamePath) { break }
}

if ($null -eq $GamePath) {
    Write-Host "`n[!] Notice: Automatic game directory detection bypassed." -ForegroundColor Yellow
    $UserPath = (Read-Host "[*] Please input your main game directory path manually").Trim()
    if (Test-Path $UserPath) {
        if ($UserPath -like "*Data*") { $GamePath = $UserPath }
        else { $GamePath = Join-Path $UserPath "Data" }
    } else {
        Write-Host "[!] Fatal Error: Destination path does not exist." -ForegroundColor Red
        Read-Host "Press [Enter] to exit"; exit
    }
}

# -----------------------------------------------------------------
# EVALUATE CLOUD GATEWAY RESPONSE
# -----------------------------------------------------------------
$IsPermanent = $false

if ($ApiResponse -eq "INVALID_KEY") {
    Write-Host "[!] Authorization Failed: Invalid client product key." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "HWID_MISMATCH") {
    Write-Host "`n[!] Security Violation Detected! Access denied." -ForegroundColor Red
    Read-Host "Press [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "KEY_EXPIRED") {
    Write-Host "`n[!] License Period Expired! Activating force cleanup..." -ForegroundColor Red
    if (Test-Path $GamePath) {
        Remove-Item (Join-Path $GamePath "Menu") -Recurse -Force
        Remove-Item (Join-Path $GamePath "ObjectsDepot") -Recurse -Force
    }
    Unregister-ScheduledTask -TaskName "WarZ_FPS_Booster_LogonCheck" -Confirm:$false
    Start-Process cmd -ArgumentList "/c del `"$PSCommandPath`"" -WindowStyle Hidden
    Read-Host "Press [Enter] to exit"; exit
}
elseif ($ApiResponse -eq "REGISTERED_SUCCESS" -or $ApiResponse -eq "ACCESS_GRANTED") {
    Write-Host "[DONE] Security Token Validated. Session Authorized." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
else {
    if ($ApiResponse -like "*PERMANENT*") { $IsPermanent = $true }
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
Write-Host "  [1] INSTALL                                     " -ForegroundColor Green
Write-Host "  [2] CLEAN                                       " -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Cyan

do {
    $Choice = Read-Host "Select execution mode (1/2)"
} while ($Choice -ne "1" -and $Choice -ne "2")

$DownloadUrl = "https://raw.githubusercontent.com/mastergamerk/Key-Warz/refs/heads/main/BootFPS.zip"
$TempZip = "$env:TEMP\warz_esp_temp.zip"
$TargetMenu = Join-Path $GamePath "Menu"
$TargetObjects = Join-Path $GamePath "ObjectsDepot"

# MODE 1: ติดตั้ง พร้อมฝังคำสั่งสแกนเช็กคีย์ตอนเปิดคอมพิวเตอร์ใหม่
if ($Choice -eq "1") {
    if (Test-Path $TargetMenu) {
        Write-Host "`n[!] Notice: Performance patch is already installed in this directory." -ForegroundColor Yellow
    } else {
        Write-Host "`n[*] Downloading performance assets from secure repository..." -ForegroundColor Yellow
        try {
            if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -ErrorAction Stop
            Expand-Archive -Path $TempZip -DestinationPath $GamePath -Force
            
            if (Test-Path $TargetMenu) { Set-ItemProperty -Path $TargetMenu -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System) }
            if (Test-Path $TargetObjects) { Set-ItemProperty -Path $TargetObjects -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System) }

            # --- ฝังระบบตรวจสอบสิทธิ์อัตโนมัติเบื้องหลังตอนเปิดเครื่อง (At Logon) ---
            if (-not $IsPermanent) {
                Write-Host "[*] Registering boot-time environmental security cycle..." -ForegroundColor DarkCyan
                
                Unregister-ScheduledTask -TaskName "WarZ_FPS_Booster_LogonCheck" -Confirm:$false
                
                # เขียนโค้ดส่งไปฝังในเครื่องลูกค้า: ทุกครั้งที่เปิดคอม ให้ยิงถาม Google Sheets เช็กเวลาหมดอายุ
                $ActionScript = @"
`$Url = '$BaseApiUrl?key=$UserKey&hwid=$MachineHWID'
`$Res = (Invoke-WebRequest -Uri `$Url -Method Get -UseBasicParsing -ErrorAction SilentlyContinue).Content
if (`$Res -like '*KEY_EXPIRED*' -or `$Res -like '*INVALID_KEY*') {
    Remove-Item -Path '$TargetMenu' -Recurse -Force
    Remove-Item -Path '$TargetObjects' -Recurse -Force
    Unregister-ScheduledTask -TaskName 'WarZ_FPS_Booster_LogonCheck' -Confirm:`$false
}
"@
                $EncScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ActionScript))
                
                # ตั้งค่าให้รันแบบซ่อนหน้าต่าง เงียบสนิท ทันทีที่มีการเปิดเครื่องเข้า Windows
                $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -EncodedCommand $EncScript"
                $Trigger = New-ScheduledTaskTrigger -AtLogon
                
                Register-ScheduledTask -TaskName "WarZ_FPS_Booster_LogonCheck" -Action $Action -Trigger $Trigger -User "SYSTEM" -Force
            }

            Write-Host "`n[DONE] Execution Success: Performance patch deployed smoothly." -ForegroundColor Green
        } catch {
            Write-Host "`n[!] Critical Deployment Failure: $_" -ForegroundColor Red
        }
    }
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }

# MODE 2: ล้างไฟล์ และยกเลิกงานตอนเปิดเครื่อง
} elseif ($Choice -eq "2") {
    Write-Host "`n[*] Starting data integrity cleanup engine..." -ForegroundColor Yellow
    if (-not (Test-Path $TargetMenu) -and -not (Test-Path $TargetObjects)) {
        Write-Host "[-] System status: Verified Clean." -ForegroundColor Gray
    } else {
        if (Test-Path $TargetMenu) { Remove-Item $TargetMenu -Recurse -Force }
        if (Test-Path $TargetObjects) { Remove-Item $TargetObjects -Recurse -Force }
        Write-Host "[DONE] Game environment configuration restored." -ForegroundColor DarkYellow 
    }
    Unregister-ScheduledTask -TaskName "WarZ_FPS_Booster_LogonCheck" -Confirm:$false
    Write-Host "`n[DONE] Environment restoration completely completed!" -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Read-Host "Press [Enter] to terminate dashboard session"
