#!/bin/sh

# uncomment if you want to turn off IP forwarding
# sysctl -w net.ipv4.ip_forward=0

#get gateway
gw_intf2=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
ocserv_tcpport=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
ocserv_udpport=`cat /etc/ocserv/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g'`
ocserv_ip4work=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-network' | sed 's/ipv4-network = //g'`
ocserv_ip4mask=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-netmask' | sed 's/ipv4-netmask = //g'`


# turn on NAT over default gateway and VPN


iptables -t nat -D POSTROUTING -s $ocserv_ip4work/$ocserv_ip4mask -o $gw_intf2 -m comment --comment "$gw_intf2 (ocserv)" -j MASQUERADE



iptables -D FORWARD -s $ocserv_ip4work/$ocserv_ip4mask -m comment --comment "$gw_intf2 (ocserv2)" -j ACCEPT



iptables -D INPUT -p tcp --dport $ocserv_tcpport -m comment --comment "$gw_intf2 (ocserv3)" -j ACCEPT



iptables -D INPUT -p udp --dport $ocserv_udpport -m comment --comment "$gw_intf2 (ocserv4)" -j ACCEPT


# turn off MSS fix
# MSS = MTU - TCP header - IP header

iptables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_intf2 (ocserv5)" -j TCPMSS --clamp-mss-to-pmtu

echo "..."
