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
    echo -e "${CYAN}======================================================${NC}"
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}║${YELLOW}%*s%s%*s${CYAN}║${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}======================================================${NC}"
    sleep 1
}

function print_success() {
    echo -e "${GREEN} [OK] $1${NC}"
}

function print_info() {
    echo -e "${BLUE} [INFO] $1${NC}"
}

# 1. DEFINE PRIVATE VAULT (UPDATED TO GOODYOG REPO)
# -----------------------------------------------------
REPO_URL="https://raw.githubusercontent.com/GoodyOG/AutoVpsManager/main"
# -----------------------------------------------------

clear
echo -e "\033[0;36m======================================================\033[0m"
echo -e "\033[0;32m             GOODYOG AUTOSCRIPT INSTALLER             \033[0m"
echo -e "\033[0;33m          Premium VPS Manager - By TechyChi           \033[0m"
echo -e "\033[0;36m======================================================\033[0m"
echo -e " \033[0;34m>\033[0m Initializing Installation Sequence..."
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
# Stop Apache if present
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

# 3. DOMAIN & NS SETUP
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS -4 ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    read -p " Input SubDomain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi
    
    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[OK] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[!] Domain points to $DOMAIN_IP (Expected $MYIP)${NC}"
        echo -e "     Continuing anyway... (Please ensure DNS is correct)"
        echo "$domain" > /etc/xray/domain
        break
    fi
done

# --- B. NameServer (NS) ---
echo -e ""
echo -e "${YELLOW}              ENTER YOUR NAMESERVER (NS)              ${NC}"
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
read -p " Input NS Domain : " nsdomain
if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
    print_info "Using default: ns.$domain"
else
    echo "$nsdomain" > /etc/xray/nsdomain
    print_success "NS Domain Saved!"
fi

# 4. CONFIGURE DROPBEAR
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR SSH"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
