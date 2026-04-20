#requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$pass = 0
$fail = 0

function Pass([string]$msg) {
    Write-Host "[PASS] $msg"
    $script:pass++
}

function Fail([string]$msg) {
    Write-Host "[FAIL] $msg"
    $script:fail++
}

Write-Host '=== LAB 2 WINDOWS VALIDATION ==='

# Users
if (Get-LocalUser -Name 'labuser' -ErrorAction SilentlyContinue) { Pass 'labuser account exists' } else { Fail 'labuser account missing' }
if (Get-LocalUser -Name 'Administrator' -ErrorAction SilentlyContinue) { Pass 'Administrator account exists' } else { Fail 'Administrator account missing' }

$guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
if ($guest -and -not $guest.Enabled) { Pass 'Guest account disabled' } else { Fail 'Guest account not disabled' }

# Firewall
$fw = Get-NetFirewallProfile -Profile Domain,Private,Public
if (($fw | Where-Object { $_.Enabled -eq $true }).Count -eq 0) { Pass 'Firewall profiles disabled' } else { Fail 'One or more firewall profiles still enabled' }

# UAC
$uac = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction SilentlyContinue
if ($uac.EnableLUA -eq 0) { Pass 'EnableLUA set to 0' } else { Fail 'EnableLUA not set to 0' }

# Process requirements
if (Get-Process explorer -ErrorAction SilentlyContinue) { Pass 'explorer.exe present' } else { Fail 'explorer.exe missing' }
if (Get-Process svchost -ErrorAction SilentlyContinue) { Pass 'svchost.exe present' } else { Fail 'svchost.exe missing' }
if (Get-Process winlogon -ErrorAction SilentlyContinue) { Pass 'winlogon.exe present' } else { Fail 'winlogon.exe missing' }
if (Get-Process notepad -ErrorAction SilentlyContinue) { Pass 'notepad.exe present' } else { Fail 'notepad.exe missing' }

# Baseline persistence locations
$runKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)
foreach ($rk in $runKeys) {
    $props = @()
    if (Test-Path $rk) {
        $props = (Get-ItemProperty -Path $rk).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS(.*)$' }
    }

    if ($props.Count -eq 0) {
        Pass "$rk is empty"
    } else {
        Fail "$rk contains existing values"
    }
}

$startup = 'C:\Users\labuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
if (-not (Test-Path $startup) -or (Get-ChildItem $startup -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Pass 'labuser startup folder is clean'
} else {
    Fail 'labuser startup folder has files'
}

Write-Host ''
Write-Host "Summary: $pass PASS / $fail FAIL"
if ($fail -gt 0) { exit 1 } else { exit 0 }
