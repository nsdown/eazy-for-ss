#! /bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install IPSecIKEv1v2 VPN server for Debian by strongSwan 5
#   ipsecIKEv1v2auto-0.1 For Debian Copyright (C) liyangyijie@Gmail released under GNU GPLv2
#===============================================================================================

clear
echo "#############################################################"
echo "# Install  IPSecIKEv1v2 VPN server for Debian 7+"
echo "#############################################################"
echo ""

#install 安装主流程
function install_IPSecIKEv1v2_VPN_server(){
    
#check system , get IP,del test sources 检测系统 获取本机公网ip 去除测试源
    check_Required
	
#add a user 增加初始用户
    add_a_user

#press any key to start 任意键开始
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    print_info "Press any key to start...or Press Ctrl+C to cancel"
    IPSecIKEv1v2_char=`get_char`

#install  安装
    deb_install

#make self-signd ca 制作自签名证书	
    make_IPSecIKEv1v2_ca

#configuration 设定软件相关选项	
    set_IPSecIKEv1v2_conf

#restart 重新启动生效	
    /etc/init.d/ipsec restart    

#show result 显示结果
    show_IPSecIKEv1v2
}

#error and force-exit
function die {
    echo "ERROR: $1" > /dev/null 1>&2
    exit 1
}

#info echo
function print_info {
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

#warn echo
function print_warn {
    echo -n -e '\033[41;37m'
    echo -n $1
    echo -e '\033[0m'
}

#get random word 获取$1位随机文本
function get_random_word(){
    index=0
    str=""
    for i in {a..z}; do arr[index]=$i; index=$(expr ${index} + 1); done
    for i in {A..Z}; do arr[index]=$i; index=$(expr ${index} + 1); done
    for i in {0..9}; do arr[index]=$i; index=$(expr ${index} + 1); done
#$1 figures
    for i in `seq 1 $1`; do str="$str${arr[$RANDOM%$index]}"; done
    echo $str
}

function check_Required {
#check root
    if [ $(/usr/bin/id -u) != "0" ]
    then
        die 'Must be run by root user'
    fi
    print_info "Root ok"
#debian only
    if [ ! -f /etc/debian_version ]
    then
        die "Looks like you aren't running this installer on a Debian-based system"
    fi
    print_info "Debian ok"
#only Debian 7+!!!
    if grep ^6. /etc/debian_version > /dev/null
    then
        die "Your system is debian 6. Only for Debian 7+!!!"
    fi
	
    if grep ^5. /etc/debian_version > /dev/null
    then
        die "Your system is debian 5. Only for Debian 7+!!!"
    fi
    print_info "Debian version ok"
#check install 防止重复安装
    if [ -f /usr/sbin/ipsec ]
    then
        die "Ipsec has been installed!!!"
    fi
    print_info "Not installed ok"
#sources check,test sources 检查源是否已有 
    cat /etc/apt/sources.list | grep 'deb http://ftp.debian.org/debian wheezy-backports main' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        ic_backports="n"
    fi
    print_info "Sources ok"
#get IPv4 info,install tools 
    print_info "Getting ip from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed
    fqdnname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $fqdnname ]; then
        fqdnname=`curl -s liyangyijie.sinaapp.com/ip/`
    fi
    print_info "Get ip ok"
    clear
}

#install 安装
function deb_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | sudo dpkg --set-selections
    apt-get upgrade -y
#deb install 安装主体以及插件
    if [ "$ic_backports" = "n" ]; then
    echo "deb http://ftp.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
    apt-get update
    fi
    apt-get install -y -t wheezy-backports strongswan libcharon-extra-plugins 
#if sources del 如果本来没有测试源便删除
    if [ "$ic_backports" = "n" ]; then
        sed -i '#deb http://ftp.debian.org/debian wheezy-backports main#d' /etc/apt/sources.list
    fi
#keep update
    apt-get update
    print_info "Deb install ok"
}

#add a user 增加一个初始用户
function add_a_user(){
#get username,4 figures default
    Default_username=$(get_random_word 4)
    print_info "Input your username for IPSecIKEv1v2:"
    read -p "(Default :$Default_username):" username
    if [ "$username" = "" ]; then
        username="$Default_username"
    fi
    print_info "Your username:$username"
    echo "####################################"
#get password,if not ca login,6 figures default
    Default_password=$(get_random_word 6)
    print_info "Input your password for IPSecIKEv1v2:"
    read -p "(Default :$Default_password):" password
    if [ "$password" = "" ]; then
        password="$Default_password"
    fi
    print_info "Your password:$password"
    echo "####################################"
#get psk,3 figures default
    Default_psk=$(get_random_word 3)
    print_info "Input your psk for IPSecIKEv1v2:"
    read -p "(Default :$Default_psk):" psk
    if [ "$psk" = "" ]; then
        psk="$Default_psk"
    fi
    print_info "Your psk:$psk"
    echo "####################################"
}

#make a self-signd ca 制作自签证书 客户端登录使用证书
function make_IPSecIKEv1v2_ca(){
    print_info "Making CA ..."
#CREATE YOUR CERTIFICATION AUTHORITY (CA)
    cd /etc/ipsec.d/
    ipsec pki --gen --type rsa --size 4096 --outform pem > private/strongswanKey.pem
    chmod 600 private/strongswanKey.pem
    ipsec pki --self --ca --lifetime 7777 --in private/strongswanKey.pem --type rsa --dn "C=CN, O=strongSwan, CN=strongSwan Root CA" --outform pem > cacerts/strongswanCert.pem
#CREATE YOUR VPN HOST CERTIFICATE
    ipsec pki --gen --type rsa --size 2048 --outform pem > private/vpnHostKey.pem
    chmod 600 private/vpnHostKey.pem
    ipsec pki --pub --in private/vpnHostKey.pem --type rsa | ipsec pki --issue --lifetime 7777 --cacert cacerts/strongswanCert.pem --cakey private/strongswanKey.pem --dn "C=CN, O=strongSwan, CN=$fqdnname" --san $fqdnname --flag serverAuth --flag ikeIntermediate --outform pem > certs/vpnHostCert.pem
#CREATE A CLIENT CERTIFICATE
    ipsec pki --gen --type rsa --size 2048 --outform pem > private/ClientKey.pem
    chmod 600 private/ClientKey.pem
    ipsec pki --pub --in private/ClientKey.pem --type rsa | ipsec pki --issue --lifetime 7777 --cacert cacerts/strongswanCert.pem --cakey private/strongswanKey.pem --dn "C=CN, O=strongSwan, CN=Client VPN" --san Client VPN --outform pem > certs/ClientCert.pem
#EXPORT CLIENT CERTIFICATE AS A PKCS#12 FILE
    openssl pkcs12 -export -inkey /etc/ipsec.d/private/ClientKey.pem -in /etc/ipsec.d/certs/ClientCert.pem -name "Client's VPN Certificate" -certfile /etc/ipsec.d/cacerts/strongswanCert.pem -caname "strongSwan Root CA" -out Client.p12 -passout pass:$password
#MV strongswanKey,PKCS#12 TO ROOT
    mv Client.p12 /root
    cp cacerts/strongswanCert.pem /root
    cp certs/ClientCert.pem /root
    print_info "CA OK"
}

function get_p12_ca(){
    cd ~
#EXPORT CLIENT CERTIFICATE AS A PKCS#12 FILE
    openssl pkcs12 -export -inkey /etc/ipsec.d/private/ClientKey.pem -in /etc/ipsec.d/certs/ClientCert.pem -name "Client's VPN Certificate" -certfile /etc/ipsec.d/cacerts/strongswanCert.pem -caname "strongSwan Root CA" -out Client.p12
}

#set
function set_IPSecIKEv1v2_conf(){
#ipsec
    cat >/etc/ipsec.conf<<EOF
config setup
    uniqueids=never
    charondebug="cfg 2, dmn 2, ike 2, net 2"

#default for all 
conn %default
    ikelifetime=24h
    keylife=24h
    dpdaction=clear
    dpdtimeout=3600s
    dpddelay=3600s
    compress=yes
    left=%defaultroute
    leftsubnet=0.0.0.0/0
    leftcert=vpnHostCert.pem
    right=%any
    rightcert=ClientCert.pem
    rightsourceip=10.89.32.0/24

# compatible with "strongSwan VPN Client" for Android 4.0+
# and Windows 7 cert mode. 
conn networkmanager-strongswan
    keyexchange=ikev2
    leftauth=pubkey
    rightauth=pubkey
    auto=add

# for win esp mode 
conn windows_eap
    keyexchange=ikev2
    ike=aes256-sha1-modp1024!
    esp=aes256-sha1!
    leftid="C=CN, O=strongSwan, CN=$fqdnname"
    leftauth=pubkey
    rekey=no
    rightauth=eap-mschapv2
    rightsendcert=never
    eap_identity=%any
    auto=add

# for ios cert mode. 
conn iOS_cert
    keyexchange=ikev1
    # strongswan version >= 5.0.2, compatible with iOS 6.0,6.0.1
    fragmentation=yes
    leftauth=pubkey
    right=%any
    rightauth=pubkey
    rightauth2=xauth
    auto=add

# for psk mode 
conn ios_android_xauth_psk
    fragmentation=yes
    keyexchange=ikev1
    leftauth=psk
    rightauth=psk
    rightauth2=xauth
    auto=add
EOF
#strongswan
    cat >/etc/strongswan.conf<<'EOF'
# strongswan.conf - strongSwan configuration file
#
# Refer to the strongswan.conf(5) manpage for details
#
# Configuration changes should be made in the included files

charon {
    load_modular = yes
    duplicheck.enable = no
    dns1 = 8.8.8.8
    dns2 = 8.8.4.4
    nbns1 = 8.8.8.8
    nbns2 = 8.8.4.4
    
	plugins {
		include strongswan.d/charon/*.conf
	}
    
    filelog {
        /var/log/strongswan.charon.log {
            time_format = %b %e %T
            default = 2
            append = no
            flush_line = yes
        }
    }
}
EOF
#secrets
    cat >/etc/ipsec.secrets<<EOF
# /etc/ipsec.secrets - strongSwan IPsec secrets file
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.

# this file is managed with debconf and will contain the automatically created private key
#include /var/lib/strongswan/ipsec.secrets.inc
: RSA vpnHostKey.pem
: PSK "$psk"
$username : XAUTH "$password" 
$username : EAP "$password"
# get secrets from other files
#include ipsec.*.secrets
EOF
#iptables and sysctl 'EOF' then $ok>$/etc/default/ipsec
    cat >/etc/ipsec.d/start-ipsec-sysctl.sh<<'EOF'
#! /bin/bash

# turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway and ip pool
gw_IPsec=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
IP_pool_IPSec=`cat /etc/ipsec.conf | grep "rightsourceip" | sed 's/.*rightsourceip=//'`

# turn on NAT over default gateway and VPN
if !(iptables-save -t nat | grep -q "$gw_IPsec (IPSecIKEv1v2_1)"); then
iptables -t nat -A POSTROUTING -s $IP_pool_IPSec -o $gw_IPsec -m comment --comment "$gw_IPsec (IPSecIKEv1v2_1)" -j MASQUERADE
fi

if !(iptables-save -t filter | grep -q "$gw_IPsec (IPSecIKEv1v2_2)"); then
iptables -A FORWARD -s $IP_pool_IPSec -m comment --comment "$gw_IPsec (IPSecIKEv1v2_2)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_IPsec (IPSecIKEv1v2_3)"); then
iptables -A INPUT -p udp --dport 500 -m comment --comment "$gw_IPsec (IPSecIKEv1v2_3)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_IPsec (IPSecIKEv1v2_4)"); then
iptables -A INPUT -p udp --dport 4500 -m comment --comment "$gw_IPsec (IPSecIKEv1v2_4)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_IPsec (IPSecIKEv1v2_5)"); then
iptables -A INPUT -p udp --dport 1701 -m comment --comment "$gw_IPsec (IPSecIKEv1v2_5)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_IPsec (IPSecIKEv1v2_6)"); then
iptables -A INPUT -p esp -m comment --comment "$gw_IPsec (IPSecIKEv1v2_6)" -j ACCEPT
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$gw_IPsec (IPSecIKEv1v2_7)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_IPsec (IPSecIKEv1v2_7)" -j TCPMSS --clamp-mss-to-pmtu
fi
EOF
    chmod +x /etc/ipsec.d/start-ipsec-sysctl.sh
    cat >/etc/ipsec.d/stop-ipsec-sysctl.sh<<'EOF'
#! /bin/bash

# uncomment if you want to turn off IP forwarding
# sysctl -w net.ipv4.ip_forward=0

#del iptables
iptables-save | grep 'IPSecIKEv1v2' | sed 's/^-A P/iptables -t nat -D P/' | sed 's/^-A FORWARD -p/iptables -t mangle -D FORWARD -p/' | sed 's/^-A/iptables -D/' | bash

EOF
    chmod +x /etc/ipsec.d/stop-ipsec-sysctl.sh
#change ipsec for set iptables
    sed -i '/test if charon is currently running/a\. /etc/ipsec.d/start-ipsec-sysctl.sh' /etc/init.d/ipsec
    sed -i '/give the proper signal to stop/a\. /etc/ipsec.d/stop-ipsec-sysctl.sh' /etc/init.d/ipsec
#boot from the start 开机自启
    sudo insserv ipsec
    print_info "set OK"
}


#show result
function show_IPSecIKEv1v2(){
    clear
    pidof charon > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname"
        echo -e "\033[41;37m Your username is \033[0m" "$username"
        echo -e "\033[41;37m Your password is \033[0m" "$password"
        echo -e "\033[41;37m Your psk is \033[0m" "$psk"
        echo -e "\033[41;37m Your ClientCert's password is \033[0m" "$password"
        print_warn " You can stop IPSecIKEv1v2 by ' /etc/init.d/ipsec stop '!"
        print_warn " Boot from the start or not, use ' sudo insserv ipsec ' or ' sudo insserv -r ipsec '."
        echo ""    
        print_info " Enjoy it!"
        echo ""
    else
        print_warn "IPSecIKEv1v2 start failure,IPSecIKEv1v2 is offline!"	
    fi
}

#Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_IPSecIKEv1v2_VPN_server
    ;;
getca)
    get_p12_ca
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|getca}"
    ;;
esac
