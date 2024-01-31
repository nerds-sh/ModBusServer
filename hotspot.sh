#!/bin/bash

# Configuration variables
WIFI_INTERFACE="wlan0"
ETH_INTERFACE="eth0"
SSID="escuplast-freza"
WPA_PASSPHRASE="virtual1234"
DHCP_RANGE_START="192.168.4.2"
DHCP_RANGE_END="192.168.4.20"
DHCP_RANGE_MASK="255.255.255.0"
DHCP_LEASE_TIME="24h"
NETWORK="192.168.4.0"

# Check if iptables exists, if not, install it
if ! command -v iptables >/dev/null; then
    echo "iptables not found, installing..."
    apt-get update
    apt-get install -y iptables
else
    echo "iptables is already installed."
fi

# Install hostapd and dnsmasq
# echo "Installing hostapd and dnsmasq..."
# apt-get update
# apt-get install -y hostapd dnsmasq

# Stop services before configuring
systemctl stop hostapd
systemctl stop dnsmasq

# Configure hostapd
echo "Configuring hostapd..."
cat > /etc/hostapd/hostapd.conf <<EOF
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WPA_PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Tell hostapd where to find its configuration file
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure dnsmasq
echo "Configuring dnsmasq..."
cat > /etc/dnsmasq.conf <<EOF
interface=$WIFI_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_RANGE_MASK,$DHCP_LEASE_TIME
EOF

# Assign static IP address to the Wi-Fi interface
echo "Assigning static IP address 192.168.4.1 to $WIFI_INTERFACE..."
ip addr flush dev $WIFI_INTERFACE
ip addr add 192.168.4.1/24 dev $WIFI_INTERFACE

# Enable IP forwarding
echo "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configure NAT
echo "Configuring NAT..."
iptables -t nat -A POSTROUTING -o $ETH_INTERFACE -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Setup to load the NAT rule on boot
cat > /etc/rc.local <<EOF
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF

chmod +x /etc/rc.local

# Enable and start hostapd and dnsmasq
echo "Enabling and starting hostapd and dnsmasq..."
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd
systemctl enable dnsmasq
systemctl restart dnsmasq

echo "Wi-Fi hotspot setup complete. SSID: $SSID with passphrase: $WPA_PASSPHRASE"

# Reminder for persistent static IP configuration
echo "Please ensure to configure a static IP for wlan0 (192.168.4.1) in /etc/dhcpcd.conf for persistence across reboots."

# Enable the hotspot on boot
systemctl enable hotspot-setup.service

