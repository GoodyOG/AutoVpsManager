#!/bin/bash
# ==========================================
#  GoodyOG Universal Auto-Installer
#  Premium Edition - TechyChi (Unlocked)
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper for "Futuristic" Headers
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}│${YELLOW}%*s%s%*s${CYAN}│${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    sleep 1
}

function print_success() { echo -e "${GREEN} [OK] $1${NC}"; }
function print_info() { echo -e "${BLUE} [INFO] $1${NC}"; }

# 1. REPOSITORY CONFIGURATION
# -----------------------------------------------------
REPO_URL="https://raw.githubusercontent.com/GoodyOG/AutoVpsManager/main"
# -----------------------------------------------------

clear
echo -e "\033[0;36m┌───────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[0;36m│\033[0;32m             GOODYOG AUTOSCRIPT INSTALLER              \033[0;36m│\033[0m"
echo -e "\033[0;36m│\033[0;33m          Premium VPS Manager - By TechyChi            \033[0;36m│\033[0m"
echo -e "\033[0;36m└───────────────────────────────────────────────────────┘\033[0m"
echo -e " \033[0;34m>\033[0m Initializing Installation Sequence..."
sleep 2

# -----------------------------------------------------
# 2. SYSTEM PREPARATION
# -----------------------------------------------------
print_title "SYSTEM PREPARATION"
print_info "Creating System Directories..."
mkdir -p /etc/xray/limit/{vmess,vless,trojan} /usr/local/etc/xray /etc/openvpn /etc/slowdns

print_info "Installing Essentials..."
systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1
apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip vnstat dropbear nginx dnsutils dante-server stunnel4 cmake

# Install Rclone
curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1

# --- OS DETECTOR & UBUNTU 24.04 COMPATIBILITY PATCH ---
source /etc/os-release
if [[ "$VERSION_ID" == "24.04" ]]; then
    print_info "Ubuntu 24.04 Detected: Applying Core Network & SSH Patches..."
    apt-get install -y iptables iptables-nft > /dev/null 2>&1
    systemctl disable --now ssh.socket > /dev/null 2>&1
    systemctl enable --now ssh.service > /dev/null 2>&1
    systemctl restart ssh > /dev/null 2>&1
fi

# -----------------------------------------------------
# 3. DOMAIN & NS SETUP
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS -4 ifconfig.me)

while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    read -p " Input SubDomain : " domain
    if [[ -z "$domain" ]]; then continue; fi

    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[✔] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[✘] DNS Mismatch (Expected $MYIP). Continuing anyway...${NC}"
        echo "$domain" > /etc/xray/domain
        break
    fi
done

echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}              ENTER YOUR NAMESERVER (NS)              ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
read -p " Input NS Domain (Empty for ns.$domain) : " nsdomain
if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
else
    echo "$nsdomain" > /etc/xray/nsdomain
fi
print_success "NS Domain Saved!"

# -----------------------------------------------------
# 4. CONFIGURE DROPBEAR (REBRANDED)
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR SSH"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

cat > /etc/default/dropbear <<'EOF_DROPBEAR'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -b /etc/issue.net -K 35 -I 60"
DROPBEAR_BANNER="/etc/issue.net"
EOF_DROPBEAR

# Rebranded Banner
cat > /etc/issue.net << 'EOF_BANNER'
<html><body>
<h3 style="text-align: center;"><span style="color: #0000FF;"><strong>Premium Server By GoodyOG & TechyChi</strong></span></h3>
<font color="red"><b>Terms Of Service (TOS)</b></font><br>
<font color="white"><b>NO Multi Login | NO DDoS | NO Carding</b></font><br>
<font color="red"><b>Violating TOS will result in permanent suspension.</b></font><br>
<h5 style="text-align: center;"><span style="color: #890596;"><strong>Config Created By AutoVpsManager (GoodyOG)</strong></span></h5>
</body></html>
EOF_BANNER

mkdir -p /etc/ssh/sshd_config.d
echo "Banner /etc/issue.net" > /etc/ssh/sshd_config.d/99-custom-banner.conf
sed -i 's/^Banner/#Banner/g' /etc/ssh/sshd_config 2>/dev/null
echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config.d/99-keepalive.conf
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config.d/99-keepalive.conf

systemctl restart ssh
systemctl restart dropbear
print_success "Dropbear & SSH Configured!"

# -----------------------------------------------------
# 5. INSTALL XRAY CORE
# -----------------------------------------------------
print_title "INSTALLING XRAY CORE"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# -----------------------------------------------------
# 6. INSTALL SSL/TLS
# -----------------------------------------------------
print_title "GENERATING SSL CERTIFICATE"
systemctl stop nginx
mkdir -p /root/.acme.sh
curl -s https://get.acme.sh | sh -s email=admin@$domain
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

if [[ ! -s /etc/xray/xray.crt ]]; then
    print_info "Let's Encrypt fallback triggered..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -subj "/C=US/ST=State/L=City/O=GoodyOG/CN=$domain" 2>/dev/null
fi
chmod 644 /etc/xray/xray.key /etc/xray/xray.crt

# -----------------------------------------------------
# 6.5 CONFIGURE STUNNEL4
# -----------------------------------------------------
cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/stunnel/stunnel.pem
cat > /etc/stunnel/stunnel.conf <<'EOF_STUNNEL'
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear_tls_1]
accept = 447
connect = 127.0.0.1:109
[dropbear_tls_2]
accept = 777
connect = 127.0.0.1:109
EOF_STUNNEL
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl enable stunnel4 && systemctl restart stunnel4

# -----------------------------------------------------
# 7. INSTALL UDPGW (PORT 7300)
# -----------------------------------------------------
git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn > /dev/null 2>&1
mkdir -p /tmp/badvpn/build && cd /tmp/badvpn/build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
make install > /dev/null 2>&1
cat > /etc/systemd/system/udpgw.service <<'EOF_UDPGW'
[Unit]
Description=BadVPN UDPGW
[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF_UDPGW
systemctl daemon-reload && systemctl enable udpgw && systemctl start udpgw
cd /root && rm -rf /tmp/badvpn

# -----------------------------------------------------
# 7.5 CONFIGURE NGINX MULTIPLEXER
# -----------------------------------------------------
fuser -k 80/tcp 81/tcp 443/tcp > /dev/null 2>&1
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/conf.d/vps.conf <<'EOF_NGINX'
server {
    listen 81;
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /vless {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /vmess {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /trojan-ws {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
}
EOF_NGINX
systemctl restart nginx

# -----------------------------------------------------
# 8. DOWNLOAD FILES FROM GOODYOG REPO
# -----------------------------------------------------
print_title "DOWNLOADING ASSETS"

download_bin() {
    wget -q -O /usr/bin/$2 "${REPO_URL}/$1/$2" && chmod +x /usr/bin/$2
    echo -e " [OK] Installed: $2"
}

# Core
wget -q -O /etc/slowdns/dnstt-server "${REPO_URL}/core/dnstt-server" && chmod +x /etc/slowdns/dnstt-server
wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json.template"
wget -q -O /etc/xray/ohp.py "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"
wget -q -O /etc/xray/proxy-8880.py "${REPO_URL}/core/proxy-8880.py"
download_bin "core" "auth.sh"

# Auth Token Failsafe (Severing License connection)
echo "GoodyOG_$(date +%Y-%m-%d)" > /tmp/.vps_auth_token

# Download Menus
for m in menu menu-domain.sh menu-set.sh menu-ssh.sh menu-trojan.sh menu-vless.sh menu-vmess.sh running.sh; do
    download_bin "menu" "$m"
done

# SSH & Xray scripts
files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf ceklim speedtest api-ssh locker limit user-timed)
for f in "${files_ssh[@]}"; do download_bin "ssh" "$f"; done
files_xray=(add-ws del-ws renew-ws cek-ws trial-ws member-ws add-vless del-vless renew-vless cek-vless trial-vless member-vless add-tr del-tr renew-tr cek-tr trial-tr member-tr)
for f in "${files_xray[@]}"; do download_bin "xray" "$f"; done

# -----------------------------------------------------
# 9. SECURITY & FIREWALL (HARDENED)
# -----------------------------------------------------
print_info "Arming Firewall & Anti-Abuse..."
apt-get install -y ufw > /dev/null 2>&1
for port in 22 109 143 80 81 8880 443 447 777 53 5300 1080 7300; do ufw allow $port/tcp > /dev/null 2>&1; done
ufw allow 53/udp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

# Block Spam & Torrenting
iptables -A OUTPUT -p tcp --dport 25 -j DROP
iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
apt-get install -y iptables-persistent > /dev/null 2>&1
netfilter-persistent save > /dev/null 2>&1

# DDoS Deflate
wget -qO ddos.zip "https://github.com/jgmdev/ddos-deflate/archive/master.zip"
unzip -q ddos.zip && cd ddos-deflate-master && yes "" | ./install.sh > /dev/null 2>&1
cd .. && rm -rf ddos.zip ddos-deflate-master

# -----------------------------------------------------
# 10. FINALIZE & HEAL
# -----------------------------------------------------
print_title "FINALIZING SERVICES"
ns_domain=$(cat /etc/xray/nsdomain)
echo "a0946ee29693f2394e60b251b6c9e8d5b2f3bc8d753deebf8ce778773dbe10bc" > /etc/slowdns/server.key
cat > /etc/systemd/system/client-slow.service <<EOF_SLOW
[Unit]
Description=SlowDNS Server
[Service]
ExecStartPre=/bin/sh -c 'iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $ns_domain 127.0.0.1:109
Restart=always
[Install]
WantedBy=multi-user.target
EOF_SLOW

# Python Proxy Services
cat > /etc/systemd/system/ws-proxy.service <<'EOF_WS'
[Unit]
Description=Python Proxy SSH-WS
[Service]
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF_WS

cat > /etc/systemd/system/ws-8880.service <<'EOF_WS8'
[Unit]
Description=Python Proxy Port 8880
[Service]
ExecStart=/usr/bin/python3 /etc/xray/proxy-8880.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF_WS8

# SERVICE HEALER
systemctl daemon-reload
systemctl enable xray nginx ws-proxy ws-8880 client-slow danted
systemctl restart xray nginx ws-proxy ws-8880 client-slow danted
echo "3.5" > /etc/xray/version

print_success "Installation Finished. Rebooting..."
sleep 5
reboot
