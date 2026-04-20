# Meterpreter and Anonymity Lab Kit

This repository contains a complete build kit for the Lab 2 environment defined in `spec.md`.

It provides:

- Kali provisioning automation
- Windows target baseline scripts
- Validation scripts for both sides
- Snapshot/export instructions
- Troubleshooting and build runbook

## Files Included

- `spec.md` - Full lab specification
- `build/kali/setup_kali_lab2.sh` - Kali provisioning script
- `build/kali/config/proxychains4.conf.template` - ProxyChains baseline config
- `build/kali/config/torrc.template` - Tor baseline config
- `lab2_listener.rc` - Metasploit multi/handler template
- `validate_lab2.sh` - Kali validation script
- `build/windows/setup_windows_lab2.ps1` - Windows baseline setup script
- `build/windows/check_windows_lab2.ps1` - Windows validation script
- `snapshot_instructions.txt` - Snapshot and export checklist
- `troubleshooting.md` - Common issues and fixes
- `docs/lab_build_runbook.md` - End-to-end runbook

## Quick Start

## 1) Build Kali VM

Run on Kali:

```bash
chmod +x build/kali/setup_kali_lab2.sh validate_lab2.sh
./build/kali/setup_kali_lab2.sh
~/validate_lab2.sh
```

Set network adapters:

- Adapter 1: NAT or Bridged
- Adapter 2: Host-only
- Host-only IP: `192.168.56.100/24`

## 2) Build Windows VM

Run in elevated PowerShell on Windows:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup_windows_lab2.ps1 -VulnOption A
Restart-Computer
```

After reboot:

```powershell
.\check_windows_lab2.ps1
```

Set host-only IP: `192.168.56.150/24`

## 3) Practice Flow

1. Start Kali listener with `msfconsole -r ~/lab2_listener.rc`
2. Validate host-only reachability between VMs
3. Run through the exercise checklist in Section 6 of `spec.md`
4. Use `snapshot_instructions.txt` before freezing the final state

## Notes

- Keep this lab isolated from production networks.
- Option A in the spec requires a genuinely vulnerable image for full MS17-010 practice.
- Core build automation here covers baseline configuration and repeatable validation.
