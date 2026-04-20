# Lab 2 Build Runbook

## Scope

This runbook operationalizes `spec.md` into a repeatable build process.

## 1. Kali VM Build

1. Start Kali and clone/copy this repository.
2. Run:
   ```bash
   chmod +x build/kali/setup_kali_lab2.sh validate_lab2.sh
   ./build/kali/setup_kali_lab2.sh
   ```
3. Set host-only adapter static IP to `192.168.56.100/24`.
4. Run validation:
   ```bash
   ~/validate_lab2.sh
   ```

## 2. Windows VM Build

1. Login as Administrator.
2. Copy folder `build/windows` to Desktop.
3. Open elevated PowerShell and run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\setup_windows_lab2.ps1 -VulnOption A
   Restart-Computer
   ```
4. After reboot, run elevated:
   ```powershell
   .\check_windows_lab2.ps1
   ```
5. Set host-only adapter static IP to `192.168.56.150/24`.

## 3. Listener Prep on Kali

1. Confirm file exists:
   ```bash
   ls ~/lab2_listener.rc
   ```
2. Start handler:
   ```bash
   msfconsole -r ~/lab2_listener.rc
   ```

## 4. Validation Matrix

Use section 6 from `spec.md` as final acceptance list.

## 5. Snapshot and Export

1. Follow `snapshot_instructions.txt` exactly.
2. Export OVA files and store as encrypted archives.

## Notes

- This repository builds the environment and baseline checks.
- For exploit-specific vulnerable software images, use legally approved and intentionally vulnerable VM sources only.
