# Lab 2 Troubleshooting

## Tor not running on Kali

- Check service status: `systemctl status tor`
- Check config syntax: `tor --verify-config`
- Validate torrc path: `/etc/tor/torrc`
- Restart service: `sudo systemctl restart tor`

## ProxyChains DNS leaks still visible

- Verify `proxy_dns` exists and is uncommented in `/etc/proxychains4.conf`
- Confirm app is launched with ProxyChains (for example `proxychains4 firefox`)
- Some tools do local resolver calls before proxying; test with multiple clients

## Metasploit DB connection failures

- Start DB manually: `sudo systemctl start postgresql`
- Re-init if needed: `sudo msfdb reinit`
- Check status quickly: `msfconsole -q -x "db_status; exit"`

## No callback received from target

- Validate host-only network path between 192.168.56.100 and 192.168.56.150
- Ensure listener LHOST/LPORT matches payload callback values
- Validate local firewall and AV state on target
- Test reachability from target to Kali on callback port

## EternalBlue path not working

- SMBv1 enabled is not enough by itself
- Use a deliberately vulnerable, unpatched image specifically prepared for MS17-010 training
- If unavailable, switch to another approved initial access route from spec options

## WinRM option C login issues

- Confirm WinRM service is running
- Verify Basic auth and AllowUnencrypted are enabled for the isolated lab
- Ensure credentials are correct and local policy allows remote logon

## Wireshark not capturing DNS packets

- Validate capture interface is the host-only adapter
- Apply filter `udp.port == 53`
- Generate traffic with `nslookup` or `dig`
- Ensure packet capture permissions are correct (wireshark group)
