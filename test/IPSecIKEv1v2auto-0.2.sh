#! /bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install IPSecIKEv1v2 VPN server for Debian by strongSwan 5
#   IPSecIKEv1v2auto For Debian Copyright (C) liyangyijie released under MIT
#===============================================================================================

###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################

#force-exit
function die {
    echo -e "\033[33mERROR: $1 \033[0m" > /dev/null 1>&2
    exit 1
}
#info echo
function print_xxxx {
    xXxX="#############################"
    echo
    echo "$xXxX$xXxX$xXxX$xXxX"
    echo
}
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
#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
#if yes or no 
    echo -e -n "\e[1;36m$Temp_question\e[0m""\033[31m(Default:$Temp_default_var): \033[0m"
    read Temp_var
    if [ "$Temp_default_var" = "y" ] || [ "$Temp_default_var" = "n" ] ; then
        case $Temp_var in
            y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
                Temp_var=y
                ;;
            n|N|No|NO|no|nO)
                Temp_var=n
                ;;
            *)
                Temp_var=$Temp_default_var
                ;;
        esac
    else
        Temp_var=${Temp_var:-$Temp_default_var}        
    fi
    Temp_cmd="$Temp_var_name='$Temp_var'"
    eval $Temp_cmd
    echo
    print_info "Your answer is : ${Temp_var}"
    echo
    print_xxxx
}
#Press any key to start
function press_any_key {
    echo
    print_info "Press any key to start...or Press Ctrl+C to cancel"
    get_char_ffff(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }    
    get_char_fffff=`get_char_ffff`
    echo
}
#get random word
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

###################################################################################################################
#main-function                                                                                                    #
###################################################################################################################

#main-install 安装主流程
function install_IPSecIKEv1v2_VPN_server(){
    
#check system , get IP 检测系统 获取本机公网ip 简单判断vps类型
    check_Required
	
#add a user 增加初始用户
    add_a_user

#press any key to start 任意键开始
    press_any_key

#install  安装
    tar_install

#make self-signd ca 制作自签名证书	
    make_IPSecIKEv1v2_ca

#configuration 设定软件相关选项	
    set_IPSecIKEv1v2_conf

#restart 重新启动生效	
    /etc/init.d/ipsec restart    

#show result 显示结果
    show_IPSecIKEv1v2
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
#check install 防止重复安装
    if [ -f /usr/sbin/ipsec ]
    then
        die "Ipsec has been installed!!!"
    fi
    print_info "Not installed ok"
#get IPv4 info,install tools 
    print_info "Getting ip from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed
    fqdnname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $fqdnname ]; then
        fqdnname=`curl -s ipinfo.io|grep ip|cut -d'"' -f4`
    fi
    print_info "Get ip ok"
#vps type
    ip route show|sed -n 's/^def.* dev \([^ ]*\).*/\1/p'|grep ^v  > /dev/null 2>&1
    [ $? -eq 0 ] && openvz="y"
    openvz=${openvz:-n}
    clear
}

#编译安装
function tar_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | sudo dpkg --set-selections > /dev/null 2>&1
    apt-get upgrade -y
#安装必要依赖
    DEBIAN_FRONTEND=noninteractive apt-get install -y libpam0g-dev libssl-dev make gcc build-essential pkg-config m4 libcurl4-openssl-dev libtspi-dev    
#获取最新版本
    cd /root
    wget -c http://download.strongswan.org/strongswan.tar.gz
    tar xzf strongswan.tar.gz
    rm strongswan.tar.gz
    cd strongswan-*
    [ "$openvz" = "y" ] && Add_Parameter="--enable-kernel-libipsec"
    ./configure -prefix=/usr -sysconfdir=/etc -libexecdir=/usr/lib --enable-eap-identity --enable-eap-md5 --enable-eap-mschapv2 --enable-eap-tls --enable-eap-ttls --enable-eap-peap  --enable-eap-tnc --enable-eap-dynamic --enable-eap-radius --enable-xauth-eap  --enable-xauth-pam  --enable-dhcp  --enable-openssl  --enable-addrblock --enable-unity  --enable-certexpire --enable-radattr --disable-gmp $Add_Parameter
    make -j"$(nproc)" && make install
    [ ! -f /usr/sbin/ipsec ] && die "Install failure,check dependencies!"
    cd ..
    rm -r strongswan-*
    print_info "Install ok"
}

#add a user 增加一个初始用户
function add_a_user(){
    Default_Ask "Your VPS TYPE is openvz?" "${openvz}" "openvz"
#get username,4 figures default
    Default_Ask "Input your username:" "$(get_random_word 4)" "username"
#get password,6 figures default
    Default_Ask "Input your password:" "$(get_random_word 6)" "password"
#get psk,3 figures default
    Default_Ask "Input your PSK:" "$(get_random_word 3)" "psk"
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
    print_info "CA OK"
}

function get_p12_ca(){
#get password
    Default_Ask "Input your password for p12 file:" "$(get_random_word 6)" "password"
#client cert liftime
    Default_Ask "Input your client-cert liftime(day):" "7777" "Client_Lifetime"
    cd /etc/ipsec.d/
    userID=$(get_random_word 4)
    while [ -f private/ClientKey-${userID}.pem ]; do
        userID=$(get_random_word 4)
    done
#CREATE A CLIENT CERTIFICATE
    ipsec pki --gen --type rsa --size 2048 --outform pem > private/ClientKey-${userID}.pem
    chmod 600 private/ClientKey-${userID}.pem
    ipsec pki --pub --in private/ClientKey-${userID}.pem --type rsa | ipsec pki --issue --lifetime ${Client_Lifetime} --cacert cacerts/strongswanCert.pem --cakey private/strongswanKey.pem --dn "C=CN, O=strongSwan, CN=Client ${userID}" --san "Client ${userID}" --outform pem > certs/ClientCert-${userID}.pem
#EXPORT CLIENT CERTIFICATE AS A PKCS#12 FILE
    openssl pkcs12 -export -inkey /etc/ipsec.d/private/ClientKey-${userID}.pem -in /etc/ipsec.d/certs/ClientCert-${userID}.pem -name "Client-${userID}" -certfile /etc/ipsec.d/cacerts/strongswanCert.pem -caname "strongSwan Root CA" -out Client-${userID}.p12 -passout pass:$password
#MV strongswanKey,PKCS#12 TO ROOT
    mv Client-${userID}.p12 /root
    print_info "P12 OK"
}

#set
function set_IPSecIKEv1v2_conf(){
#ipsec $fqdnname
    cat >/etc/ipsec.conf<<EOF
config setup
    uniqueids=never
    strictcrlpolicy=no
#    charondebug="cfg 2, dmn 2, ike 2, net 2"

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
#            time_format = %b %e %T
#            default = 1
#            append = no
#            flush_line = yes
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
#iptables and sysctl
    cat >/etc/ipsec.d/start-ipsec-sysctl.sh<<'EOF'
#! /bin/bash

# turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway and ip pool
gw_IPsec=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
IP_pool_IPSec=`sed -n 's/^[ /t]*rightsourceip.*=[ /t]*//p' /etc/ipsec.conf`

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
iptables -A INPUT -p esp -m comment --comment "$gw_IPsec (IPSecIKEv1v2_5)" -j ACCEPT
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$gw_IPsec (IPSecIKEv1v2_6)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_IPsec (IPSecIKEv1v2_6)" -j TCPMSS --clamp-mss-to-pmtu
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
    cat >/etc/init.d/ipsec<<'EOF'
#! /bin/sh
### BEGIN INIT INFO
# Provides:          ipsec
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Strongswan IPsec services
### END INIT INFO

# Author: Rene Mayrhofer <rene@mayrhofer.eu.org>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="strongswan IPsec services"
NAME=ipsec
STARTER=/usr/sbin/$NAME
PIDFILE=/var/run/charon.pid
CHARON=/usr/lib/ipsec/charon
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$STARTER" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

# Create lock dir
mkdir -p /var/lock/subsys

#
# Function that starts the daemon/service
#
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started

	# test if charon is currently running
	if [ -e $CHARON ]; then
	  start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $CHARON --test > /dev/null \
		|| return 1
	fi

	$STARTER start || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
	# give the proper signal to stop
	$STARTER stop || return 2

	RETVAL=0
	# but kill if that didn't work
	if [ -e $PIDFILE ]; then
		start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
		RETVAL="$?"
		[ "$RETVAL" = 2 ] && return 2
	fi

	# Wait for children to finish too if this is a daemon that forks
	# and if the daemon is only ever run from this initscript.
	# If the above conditions are not satisfied then add some other code
	# that waits for the process to drop all resources that could be
	# needed by services started subsequently.  A last resort is to
	# sleep for some time.
	if [ -e $CHARON ]; then
	  start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $CHARON
	  [ "$?" = 2 ] && return 2
	fi

	# strongswan is known to leave PID files behind when something goes wrong, cleanup here
	rm -f $PIDFILE
	# and just to make sure they are really really dead at this point...
	killall -9 $CHARON 2>/dev/null

	return "$RETVAL"
}

do_reload() {
	$STARTER reload
	return 0
}

case "$1" in
  start)
	[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	do_start
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  status)
	$STARTER status || exit $?
	;;
  reload|force-reload)
	log_daemon_msg "Reloading $DESC" "$NAME"
	do_reload
	log_end_msg $?
	;;
  restart)
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
	exit 3
	;;
esac

:
EOF
    chmod 755 /etc/init.d/ipsec
    sed -i '/test if charon is currently running/a\. /etc/ipsec.d/start-ipsec-sysctl.sh' /etc/init.d/ipsec
    sed -i '/give the proper signal to stop/a\. /etc/ipsec.d/stop-ipsec-sysctl.sh' /etc/init.d/ipsec
#boot from the start 开机自启
    insserv -s  > /dev/null 2>&1
    [ $? -eq 0 ] || sudo ln -s /usr/lib/insserv/insserv /sbin/insserv
    sudo insserv ipsec > /dev/null 2>&1
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

clear
echo "#############################################################"
echo "# Install  IPSecIKEv1v2 VPN server for Debian 7+"
echo "#############################################################"
echo ""

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
