#!/bin/bash
# --- GoodyOG & TechyChi Settings ---

trap 'clear; exit 0' SIGINT

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               SYSTEM SETTINGS MANAGER                ${NC}"
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
echo -e " [\033[0;32m11\033[0m]  REINSTALL SYSTEM (Total Wipe)"
echo -e " [\033[0;32m00\033[0m]  Back To Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e ""
read -p " Select Option : " opt

case $opt in
    1|01) speedtest ;;
    2|02) show-conf ;;
    3|03)
        echo -e "\n[Auto Reboot Interval]"
        echo "1. Every 1 Hour"
        echo "2. Every 6 Hours"
        echo "3. Every 12 Hours"
        read -p "Select [1-3]: " interval
        case $interval in
            1) echo "0 * * * * root reboot" > /etc/cron.d/auto_reboot ;;
            2) echo "0 */6 * * * root reboot" > /etc/cron.d/auto_reboot ;;
            3) echo "0 */12 * * * root reboot" > /etc/cron.d/auto_reboot ;;
        esac
        echo -e "${GREEN}Interval Reboot Set!${NC}"; sleep 2 ;;
    4|04)
        read -p "Set reboot hour (0-23): " hr
        echo "0 $hr * * * root reboot" > /etc/cron.d/auto_reboot
        echo -e "${GREEN}Daily Reboot set to $hr:00${NC}"; sleep 2 ;;
    5|05) if [ -f /root/reboot.log ]; then cat /root/reboot.log; else echo "No logs"; fi; read -p "Press Enter to continue" ;;
    6|06) systemctl restart ssh dropbear xray nginx ws-proxy ws-8880 stunnel4 danted client-slow; echo -e "${GREEN}Services Restarted!${NC}"; sleep 2 ;;
    7|07) nano /etc/issue.net; systemctl restart dropbear ;;
    8|08) vnstat; read -p "Press Enter to continue" ;;
    9|09) health-check; read -p "Press Enter to continue" ;;
    10) cat /etc/slowdns/server.pub; read -p "Press Enter to continue" ;;
    11) echo -e "${RED}Wiping VPS...${NC}"
        wget -q https://raw.githubusercontent.com/oktaviaps/rebuild-vps/main/uinstal; chmod 777 uinstal; ./uinstal ;;
    0|00) menu; exit 0 ;;
    *) echo -e "${RED}Invalid Option${NC}"; sleep 1; exit 1 ;;
esac
