#!/bin/bash
# ==========================================
#  TechyChi Universal Auto-Installer
#  Premium Edition - 2026 (Verified Stable)
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper for "Futuristic" Headers (FIXED WIDTH = 54 Chars)
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    # Center text manually for perfect alignment
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}│${YELLOW}%*s%s%*s${CYAN}│${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    sleep 1
}

function print_success() {
    echo -e "${GREEN} [OK] $1${NC}"
}

function print_info() {
    echo -e "${BLUE} [INFO] $1${NC}"
}

# 1. DEFINE PRIVATE VAULT (POINTED TO YOUR GITHUB)
# -----------------------------------------------------
REPO_URL="https://raw.githubusercontent.com/GoodyOG/AutoVpsManager/main"
# -----------------------------------------------------

clear
echo -e "\033[0;36m┌───────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[0;36m│\033[0;32m             TECHYCHI AUTOSCRIPT INSTALLER             \033[0;36m│\033[0m"
echo -e "\033[0;36m│\033[0;33m        Premium Autoscript Manager - By goodyog        \033[0;36m│\033[0m"
echo -e "\033[0;36m└───────────────────────────────────────────────────────┘\033[0m"
echo -e " \033[0;34m>\033[0m Initializing Secure Boot Sequence..."
sleep 2

# 2. SYSTEM PREPARATION
# -----------------------------------------------------
print_title "SYSTEM PREPARATION"
print_info "Creating System Directories..."
mkdir -p /etc/xray
mkdir -p /etc/xray/limit/vmess
mkdir -p /etc/xray/limit/vless
mkdir -p /etc/xray/limit/trojan
mkdir -p /usr/local/etc/xray
mkdir -p /etc/openvpn

print_info "Installing Essentials..."
# Stop Apache if present (Fix for Nginx OFF issue)
systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1

apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip vnstat dropbear nginx dnsutils dante-server stunnel4 cmake

# Install Rclone directly from official source to ensure Google Drive API compatibility
curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1

# --- OS DETECTOR & UBUNTU 24.04 COMPATIBILITY PATCH ---
source /etc/os-release
if [[ "$VERSION_ID" == "24.04" ]]; then
    print_info "Ubuntu 24.04 Detected: Applying Core Network & SSH Patches..."
    
    # 1. Fix the IPtables Routing Death (Forces legacy translation)
    apt-get install -y iptables iptables-nft > /dev/null 2>&1
    
    # 2. Fix the SSH Socket Lockout (Reverts to standard ssh.service)
    systemctl disable --now ssh.socket > /dev/null 2>&1
    systemctl enable --now ssh.service > /dev/null 2>&1
    systemctl restart ssh > /dev/null 2>&1
fi
# ------------------------------------------------------

# 3. DOMAIN & NS SETUP
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS -4 ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    # Instructions print FIRST
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}>${NC} Enter that subdomain below (e.g., vpn.mysite.com)."
    # Input prompt prints LAST
    read -p " Input SubDomain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi

    # Quick IP Check
    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[✔] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[✘] Domain points to $DOMAIN_IP (Expected $MYIP)${NC}"
        echo -e "     Continuing anyway... (Please ensure DNS is correct)"
        echo "$domain" > /etc/xray/domain
        break
    fi
done

# --- B. NameServer (NS) ---
echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}              ENTER YOUR NAMESERVER (NS)              ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
# Instructions print FIRST
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
echo -e " ${CYAN}>${NC} If you don't have one, just press ENTER."
# Input prompt prints LAST
read -p " Input NS Domain : " nsdomain

if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
    print_info "Using default: ns.$domain"
else
    echo "$nsdomain" > /etc/xray/nsdomain
    print_success "NS Domain Saved!"
fi

# 4. CONFIGURE DROPBEAR (FORCE WRITE)
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR SSH"

# Allow restricted shells so Dropbear accepts VPN users
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

# Inject Custom SSH/Dropbear Banner (Rebranded to TechyChi)
cat > /etc/issue.net << 'EOF'
<html>
<!DOCTYPE html>
<body>
<h3 style="text-align: center;"><span style="color: #0000FF;"><strong>Premium Server Brought To You By TechyChi</strong></span></h3><font color="red"><b>Terms Of Service (TOS)</b></font>
<font color="white"><b>NO Multi Login</b></font>
<font color="white"><b>NO DDoS</b></font>
<font color="white"><b>NO Carding/Hacking/Illegal Use</b></font>
<font color="white"><b>NO Seed Torrent</b></font>
<font color="white"><b>NO SPAM</b></font>

<font color="red"><b>Violating Term Of Service (TOS)</b></font>
<font color="white"><b>Your Account Will Permanently Suspend</b></font>
<font color="white"><b>Without Any Warning !!!</b></font>

<h5 style="text-align: center;"><span style="color: #890596;"><strong>Config Created By goodyog - TechyChi</strong></span>
</span></h5>
</body>
</html>
EOF

# Ensure OpenSSH also displays the banner (Modern 24.04 Safe Method)
mkdir -p /etc/ssh/sshd_config.d
echo "Banner /etc/issue.net" > /etc/ssh/sshd_config.d/99-custom-banner.conf

# Silence any legacy banner settings in the main file to prevent fatal crashes
sed -i 's/^Banner/#Banner/g' /etc/ssh/sshd_config 2>/dev/null

systemctl restart ssh
systemctl restart sshd 2>/dev/null

# Force Dropbear Banner and Aggressive Keep-Alive/Timeout
sed -i 's/^DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-b \/etc\/issue.net -K 35 -I 60"/g' /etc/default/dropbear
if ! grep -q "^DROPBEAR_EXTRA_ARGS=" /etc/default/dropbear; then
    echo 'DROPBEAR_EXTRA_ARGS="-b /etc/issue.net -K 35 -I 60"' >> /etc/default/dropbear
fi

# Apply OpenSSH Aggressive Keep-Alives
echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config.d/99-keepalive.conf
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config.d/99-keepalive.conf

print_success "Dropbear & SSH Configured with Anti-Ghost Settings!"
systemctl restart dropbear

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

# 1. The official ACME script URL
curl -s https://get.acme.sh | sh -s email=admin@$domain
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

# 2. THE BULLETPROOF FAILSAFE
if [[ ! -s /etc/xray/xray.crt || ! -s /etc/xray/xray.key ]]; then
    print_info "Let's Encrypt blocked or empty. Generating Fallback SSL..."
    
    rm -f /etc/xray/xray.crt /etc/xray/xray.key
    
    # Generate the dummy cert (Rebranded to TechyChi)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -subj "/C=US/ST=State/L=City/O=TechyChi/CN=$domain" 2>/dev/null
fi

chmod 644 /etc/xray/xray.key
chmod 644 /etc/xray/xray.crt
print_success "SSL Certificate Installed!"

# -----------------------------------------------------
# 6.5 CONFIGURE STUNNEL4 (TLS/SSL)
# -----------------------------------------------------

print_title "CONFIGURING STUNNEL4"
cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/stunnel/stunnel.pem
cat > /etc/stunnel/stunnel.conf <<EOF
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
EOF

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl enable stunnel4
systemctl restart stunnel4
print_success "Stunnel4 Configured (Ports 447, 777)"

# -----------------------------------------------------
# 7. INSTALL BADVPN UDPGW (PORT 7300)
# -----------------------------------------------------
print_title "INSTALLING UDPGW"
git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn > /dev/null 2>&1
mkdir -p /tmp/badvpn/badvpn-build
cd /tmp/badvpn/badvpn-build
cmake /tmp/badvpn -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
make install > /dev/null 2>&1
cat > /etc/systemd/system/udpgw.service <<EOF
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable udpgw
systemctl start udpgw
rm -rf /tmp/badvpn
print_success "UDPGW Core Installed!"

# -----------------------------------------------------
# 7.5 CONFIGURE NGINX MULTIPLEXER (PORT 443 & 81)
# -----------------------------------------------------
print_title "CONFIGURING NGINX PROXY"

fuser -k 80/tcp > /dev/null 2>&1
fuser -k 81/tcp > /dev/null 2>&1
fuser -k 443/tcp > /dev/null 2>&1

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

cat > /etc/nginx/conf.d/vps.conf <<EOF
server {
    listen 81;
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;

    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location /vless-hu {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location /vmess-hu {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location /trojan-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
EOF
print_success "Nginx Multiplexer Configured!"

# -----------------------------------------------------
# 7.6 INSTALL SLOWDNS (DNSTT) - PRE-COMPILED BINARY
# -----------------------------------------------------
print_title "INSTALLING SLOWDNS"
mkdir -p /etc/slowdns

# 1. Download Pre-compiled Binary from GitHub
print_info "Downloading SlowDNS Core..."
wget -q -O /etc/slowdns/dnstt-server "${REPO_URL}/core/dnstt-server"
chmod +x /etc/slowdns/dnstt-server

# 2. Inject Static Master Keys
print_info "Applying Static Master Keys..."
echo "a0946ee29693f2394e60b251b6c9e8d5b2f3bc8d753deebf8ce778773dbe10bc" > /etc/slowdns/server.key
echo "68a93ff4e08ea51657ede89c8dcc6534088d8461c1209743c11b96399beb1408" > /etc/slowdns/server.pub
chmod 644 /etc/slowdns/server.pub
chmod 600 /etc/slowdns/server.key

# 3. Read your NS Domain
nsdomain=$(cat /etc/xray/nsdomain)

# 4. Create Systemd Service
cat > /etc/systemd/system/client-slow.service <<EOF
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sh -c 'iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $nsdomain 127.0.0.1:109
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 5. Start the Service with explicit dependency checks
systemctl daemon-reload
systemctl enable client-slow

# Force apply the IPTables rule before starting
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true

systemctl restart client-slow

# Cleanup
cd ~
rm -rf /tmp/dnstt
print_success "SlowDNS Configured (Static Mode)!"
# -----------------------------------------------------

# 7.7 INSTALL OPENVPN
# -----------------------------------------------------
print_title "INSTALLING OPENVPN"
wget -q -O /tmp/openvpn.sh "${REPO_URL}/core/openvpn.sh"
chmod +x /tmp/openvpn.sh
/tmp/openvpn.sh
rm -f /tmp/openvpn.sh

# 8. DOWNLOAD FILES
# -----------------------------------------------------
print_title "DOWNLOADING SCRIPTS"

download_bin() {
    local folder=$1
    local file=$2
    wget -q -O /usr/bin/$file "${REPO_URL}/$folder/$file"
    chmod +x /usr/bin/$file
    echo -e " [OK] Installed: $file"
}

wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json.template"
wget -q -O /etc/systemd/system/xray.service "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/ohp.py "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"
wget -q -O /etc/xray/proxy-8880.py "${REPO_URL}/core/proxy-8880.py"

download_bin "core" "auth.sh"

# -----------------------------------------------------
# VAULTED CONFIG: GOOGLE DRIVE AUTHENTICATION
# -----------------------------------------------------
print_info "Fetching Master Cloud Auth (Rclone)..."
mkdir -p /root/.config/rclone
wget -q -O /root/.config/rclone/rclone.conf "${REPO_URL}/core/rclone.conf"

# -----------------------------------------------------
# CREATING SSH-WS PROXY SERVICE (PORT 80)
# -----------------------------------------------------
print_info "Creating SSH-WS Proxy Service..."
cat > /etc/systemd/system/ws-proxy.service <<EOF
[Unit]
Description=Python Proxy SSH-WS
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy
print_success "SSH-WS Proxy Service Configured & Healing Armed!"
# -----------------------------------------------------

# -----------------------------------------------------
# CREATING CUSTOM SSH PROXY SERVICE (PORT 8880)
# -----------------------------------------------------
print_info "Creating Custom SSH Proxy (Port 8880)..."
cat > /etc/systemd/system/ws-8880.service <<EOF
[Unit]
Description=Python Proxy SSH Blind 101 (Port 8880)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/proxy-8880.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-8880
systemctl restart ws-8880
print_success "Custom Proxy Service Configured!"

download_bin "menu" "menu"
download_bin "menu" "menu-domain.sh"
download_bin "menu" "menu-set.sh"
download_bin "menu" "menu-ssh.sh"
download_bin "menu" "menu-trojan.sh"
download_bin "menu" "menu-vless.sh"
download_bin "menu" "menu-vmess.sh"
download_bin "menu" "running.sh"

files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf ceklim speedtest api-ssh locker limit user-timed)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done
# Rename backup/restore to match menu paths
mv /usr/bin/backup /usr/bin/backup.sh 2>/dev/null
mv /usr/bin/restore /usr/bin/restore.sh 2>/dev/null

files_xray=(add-ws del-ws renew-ws cek-ws trial-ws member-ws add-vless del-vless renew-vless cek-vless trial-vless member-vless add-tr del-tr renew-tr cek-tr trial-tr member-tr)
for file in "${files_xray[@]}"; do
    download_bin "xray" "$file"
done

# -----------------------------------------------------
# CONFIGURING SOCKS5 (DANTE)
# -----------------------------------------------------
print_info "Configuring SOCKS5 Proxy (Port 1080)..."
NIC=$(ip -o -4 route show to default | head -n1 | awk '{print $5}')
cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = 1080
external: $NIC
socksmethod: username
clientmethod: none
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF
systemctl enable danted
systemctl restart danted
print_success "SOCKS5 Configured!"

# -----------------------------------------------------
# 8.5 FIREWALL & ANTI-BOT PROTECTION
# -----------------------------------------------------
print_info "Configuring UFW Firewall & Anti-Bot Limits..."
apt-get install -y ufw > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 109/tcp > /dev/null 2>&1
ufw allow 143/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 81/tcp > /dev/null 2>&1
ufw allow 8880/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
ufw allow 447/tcp > /dev/null 2>&1
ufw allow 777/tcp > /dev/null 2>&1
ufw allow 85/tcp > /dev/null 2>&1
ufw allow 1194/tcp > /dev/null 2>&1
ufw allow 2200/udp > /dev/null 2>&1
ufw allow 7100:7300/udp > /dev/null 2>&1
ufw allow 53/udp > /dev/null 2>&1
ufw allow 5300/udp > /dev/null 2>&1
ufw allow 2095/tcp > /dev/null 2>&1
ufw limit 1080/tcp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
print_success "Military-Grade Firewall Armed!"

# 1. Block SPAM (SMTP Port 25)
iptables -A OUTPUT -p tcp --dport 25 -j DROP
ufw deny out 25/tcp > /dev/null 2>&1

# 2. Block Torrenting (String Matching for P2P protocols)
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -p tcp --dport 6881:6889 -j DROP

# 3. Block Hacking/Exploitation Ports (SMB/RPC)
iptables -A OUTPUT -p tcp --dport 135:139 -j DROP
iptables -A OUTPUT -p tcp --dport 445 -j DROP
iptables -A OUTPUT -p udp --dport 135:139 -j DROP
iptables -A OUTPUT -p udp --dport 445 -j DROP

# 4. Save the rules so they survive a reboot
apt-get install -y iptables-persistent > /dev/null 2>&1
netfilter-persistent save > /dev/null 2>&1

print_success "Cloud-Safe Protocols (Anti-Spam & Anti-Torrent) Armed!"

# --- INSTALL DDoS-DEFLATE (THE BOUNCER) ---
print_info "Installing DDoS-Deflate Engine..."

# Force Ubuntu 24.04 to skip the invisible pink prompt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

wget -qO ddos.zip "https://github.com/jgmdev/ddos-deflate/archive/master.zip"
unzip -q ddos.zip
cd ddos-deflate-master

# Auto-answer yes to any hidden prompts
yes "" | ./install.sh > /dev/null 2>&1

cd ..
rm -rf ddos.zip ddos-deflate-master

# Configure DDoS-Deflate for VPN Traffic
sed -i 's/NO_OF_CONNECTIONS=150/NO_OF_CONNECTIONS=200/g' /etc/ddos/ddos.conf
sed -i 's/BAN_PERIOD=600/BAN_PERIOD=1800/g' /etc/ddos/ddos.conf
systemctl restart ddos
print_success "Aggressive Anti-DDoS Bouncer Armed!"
# ------------------------------------------

# 9. FINAL CONFIGURATION
# -----------------------------------------------------
print_title "FINALIZING SERVICES"

# --- NGINX SELF-HEALING & CONNECTION LIMIT OVERRIDE ---
print_info "Injecting Nginx Self-Healing Overrides..."
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf <<EOF
[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=3
LimitNOFILE=1000000
EOF
# ------------------------------------------------------

# Configure Vnstat
systemctl enable vnstat
systemctl restart vnstat

# --- UNCAP NGINX WORKER LIMITS ---
sed -i 's/worker_processes.*/worker_processes auto;/g' /etc/nginx/nginx.conf
sed -i 's/worker_connections.*/worker_connections 65535;/g' /etc/nginx/nginx.conf

# Enable Services
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl enable nginx
systemctl restart nginx
systemctl enable dropbear
systemctl restart dropbear

# Tag Local Version
curl -s -m 5 "${REPO_URL}/core/version.txt" > /etc/xray/version

# Cronjobs
echo "0 14 * * * root /usr/bin/xp" > /etc/cron.d/xp
echo "*/5 * * * * root /usr/bin/tendang" > /etc/cron.d/tendang
service cron restart
print_success "Services Started."

# 10. FINISH & REBOOT (10s)
# -----------------------------------------------------
clear
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               INSTALLATION COMPLETED!                ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${BLUE}Domain      :${NC} $domain"
echo -e " ${BLUE}NS Domain   :${NC} $nsdomain"
echo -e " ${BLUE}IP Address  :${NC} $MYIP"
echo -e ""
echo -e "${YELLOW} IMPORTANT: Server will reboot in 10 seconds... ${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"

# --- GHOST PROTOCOL: SELF-DESTRUCT ---
print_info "Erasing installation blueprints..."
rm -f /root/setup.sh
rm -f /tmp/setup.sh
history -c

for i in {10..1}; do
    echo -e " Rebooting in $i..."
    sleep 1
done

reboot 
