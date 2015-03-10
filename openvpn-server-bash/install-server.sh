#!/bin/bash
# install a new OpenVPN server

if [ `whoami` != "root" ]; then
    echo "You must be root to run this script"
    exit 1
fi

SOURCE="/usr/share/doc/openvpn/examples/easy-rsa"
CONF="/etc/openvpn"
BASE="/etc/openvpn/easy-rsa/2.0"

if [ -e "$CONF/keys/ca.crt" ]; then
    echo "ERROR: OpenVPN has been configured on this server."
    echo "If you want to re-deploy OpenVPN, remove dir $CONF/keys and rerun this script."
    echo "WARNING: By removing $CONF/keys, all existing users will no longer be able to login."
    exit 1
fi

if ! command -v "openvpn"; then
    echo "OpenVPN not installed, installing..."
    apt-get install openvpn
fi

if [ ! -d "$SOURCE" ]; then
    echo "$SOURCE does not exist, please check your openvpn installation"
    exit 1
fi
if [ ! -d "$CONF" ]; then
    echo "OpenVPN config dir $CONF does not exist"
    exit 1
fi
cp -R /usr/share/doc/openvpn/examples/easy-rsa/ $CONF

pushd $BASE >/dev/null

echo -n "Input server hostname for clients to connect: "
read hostname

echo -n "Input virtual network addr [10.8.0.0]: "
read virtnet
if [ -z "$virtnet" ]; then
    virtnet="10.8.0.0"
fi
if [[ ! "$virtnet" =~ ^([0-9]{1,3}\.){2}0\.0$ ]]; then
    echo "Invalid IPv4 address (IPv6 is not supported)"
    echo "Virtual Network should be /16 (*.*.0.0)"
    exit 1
fi

echo "Input information of your organization (if you wish to leave it as default, press Enter):"
read -p "Country [CN]: " country
country=${country:-CN}
read -p "Province [Anhui]: " province
province=${province:-Anhui}
read -p "City [Hefei]: " city
city=${city:-Hefei}
read -p "Organization [LUG@USTC]: " org
org=${org:-LUG@USTC}
read -p "Email [lug@ustc.edu.cn]: " email
email=${email:-lug@ustc.edu.cn}

sed -i '/^export KEY_\(COUNTRY\|PROVINCE\|CITY\|ORG\|EMAIL\)\(.*\)$/d' vars
echo "export KEY_COUNTRY='$country'" >> vars
echo "export KEY_PROVINCE='$province'" >> vars
echo "export KEY_CITY='$city'" >> vars
echo "export KEY_ORG='$org'" >> vars
echo "export KEY_EMAIL='$email'" >> vars

echo "Generating keys..."
. ./vars
. ./clean-all
. ./build-ca
. ./build-key-server server
. ./build-dh

mkdir -p $CONF/keys
cp $BASE/keys/{ca.crt,ca.key,dh1024.pem,server.crt,server.key} $CONF/keys
popd >/dev/null

echo "Generating config files from template..."
pushd `dirname $0` >/dev/null
sed -i "s/vpn.lug.ustc.edu.cn/$hostname/g" client.conf server.conf
sed -i "s/10.8.0.0/$virtnet/g" client.conf server.conf
dns=8.8.4.4
#dns=$(echo $virtnet | awk 'BEGIN{FS="."}{print $1 "." $2 "." $3 "." $4+1}')
sed -i "s/10.8.0.1/$dns/g" client.conf server.conf
cp server.conf $CONF
popd >/dev/null

echo "Configuring network..."
# enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
sed -i 's/^\(net.ipv4.ip_forward\)\(.*\)$/#\1\2/' /etc/sysctl.conf  # comment out old setting
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# iptables SNAT
if ! command -v "iptables"; then
    echo "iptables not installed, installing..."
    apt-get install iptables
fi
INIT_COMMAND="iptables -t nat -A POSTROUTING -s $virtnet/16 -j MASQUERADE"
eval $INIT_COMMAND

# dnsmasq for push DNS server
#if ! command -v "dnsmasq"; then
#   echo "DNSmasq not installed, installing..."
#   apt-get install dnsmasq
#fi

echo "====== DONE ======"
echo "You need to add the following command to init script (e.g. /etc/rc.local)"
echo "$INIT_COMMAND"
