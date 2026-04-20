#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[+] Updating apt cache"
sudo apt-get update

echo "[+] Installing required packages"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    metasploit-framework tor proxychains4 wireshark firefox-esr nmap curl dnsutils

echo "[+] Backing up and applying proxychains config"
if [[ -f /etc/proxychains4.conf ]]; then
    sudo cp /etc/proxychains4.conf /etc/proxychains4.conf.bak.lab2
fi
sudo cp "$REPO_ROOT/build/kali/config/proxychains4.conf.template" /etc/proxychains4.conf

echo "[+] Backing up and applying Tor config"
if [[ -f /etc/tor/torrc ]]; then
    sudo cp /etc/tor/torrc /etc/tor/torrc.bak.lab2
fi
sudo cp "$REPO_ROOT/build/kali/config/torrc.template" /etc/tor/torrc

# Ensure tor logging file exists and has expected permissions.
sudo touch /var/log/tor/notices.log
sudo chown debian-tor:debian-tor /var/log/tor/notices.log
sudo chmod 640 /var/log/tor/notices.log

echo "[+] Enabling and restarting tor"
sudo systemctl enable tor
sudo systemctl restart tor

echo "[+] Enabling and starting postgresql"
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "[+] Initializing Metasploit database (idempotent)"
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='msf'" | grep -q 1; then
    sudo msfdb init
else
    echo "[i] msf database already present, skipping msfdb init"
fi

echo "[+] Ensuring current user is in wireshark group"
if getent group wireshark >/dev/null; then
    sudo usermod -aG wireshark "$USER" || true
fi

echo "[+] Installing listener resource script"
cp "$REPO_ROOT/lab2_listener.rc" "$HOME/lab2_listener.rc"

echo "[+] Installing validation script"
cp "$REPO_ROOT/validate_lab2.sh" "$HOME/validate_lab2.sh"
chmod +x "$HOME/validate_lab2.sh"

echo "[+] Kali setup complete"
echo "[i] Run: $HOME/validate_lab2.sh"
echo "[i] Log out/in once so wireshark group membership is refreshed"
