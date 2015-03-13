#!/bin/bash

# turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway
gw_intf2=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
ocserv_tcpport=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
ocserv_udpport=`cat /etc/ocserv/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g'`
ocserv_ip4work=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-network' | sed 's/ipv4-network = //g'`
ocserv_ip4mask=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-netmask' | sed 's/ipv4-netmask = //g'`


# turn on NAT over default gateway and VPN

if !(iptables-save -t nat | grep -q "$gw_intf2 (ocserv)"); then
iptables -t nat -A POSTROUTING -s $ocserv_ip4work/$ocserv_ip4mask -o $gw_intf2 -m comment --comment "$gw_intf2 (ocserv)" -j MASQUERADE
fi

if !(iptables-save -t filter | grep -q "$gw_intf2 (ocserv2)"); then
iptables -A FORWARD -s $ocserv_ip4work/$ocserv_ip4mask -m comment --comment "$gw_intf2 (ocserv2)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_intf2 (ocserv3)"); then
iptables -A INPUT -p tcp --dport $ocserv_tcpport -m comment --comment "$gw_intf2 (ocserv3)" -j ACCEPT
fi

if [ "$ocserv_udpport" != "" ]; then
    if !(iptables-save -t filter | grep -q "$gw_intf2 (ocserv4)"); then
        iptables -A INPUT -p udp --dport $ocserv_udpport -m comment --comment "$gw_intf2 (ocserv4)" -j ACCEPT
    fi
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$gw_intf2 (ocserv5)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_intf2 (ocserv5)" -j TCPMSS --clamp-mss-to-pmtu
fi

echo "..."
