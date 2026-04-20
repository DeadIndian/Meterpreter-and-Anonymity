#!/usr/bin/env bash
set -u

echo "=== LAB 2 VALIDATION (KALI SIDE) ==="

pass_count=0
fail_count=0

pass() {
    echo "[PASS] $1"
    pass_count=$((pass_count + 1))
}

fail() {
    echo "[FAIL] $1"
    fail_count=$((fail_count + 1))
}

if systemctl is-active --quiet tor; then
    pass "Tor is running"
else
    fail "Tor is not running"
fi

if [[ -S /run/tor/control ]] || ss -lnt 2>/dev/null | grep -q "127.0.0.1:9050"; then
    pass "Tor SOCKS endpoint appears available"
else
    fail "Tor SOCKS endpoint not detected on 127.0.0.1:9050"
fi

if grep -q "^dynamic_chain" /etc/proxychains4.conf && grep -q "^proxy_dns" /etc/proxychains4.conf; then
    pass "ProxyChains configured with dynamic_chain + proxy_dns"
else
    fail "ProxyChains missing dynamic_chain or proxy_dns"
fi

if command -v msfconsole >/dev/null 2>&1; then
    if msfconsole -q -x "db_status; exit" | grep -q "connected to"; then
        pass "Metasploit database connected"
    else
        fail "Metasploit database not connected"
    fi
else
    fail "msfconsole not found"
fi

if ping -c 1 192.168.56.150 >/dev/null 2>&1; then
    pass "Target VM reachable at 192.168.56.150"
else
    fail "Target VM not reachable at 192.168.56.150"
fi

echo
echo "Summary: $pass_count PASS / $fail_count FAIL"
if [[ $fail_count -gt 0 ]]; then
    exit 1
fi
