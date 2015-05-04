#!/bin/bash

#vars
PPTP_CONFIG="/etc/pptpd.conf"

# turn on IP forwarding
#sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway and profiles
GATEWAY=`ip route show|sed -n 's/^default.* dev \([^ ]*\).*/\1/p'`
pptp_ip4_work_mask=`sed -n 's|^localip[ \t]*\(.*\..*\..*\.\).*|\10/24|p' $PPTP_CONFIG`


# turn on NAT over default gateway and VPN
if !(iptables-save -t nat | grep -q "$GATEWAY (pptp_1)"); then
iptables -t nat -A POSTROUTING -s $pptp_ip4_work_mask -o $GATEWAY -m comment --comment "$GATEWAY (pptp_1)" -j MASQUERADE
fi

if !(iptables-save -t filter | grep -q "$GATEWAY (pptp_2)"); then
iptables -A FORWARD -s $pptp_ip4_work_mask -m comment --comment "$GATEWAY (pptp_2)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$GATEWAY (pptp_3)"); then
iptables -A INPUT -p tcp --dport 1723 -m comment --comment "$GATEWAY (pptp_3)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$GATEWAY (pptp_4)"); then
iptables -A INPUT --protocol 47 -m comment --comment "$GATEWAY (pptp_4)" -j ACCEPT
fi

#supposedly makes the vpn work better
if !(iptables-save -t filter | grep -q "$GATEWAY (pptp_5)"); then
iptables -A FORWARD -s $pptp_ip4_work_mask -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "$GATEWAY (pptp_5)" -j TCPMSS --set-mss 1356
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$GATEWAY (pptp_6)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$GATEWAY (pptp_6)" -j TCPMSS --clamp-mss-to-pmtu
fi

if !(iptables-save -t filter | grep -q "$GATEWAY (pptp_7)"); then
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -m comment --comment "$GATEWAY (pptp_7)" -j ACCEPT
fi

echo -n "..."
