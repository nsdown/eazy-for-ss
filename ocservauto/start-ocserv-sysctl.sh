#!/bin/bash

#vars
OCSERV_CONFIG="/etc/ocserv/ocserv.conf"

# turn on IP forwarding
#sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway and profiles
gw_intf_oc=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
ocserv_tcpport=`cat $OCSERV_CONFIG | grep '^tcp-' |  cut -d ' ' -f 3`
ocserv_udpport=`cat $OCSERV_CONFIG | grep '^udp-' |  cut -d ' ' -f 3`
ocserv_ip4_work_mask=`cat $OCSERV_CONFIG | grep '^ipv4-' | cut -d ' ' -f 3 | sed 'N;s|\n|/|g'`


# turn on NAT over default gateway and VPN
if !(iptables-save -t nat | grep -q "$gw_intf_oc (ocserv)"); then
iptables -t nat -A POSTROUTING -s $ocserv_ip4_work_mask -o $gw_intf_oc -m comment --comment "$gw_intf_oc (ocserv)" -j MASQUERADE
fi

if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv2)"); then
iptables -A FORWARD -s $ocserv_ip4_work_mask -m comment --comment "$gw_intf_oc (ocserv2)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv3)"); then
iptables -A INPUT -p tcp --dport $ocserv_tcpport -m comment --comment "$gw_intf_oc (ocserv3)" -j ACCEPT
fi

if [ "$ocserv_udpport" != "" ]; then
    if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv4)"); then
        iptables -A INPUT -p udp --dport $ocserv_udpport -m comment --comment "$gw_intf_oc (ocserv4)" -j ACCEPT
    fi
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$gw_intf_oc (ocserv5)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_intf_oc (ocserv5)" -j TCPMSS --clamp-mss-to-pmtu
fi

echo -n "..."
