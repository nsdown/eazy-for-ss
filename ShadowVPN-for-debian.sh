#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  Debian/Ubuntu (32bit/64bit)
#   Description:  Install ShadowVPN Single user for Debian/Ubuntu
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install ShadowVPN for Debian/Ubuntu (32bit/64bit)"
echo "#############################################################"
echo ""

# install ShadowVPN
function install_ShadowVPN_libsodium(){
    root
    debian
    get_config
    pre_install
    ShadowVPN_install
    config_ShadowVPN
    stop_ShadowVPN
    start_ShadowVPN
    show_ShadowVPN    
}

#change config
function changeconfig_ShadowVPN_libsodium(){
    get_config
    config_ShadowVPN
    stop_ShadowVPN
    start_ShadowVPN
    show_ShadowVPN
}

#update ShadowVPN
function update_ShadowVPN_libsodium(){
	stop_ShadowVPN
	cp -rpf /etc/shadowvpn/server.conf /opt/server.conf
	ShadowVPN_update
	rm -f /etc/shadowvpn/server.conf
	mv /opt/server.conf /etc/shadowvpn/server.conf
	rm -f /opt/server.conf
	start_ShadowVPN
}

#unistall ShadowVPN
function uninstall_ShadowVPN_libsodium(){
    printf "Are you sure uninstall ShadowVPN? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        #stop ss
        stop_ShadowVPN
        # restore /etc/rc.local
        if [[ -s /opt/rc.local_bak ]]; then
            rm -f /etc/rc.local
            mv /opt/rc.local_bak /etc/rc.local
        fi
        # delete config file
        rm -rf /etc/shadowvpn
        # delete ShadowVPN
        rm -f /usr/local/bin/shadowvpn
        echo "ShadowVPN uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Check if user is root
function root(){
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!!"
    exit 1
fi
}

# debian only
function debian(){
if [[ ! -e /etc/debian_version ]]; then
	echo "Looks like you aren't running this installer on a Debian-based system"
	exit 1
fi
}

# pre_install
function pre_install(){
   cd /root/
   apt-get update -y
   apt-get upgrade -y
   apt-get install -y build-essential autoconf libtool libssl-dev gcc 
   apt-get install -y vim sudo git gawk debhelper wget curl
   clear
}

function get_config(){

# Get ShadowVPN config password
    echo "Please input password for ShadowVPN:"
    read -p "(Default password: 123456):" ShadowVPNpwd
    if [ "$ShadowVPNpwd" = "" ]; then
        ShadowVPNpwd="123456"
    fi
    echo "password:$ShadowVPNpwd"
    echo "####################################"
# Get ShadowVPN config servers port
    echo "Please input server port for ShadowVPN:"
    read -p "(Default port: 443):" ShadowVPNpt
    if [ "$ShadowVPNpt" = "" ]; then
        ShadowVPNpt="443"
    fi
    echo "port:$ShadowVPNpt"
    echo "####################################"
}

function ShadowVPN_install(){
# install check
if [ -s /usr/local/bin/shadowvpn ];then
        echo "ShadowVPN has been installed!"
        echo "change config!"
else
   ShadowVPN_update
fi
}

function ShadowVPN_update(){
   cd /root/
   git clone https://github.com/clowwindy/ShadowVPN.git
   cd ShadowVPN
   git submodule update --init
   ./autogen.sh
   ./configure --enable-static --sysconfdir=/etc
   make && sudo make install
   cd ..
   rm -rf ShadowVPN
}

function config_ShadowVPN(){
# set config 
cat > /etc/shadowvpn/server.conf<<-EOF
# ShadowVPN config example

# notice: do not put space before or after "="

# server listen address
server=0.0.0.0

# server listen port
port=${ShadowVPNpt}

# password to use
# you can generate one by:
# dd if=/dev/urandom bs=64 count=1 | md5sum
password=${ShadowVPNpwd}

# server or client
mode=server

# max source ports
# must be the SAME with client or won't work properly
concurrency=1

# the MTU of VPN device
# 1492(Ethernet) - 20(IPv4, or 40 for IPv6) - 8(UDP) - 24(ShadowVPN)
mtu=1440

# tunnel device name
intf=tun0

# the script to run after VPN is created
# use this script to set up routes, NAT, etc
# configuration in this file will be set as environment variables
up=/etc/shadowvpn/server_up.sh

# the script to run before stopping VPN
# use this script to restore routes, NAT, etc
# configuration in this file will be set as environment variables
down=/etc/shadowvpn/server_down.sh

# PID file path
pidfile=/var/run/shadowvpn.pid

# log file path
logfile=/var/log/shadowvpn.log
EOF

}

function stop_ShadowVPN(){
#stop all
sv_pid=`pidof shadowvpn`
if [ ! -z "$sv_pid" ]; then
        for pid in $sv_pid
        do
            kill -9 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
            echo "ShadowVPN process[$pid] has been killed"
            fi
        done
fi
}

function start_ShadowVPN(){
#start
/usr/local/bin/shadowvpn -c /etc/shadowvpn/server.conf -s start
#Add run on system start up
cat /etc/rc.local | grep 'shadowvpn -c /etc/shadowvpn/server.conf' > /dev/null 2>&1
if [ $? -ne 0 ]; then
       cp -rpf /etc/rc.local /opt/rc.local_bak
       sed -i "/By default this script does nothing./a\/usr/local/bin/shadowvpn -c /etc/shadowvpn/server.conf -s start" /etc/rc.local
       fi

}


function show_ShadowVPN(){
# Get IP
    IP=$(wget -qO- ipv4.icanhazip.com)
	if [ -z $IP ]; then
        IP=`curl -s ifconfig.me/ip`
        fi
# Run success or not
ps -ef | grep -v grep | grep -v ps | grep -i '/usr/local/bin/shadowvpn' > /dev/null 2>&1
if [ $? -eq 0 ]; then 
    clear
    echo ""
    echo "Congratulations!ShadowVPN start success!"
    echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
    echo -e "Your Server Port: \033[41;37m ${ShadowVPNpt} \033[0m"
    echo -e "Your Password: \033[41;37m ${ShadowVPNpwd} \033[0m"
    echo ""
    echo "Enjoy it!"
    echo ""
    exit
else
    echo "ShadowVPN start failure!"
	exit
fi
}
# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_ShadowVPN_libsodium
    ;;
changeconfig)
    changeconfig_ShadowVPN_libsodium
    ;;
update)
    update_ShadowVPN_libsodium
    ;;
uninstall)
    uninstall_ShadowVPN_libsodium
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|changeconfig|update|uninstall}"
    ;;
esac
