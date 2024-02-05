#!/bin/bash

# Configuration variables
BRIDGE_INTERFACE="br0"
WIFI_INTERFACE="wlan0"
ETH_INTERFACE="eth1"
SSID="escuplast-freza"
WPA_PASSPHRASE="virtual1234"
DHCP_RANGE_START="192.168.4.2"
DHCP_RANGE_END="192.168.4.20"
DHCP_RANGE_MASK="255.255.255.0"
DHCP_LEASE_TIME="24h"
NETWORK="192.168.4.0"

# Install necessary packages
echo "Checking and installing necessary packages..."
apt-get update
apt-get install -y iptables bridge-utils hostapd dnsmasq

# Stop services before configuring
systemctl stop hostapd
systemctl stop dnsmasq

# Create and configure network bridge
echo "Creating and configuring network bridge..."
ip link add name $BRIDGE_INTERFACE type bridge
ip link set dev $BRIDGE_INTERFACE up
ip link set dev $WIFI_INTERFACE master $BRIDGE_INTERFACE
ip link set dev $ETH_INTERFACE master $BRIDGE_INTERFACE

# Assign static IP address to the bridge interface
echo "Assigning static IP address 192.168.4.1 to $BRIDGE_INTERFACE..."
ip addr flush dev $WIFI_INTERFACE
ip addr flush dev $ETH_INTERFACE
ip addr add 192.168.4.1/24 brd + dev $BRIDGE_INTERFACE

# Configure hostapd for WiFi interface without assigning IP
echo "Configuring hostapd..."
cat > /etc/hostapd/hostapd.conf <<EOF
interface=$WIFI_INTERFACE
bridge=$BRIDGE_INTERFACE
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
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure dnsmasq for DHCP on the bridge interface
echo "Configuring dnsmasq..."
cat > /etc/dnsmasq.conf <<EOF
interface=$BRIDGE_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_RANGE_MASK,$DHCP_LEASE_TIME
EOF

# Enable IP forwarding
echo "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configure NAT
echo "Configuring NAT..."
iptables -t nat -A POSTROUTING -o $BRIDGE_INTERFACE -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Setup to load the NAT rule on boot
echo "Setting up NAT rule to load on boot..."
cat > /etc/rc.local <<EOF
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF
chmod +x /etc/rc.local

# Enable and start hostapd and dnsmasq
echo "Enabling and starting hostapd and dnsmasq..."