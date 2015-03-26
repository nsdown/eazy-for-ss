#!/bin/bash
echo "Well,we have to make a static.key in China..."
My_port=`cat /etc/openvpn/server.conf |grep port|grep -v ^#|grep -v '^;'|sed 's/port //'`
My_IP=`wget -qO- ipv4.icanhazip.com`
if [ $? -ne 0 -o -z $My_IP ]; then
    apt-get install -qq -y dnsutils
    My_IP=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
fi
My_ovpn=`ls /root/ |grep '.ovpn$'|grep -v 'inchina.ovpn$'|sed 's/.ovpn$//'`
My_ovpn_inchina=`ls /root/ |grep 'inchina.ovpn$'`
if [ $My_ovpn = "" ]; then
    echo "Opvn file Not Found"
    exit 1
fi
if [ "$My_ovpn_inchina" != "" ]; then
    echo "We have got a static-key"
    exit 1
fi

echo "Okay,  We are ready to change it to static-key mode now."
read -n1 -r -p "Press any key to continue..."

cd /etc/openvpn/
openvpn --genkey --secret static.key
mv server.conf server_conf_origin

cat > server.conf<<EOF
port $My_port
proto tcp-server
ifconfig 10.8.0.1 10.8.0.2
dev tun
secret static.key
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.4.4"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
comp-lzo
status openvpn-status.log
verb 3
persist-key
persist-tun
sndbuf 1048576
rcvbuf 1048576
txqueuelen 1000

EOF

cat > /root/${My_ovpn}-inchina.ovpn<<EOF
client
dev tun
proto tcp-client
remote $My_IP $My_port
ifconfig 10.8.0.2 10.8.0.1
comp-lzo
verb 3
persist-key
;persist-tun
tun-mtu 1356
ping 25
ping-restart 60
redirect-gateway def1

EOF

echo "<secret>" >> /root/${My_ovpn}-inchina.ovpn
cat static.key >> /root/${My_ovpn}-inchina.ovpn
echo "</secret>" >> /root/${My_ovpn}-inchina.ovpn
/etc/init.d/openvpn restart

echo "You can get ${My_ovpn}-inchina.ovpn in /root"
echo "enjoy it!" 
