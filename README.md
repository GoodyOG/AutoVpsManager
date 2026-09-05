# GoodyOG AutoVpsManager
### **Premium Multi-Protocol VPS Management Script — Powered by TechyChi**

![Status](https://img.shields.io/badge/Status-Stable-green)
![OS](https://img.shields.io/badge/OS-Ubuntu%2020%2F22%2F24-blue)
![Edition](https://img.shields.io/badge/Edition-Premium-gold)

**GoodyOG AutoVpsManager** is an advanced, high-performance automation script designed for the seamless deployment and management of a secure tunneling environment. It integrates multiple protocols to bypass restrictive firewalls and Deep Packet Inspection (DPI).

---

## 🚀 One-Step Installation

Copy and paste the command below into your root terminal to begin the automated setup:

```bash
apt update && apt install -y wget && wget -q https://raw.githubusercontent.com/GoodyOG/AutoVpsManager/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

---

## ✨ Features

### Core Tunneling Protocols
| Protocol | Transport | Port | TLS |
|----------|-----------|------|-----|
| **SSH** | OpenSSH | 22 | ❌ |
| **SSH-WS** | WebSocket (HTTP) | 80 | ❌ |
| **SSH-WS (Custom)** | WebSocket (HTTP) | 8880 | ❌ |
| **SSH-SSL-WS** | WebSocket (HTTPS) | 443 | ✅ |
| **Dropbear** | Direct | 109, 143 | ❌ |
| **Stunnel4** | TLS wrapper | 447, 777 | ✅ |
| **VLESS** | WebSocket | 443 (TLS) / 80 (No-TLS) | ✅ / ❌ |
| **VLESS** | HTTPUpgrade | 443 | ✅ |
| **VMess** | WebSocket | 443 (TLS) / 80 (No-TLS) | ✅ / ❌ |
| **VMess** | HTTPUpgrade | 443 | ✅ |
| **Trojan** | WebSocket | 443 (TLS) / 80 (No-TLS) | ✅ / ❌ |
| **SOCKS5** | Direct | 1080 | ❌ |
| **SlowDNS (DNSTT)** | DNS Tunnel | 53, 5300 | ❌ |
| **BadVPN UDPGW** | UDP Gateway | 7100-7300 | ❌ |

### Network Optimization
- **BBR congestion control** enabled automatically during setup
- `fq` queuing discipline applied to active interface
- TCP Fast Open enabled
- Auto-applied on every fresh install, persists across reboots

### Bandwidth Monitoring
- vnStat-based bandwidth tracking
- Live, daily, and monthly usage displayed in the main menu
- Updates every 60 seconds

### Account Management
- **SSH**: Create, trial, timed, renew, delete, list, lock, multi-login control
- **VMess**: Create, trial, extend, delete, check login, list members
- **VLESS**: Create, trial, extend, delete, check login, list members
- **Trojan**: Create (TLS + No-TLS), trial, extend, delete, check login, list members
- Auto-expiry cleanup runs daily
- AutoKill system for multi-login violations
- Security lock/unlock with strike tracking

### System Tools
- Speedtest (Ookla CLI)
- Port info display
- Auto-reboot scheduling (interval or specific time)
- Restart all services
- Change SSH banner
- Server health check
- SlowDNS key manager
- Backup to Google Drive + Telegram
- Restore from backup
- DDoS Deflate protection

---

## 📋 Main Menu Options

```
[01] SSH     [Menu]      [06] BACKUP
[02] VMESS   [Menu]      [07] DOMAIN & SSL
[03] VLESS   [Menu]      [08] CHECK RUNNING
[04] TROJAN  [Menu]      [00] EXIT SYSTEM
[05] SETTING [Menu]
```

---

## ⚙️ Requirements

- **OS:** Ubuntu 20.04 / 22.04 / 24.04 LTS
- **Architecture:** x86_64
- **RAM:** 512 MB minimum (1 GB+ recommended)
- **Root access** required
- **Domain** with A record pointing to your server IP

---

## 🔐 Notes

- OpenVPN has been removed from this fork.
- BBR is activated automatically during installation — no manual setup needed.
- All default Xray placeholder credentials should be replaced after first login.
- The script reboots the server after a successful installation.

---

## 📜 License

**GoodyOG AutoVpsManager** — Premium Edition