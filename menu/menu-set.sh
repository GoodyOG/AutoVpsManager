#!/bin/bash
/usr/bin/auth.sh || exit 1
if [[ "$(cat /tmp/.vps_auth_token 2>/dev/null)" != "TechSavage_$(date +%Y-%m-%d)" ]]; then exit 1; fi
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
MYIP=$(curl -sS -4 ifconfig.me)
domain=$(cat /etc/xray/domain)

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}             TECHYCHI SYSTEM SETTINGS MANAGER         ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " [\033[0;32m01\033[0m]  Speedtest VPS"
echo -e " [\033[0;32m02\033[0m]  Info Port"
echo -e " [\033[0;32m03\033[0m]  Set Auto Reboot (Interval)"
echo -e " [\033[0;32m04\033[0m]  Set Auto Reboot (Specific Time)"
echo -e " [\033[0;32m05\033[0m]  View Server Reboot Log"
echo -e " [\033[0;32m06\033[0m]  Restart All Services"
echo -e " [\033[0;32m07\033[0m]  Change Banner"
echo -e " [\033[0;32m08\033[0m]  Check Bandwidth"
echo -e " [\033[0;32m09\033[0m]  Server Health Check"
echo -e " [\033[0;32m10\033[0m]  SlowDNS Key Manager"
echo -e " [\033[0;31m11\033[0m]  Reinstall OS ${RED}(Destructive!)${NC}"
echo -e " [\033[0;32m12\033[0m]  Run BBR Network Optimizer"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " [\033[0;31m00\033[0m]  Back to Main Menu"
echo -e ""
read -p " Select menu : " opt || exit 1

case $opt in
1|01)
    speedtest
    ;;
2|02)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SYSTEM PORTS & INFO                  ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " ${GREEN}>> Service & Port List${NC}"
    echo -e "  - OpenSSH           : 22"
    echo -e "  - Dropbear          : 109, 143"
    echo -e "  - Stunnel4          : 447, 777"
    echo -e "  - SSH-WS (HTTP)     : 80"
    echo -e "  - Custom SSH (HTTP) : 8880"
    echo -e "  - Xray VLESS TLS    : 443"
    echo -e "  - Xray VMess TLS    : 443"
    echo -e "  - Xray Trojan TLS   : 443"
    echo -e "  - Nginx Multiplexer : 81, 443"
    echo -e "  - SlowDNS (DNSTT)   : 53, 5300"
    echo -e "  - BadVPN UDPGW      : 7300"
    echo -e "  - SOCKS5 Proxy      : 1080"
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo -e " ${GREEN}>> Server Status${NC}"
    echo -e "  - IP Address        : $MYIP"
    echo -e "  - Domain            : $domain"
    echo -e "  - Timezone          : $(date +%Z)"
    echo -e "  - Auto-Reboot       : [ACTIVE]"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
3|03)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "           AUTO-REBOOT SETTINGS (INTERVAL)"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " [1] Every 1 Hour"
    echo -e " [2] Every 6 Hours"
    echo -e " [3] Every 12 Hours"
    echo -e " [4] Every 24 Hours (Daily)"
    echo -e " [5] Turn OFF Auto-Reboot"
    echo ""
    read -p " Select: " x || exit 1
    if [[ "$x" == "1" ]]; then
        echo "0 * * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "2" ]]; then
        echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "3" ]]; then
        echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "4" ]]; then
        echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "5" ]]; then
        rm -f /etc/cron.d/auto_reboot
    fi
    service cron restart
    echo -e "${GREEN}Auto-Reboot updated!${NC}"
    sleep 2
    menu-set.sh
    ;;
4|04)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "           AUTO-REBOOT SETTINGS (SPECIFIC TIME)"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " Example: 0 = Midnight, 13 = 1 PM, 23 = 11 PM"
    echo ""
    read -p " Input hour (0-23): " hour || exit 1
    if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
        echo "0 $hour * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
        service cron restart
        echo -e "${GREEN}Server will reboot daily at $hour:00${NC}"
    else
        echo -e "${RED}[ERROR] Invalid Number!${NC}"
    fi
    sleep 2
    menu-set.sh
    ;;
5|05)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SERVER REBOOT LOG                    ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "${GREEN} Current Uptime:${NC} $(uptime -p)"
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo -e " Displaying last 10 reboots:"
    echo ""
    last reboot | head -n 10
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
6|06)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 RESTARTING SERVICES                  ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    
    systemctl restart dropbear
    echo -e "      Dropbear SSH           ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart stunnel4
    echo -e "      Stunnel4 TLS           ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart xray
    echo -e "      Xray Core              ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart nginx
    echo -e "      Nginx WebServer        ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart client-slow
    echo -e "      SlowDNS (DNSTT)        ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart ws-proxy
    echo -e "      SSH-WS Proxy           ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    systemctl restart cron
    echo -e "      Cron Scheduler         ${GREEN}[ RESTARTED ]${NC}"
    sleep 0.5
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}         All Services Restarted Successfully!${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
7|07)
    nano /etc/issue.net
    service dropbear restart
    echo -e "${GREEN}Banner Saved and Applied!${NC}"
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
8|08)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "                   BANDWIDTH MONITOR"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " [1] Live Traffic"
    echo -e " [2] Daily Usage"
    echo -e " [3] Monthly Usage"
    echo ""
    read -p " Select: " bw || exit 1
    if [[ $bw == "1" ]]; then
        vnstat -l
    elif [[ $bw == "2" ]]; then
        vnstat -d
    elif [[ $bw == "3" ]]; then
        vnstat -m
    fi
    echo ""
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
9|09)
    health-check
    echo ""
    read -n 1 -s -r -p "Press any key to return..." || exit 1
    menu-set.sh
    ;;
10)
    clear
    # Define Core Keys
    TECH_PUB="68a93ff4e08ea51657ede89c8dcc6534088d8461c1209743c11b96399beb1408"
    TECH_PRIV="a0946ee29693f2394e60b251b6c9e8d5b2f3bc8d753deebf8ce778773dbe10bc"
    GLOB_PUB="7fbd1f8aa0abfe15a7903e837f78aba39cf61d36f183bd604daa2fe4ef3b7b59"
    GLOB_PRIV="819d82813183e4be3ca1ad74387e47c0c993b81c601b2d1473a3f47731c404ae"

    # Read Current Active Key
    CUR_PUB=$(cat /etc/slowdns/server.pub 2>/dev/null | tr -d '\n')

    # Detect Key Identity
    if [[ "$CUR_PUB" == "$GLOB_PUB" ]]; then
        STATUS="${GREEN}GLOBAL (Universal)${NC}"
    elif [[ "$CUR_PUB" == "$TECH_PUB" ]]; then
        STATUS="${BLUE}TECHYCHI (Default)${NC}"
    else
        STATUS="${YELLOW}CUSTOM (Random)${NC}"
    fi

    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}               SLOWDNS KEY MANAGER                    ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " Current Type : $STATUS"
    echo -e " PubKey       : ${GREEN}${CUR_PUB:0:30}...${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo -e " [1] Switch to Global Key ${GREEN}(Compatible with all scripts)${NC}"
    echo -e " [2] Switch to TechyChi Default Key"
    echo -e " [3] Generate Random Custom Key"
    echo -e " [0] Back to Settings Menu"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select Option: " key_opt || exit 1

    if [[ "$key_opt" == "1" ]]; then
        echo "$GLOB_PRIV" > /etc/slowdns/server.key
        echo "$GLOB_PUB" > /etc/slowdns/server.pub
        chmod 600 /etc/slowdns/server.key
        chmod 644 /etc/slowdns/server.pub
        systemctl restart client-slow
        echo -e " \n${GREEN}✔ Keys updated to GLOBAL! Clients can connect seamlessly.${NC}"
        sleep 2
    elif [[ "$key_opt" == "2" ]]; then
        echo "$TECH_PRIV" > /etc/slowdns/server.key
        echo "$TECH_PUB" > /etc/slowdns/server.pub
        chmod 600 /etc/slowdns/server.key
        chmod 644 /etc/slowdns/server.pub
        systemctl restart client-slow
        echo -e " \n${GREEN}✔ Keys updated to TECHYCHI DEFAULT!${NC}"
        sleep 2
    elif [[ "$key_opt" == "3" ]]; then
        if [[ -x /etc/slowdns/dnstt-server ]]; then
            echo -e " \n${YELLOW}Generating brand new cryptographic keys...${NC}"
            /etc/slowdns/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub > /dev/null 2>&1
            chmod 600 /etc/slowdns/server.key
            chmod 644 /etc/slowdns/server.pub
            systemctl restart client-slow
            echo -e " ${GREEN}✔ Custom Keys Generated and Applied!${NC}"
            sleep 2
        else
            echo -e " \n${RED}Error: dnstt-server binary not found!${NC}"
            sleep 2
        fi
    fi
    menu-set.sh
    ;;
11|11)
    clear
    echo -e "${RED}───────────────────────────────────────────────────────${NC}"
    echo -e "${RED} WARNING: DESTRUCTIVE ACTION INITIATED!${NC}"
    echo -e "${RED}───────────────────────────────────────────────────────${NC}"
    echo -e " This will completely wipe your current OS and rebuild it."
    echo -e " All active configurations, data, and users will be LOST."
    echo ""
    read -p " Are you absolutely sure you want to proceed? [y/N]: " confirm_wipe
    if [[ "$confirm_wipe" =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}Initiating Server Rebuild...${NC}"
        cd /root
        wget https://raw.githubusercontent.com/oktaviaps/rebuild-vps/main/uinstal
        chmod 777 *
        ./uinstal
    else
        echo -e "\n${GREEN}OS Rebuild Aborted. Safe!${NC}"
        sleep 2
        menu-set.sh
    fi
    ;;
12|12)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}           STARTING BBR NETWORK OPTIMIZER             ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " Pulling script from EmadToranji repository...\n"
    bash <(curl -fsSL https://raw.githubusercontent.com/emadtoranji/NetworkOptimizer/main/optimize.sh)
    echo -e "\n${GREEN}✔ Network Optimization Completed!${NC}"
    read -n 1 -s -r -p " Press any key to return to Settings Menu..."
    menu-set.sh
    ;;
0|00)
    menu
    ;;
*)
    echo -e "${RED}[ERROR] Invalid Selection${NC}"
    sleep 1
    menu-set.sh
    ;;
esac
