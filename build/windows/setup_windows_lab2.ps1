#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet('A','B','C')]
    [string]$VulnOption = 'A'
)

$ErrorActionPreference = 'Stop'

Write-Host '[+] Applying Lab 2 Windows baseline (isolated lab only)'

# 1) Accounts and credentials
Write-Host '[+] Configuring local accounts'
$labUser = 'labuser'
$labPass = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
$adminPass = ConvertTo-SecureString 'AdminPass123!' -AsPlainText -Force

if (-not (Get-LocalUser -Name $labUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $labUser -Password $labPass -FullName 'Lab User' -Description 'Lab standard user'
}
Enable-LocalUser -Name $labUser

$adminUser = Get-LocalUser -Name 'Administrator'
if ($null -ne $adminUser) {
    $adminUser | Set-LocalUser -Password $adminPass
    Enable-LocalUser -Name 'Administrator'
}

if (-not (Get-LocalGroupMember -Group 'Users' -Member $labUser -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group 'Users' -Member $labUser
}

if (Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue) {
    Disable-LocalUser -Name 'Guest'
}

# 2) Disable firewall for lab parity
Write-Host '[+] Disabling Windows Defender Firewall profiles'
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False

# 3) Disable UAC (EnableLUA = 0)
Write-Host '[+] Disabling UAC (reboot required to fully apply)'
$uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
Set-ItemProperty -Path $uacPath -Name EnableLUA -Type DWord -Value 0

# 4) Clear baseline persistence locations (lab artifacts only)
Write-Host '[+] Clearing baseline persistence locations'
$runPaths = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)

foreach ($path in $runPaths) {
    if (Test-Path $path) {
        Get-ItemProperty -Path $path | ForEach-Object {
            $_.PSObject.Properties |
                Where-Object { $_.Name -notmatch '^PS(.*)$' } |
                ForEach-Object { Remove-ItemProperty -Path $path -Name $_.Name -ErrorAction SilentlyContinue }
        }
    }
}

$startupPath = 'C:\Users\labuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
if (Test-Path $startupPath) {
    Get-ChildItem -Path $startupPath -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -like '*lab*' -or $_.TaskName -like '*meterpreter*' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# 5) Ensure migration practice process exists
Write-Host '[+] Launching notepad for migration exercise'
Start-Process notepad.exe

# 6) Vulnerability profile prep
switch ($VulnOption) {
    'A' {
        Write-Host '[+] Applying option A prep: SMBv1 enabled'
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -All | Out-Null
        Set-Service -Name LanmanServer -StartupType Automatic
        Start-Service -Name LanmanServer

        Write-Warning 'MS17-010/EternalBlue requires an unpatched vulnerable Windows image. This script cannot safely "unpatch" a host.'
        Write-Warning 'Use a known intentionally vulnerable VM snapshot for practical exploitation drills.'
    }
    'B' {
        Write-Warning 'Option B requires vulnerable Apache/PHP stack installation. Add your vetted vulnerable package manually in this isolated VM.'
    }
    'C' {
        Write-Host '[+] Applying option C prep: WinRM enabled'
        winrm quickconfig -quiet
        Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
        Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
        Enable-PSRemoting -Force
    }
}

Write-Host '[+] Baseline complete. Reboot is recommended before snapshot.'
Write-Host '[i] After reboot, run .\check_windows_lab2.ps1 to verify requirements.'
