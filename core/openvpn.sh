#!/bin/bash
# ==========================================
#  OpenVPN Auto-Installer Module (Dual TCP/UDP)
# ==========================================
domain=$(cat /etc/xray/domain)
MYIP=$(curl -sS -4 ifconfig.me)

echo -e " [INFO] Installing OpenVPN and Easy-RSA..."
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Install OpenVPN without the persistent packages to avoid UFW conflicts
apt-get install -y openvpn easy-rsa > /dev/null 2>&1

echo -e " [INFO] Generating Cryptographic Keys (Takes ~1 minute)..."
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

export EASYRSA_BATCH=1
./easyrsa init-pki > /dev/null 2>&1
./easyrsa build-ca nopass > /dev/null 2>&1
./easyrsa build-server-full server nopass > /dev/null 2>&1
./easyrsa gen-dh > /dev/null 2>&1
openvpn --genkey secret ta.key

cp pki/ca.crt /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/dh.pem /etc/openvpn/dh2048.pem
cp ta.key /etc/openvpn/

PLUGIN=$(find /usr -type f -name "openvpn-plugin-auth-pam.so" | head -n 1)

echo -e " [INFO] Configuring Server 1: TCP (Port 1194)..."
cat > /etc/openvpn/server-tcp.conf <<EOF
port 1194
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp-tcp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-tcp.log
verb 3
plugin $PLUGIN login
verify-client-cert none
username-as-common-name
duplicate-cn
EOF

echo -e " [INFO] Configuring Server 2: UDP (Port 2200)..."
cat > /etc/openvpn/server-udp.conf <<EOF
port 2200
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp-udp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-udp.log
verb 3
plugin $PLUGIN login
verify-client-cert none
username-as-common-name
duplicate-cn
EOF

echo -e " [INFO] Configuring Network Routing..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p > /dev/null 2>&1

NIC=$(ip -o -4 route show to default | head -n1 | awk '{print $5}')

# Dynamic VPN Routing Injector (Bypasses UFW Flushing)
cat > /etc/systemd/system/vpn-routing.service <<EOF
[Unit]
Description=VPN Routing Injector
After=network.target ufw.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c "iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE; iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $MYIP; iptables -t nat -I POSTROUTING -s 10.9.0.0/24 -o $NIC -j MASQUERADE; iptables -t nat -I POSTROUTING -s 10.9.0.0/24 -j SNAT --to-source $MYIP"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-routing > /dev/null 2>&1
systemctl start vpn-routing > /dev/null 2>&1

systemctl daemon-reload
systemctl enable openvpn@server-tcp
systemctl enable openvpn@server-udp
systemctl restart openvpn@server-tcp
systemctl restart openvpn@server-udp

echo -e " [INFO] Generating Client Profiles..."
# TCP Client
cat > /etc/openvpn/client-tcp.ovpn <<EOF
client
dev tun
proto tcp
remote $domain 1194
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

# UDP Client
cat > /etc/openvpn/client-udp.ovpn <<EOF
client
dev tun
proto udp
remote $domain 2200
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

# --- NGINX DOWNLOAD LINK SETUP ---
echo -e " [INFO] Setting up Nginx Download Directory..."
mkdir -p /var/www/html/ovpn
cp /etc/openvpn/client-tcp.ovpn /var/www/html/ovpn/client-tcp.ovpn
cp /etc/openvpn/client-udp.ovpn /var/www/html/ovpn/client-udp.ovpn
chmod 644 /var/www/html/ovpn/*.ovpn

cat > /etc/nginx/conf.d/ovpn-download.conf <<EOF
server {
    listen 85;
    server_name _;
    root /var/www/html/ovpn;
    autoindex on;
}
EOF
systemctl restart nginx

echo -e " [OK] Dual OpenVPN Setup Complete!"