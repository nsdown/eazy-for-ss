#! /bin/bash

#===============================================================================================
#   System Required:  Debian/Ubuntu (32bit/64bit)
#   Description:  Install Shadowsocks(libev) for Debian
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install Shadowsocks(libev) for Debian/Ubuntu (32bit/64bit)"
echo "#############################################################"
echo ""

# install Shadowsocks-libev
function install_shadowsocks_libev(){
check_ss
get_config
pre_install
shadowsocks_update
config_shadowsocks
stop_start_shadowsocks
show_shadowsocks    
}

#change config
function changeconfig_shadowsocks_libev(){
get_config
config_shadowsocks
stop_start_shadowsocks
show_shadowsocks
}

#update shadowsocks-libev
function update_shadowsocks_libev(){
stop_shadowsocks
shadowsocks_update	
}

#uninstall shadowsocks-libev
function uninstall_shadowsocks_libev(){
printf "Are you sure uninstall Shadowsocks-libev? (y/n) \n"
read -p "(Default: n):" answer
if [ "$answer" = "y" ]; then
#stop ss
    stop_shadowsocks
#remove
    rm -f /etc/sysctl.d/local_ss.conf
    DEBIAN_FRONTEND=noninteractive apt-get remove -y -q --purge shadowsocks-libev
    echo "Shadowsocks-libev uninstall success!"
else
    echo "uninstall cancelled, Nothing to do"
fi
}

# Check if user is root and debian only
function check_ss(){
if [ $(id -u) != "0" ]; then
echo "You must be root to run this script."
exit 1
fi
if [ ! -f /etc/debian_version ]; then
echo "Looks like you aren't running this installer on a Debian-based system."
exit 1
fi
}

# pre_install
function pre_install(){
#base-tool
apt-get update
echo linux-image-`uname -r` hold | sudo dpkg --set-selections
apt-get upgrade -y
echo linux-image-`uname -r` install | sudo dpkg --set-selections
apt-get install -y -qq sudo nano sed vim gawk curl dnsutils apt-transport-https net-tools
#tcp choice
#load hybla
/sbin/modprobe tcp_hybla > /dev/null 2>&1
sysctl net.ipv4.tcp_available_congestion_control | grep 'hybla' > /dev/null 2>&1
if [ $? -eq 0 ]; then 
tcp_congestion_ss="hybla"
else
tcp_congestion_ss="cubic"
fi
#sysctl file
cat > /etc/sysctl.d/local_ss.conf<<EOF
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

net.ipv4.tcp_congestion_control = $tcp_congestion_ss
EOF
#sysctl set
sysctl -p /etc/sysctl.d/local_ss.conf
#+source   
sed 's/^[ \t]*//' /etc/apt/sources.list|grep -v '^#'|grep 'shadowsocks' > /dev/null 2>&1
if [ $? -ne 0 ]; then
    expr $(cat /etc/debian_version|cut -d. -f1) + 0 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        D_V=`expr $(cat /etc/debian_version|cut -d. -f1)`
        if [ $D_V -lt 7 ]; then        
            echo "deb http://shadowsocks.org/debian squeeze main" >> /etc/apt/sources.list
        else
            echo "deb http://shadowsocks.org/debian wheezy main" >> /etc/apt/sources.list
        fi
    else
        echo "deb http://shadowsocks.org/debian wheezy main" >> /etc/apt/sources.list
    fi
#add gpg
    wget -O- http://shadowsocks.org/debian/1D27208A.gpg | sudo apt-key add -
fi
clear
}

function Check_Tcp_Port(){
All_Listen_Tcp_Port=`netstat -napt|grep -i 'listen'|awk {'print $4'}|sed 's/.*:\(.*\)/\1/'|sort|uniq`
Port=""
for Port in $All_Listen_Tcp_Port
do
    if [ "$1" = "$Port" ]; then
        return 1
    fi
done
}

function get_config(){
# Get shadowsocks-libev config password
echo "Please input password for shadowsocks-libev:"
read -p "(Default password: 123456):" shadowsockspwd
if [ "$shadowsockspwd" = "" ]; then
     shadowsockspwd="123456"
fi
echo "password:$shadowsockspwd"
echo "####################################"
# Get shadowsocks-libev config servers port
echo "Please input server port for shadowsocks-libev:"
read -p "(Default port: 443):" shadowsockspt
if [ "$shadowsockspt" = "" ]; then
    shadowsockspt="443"
fi
echo "port:$shadowsockspt"
while !(Check_Tcp_Port "$shadowsockspt"); do
echo "The port is in use , please choose a different port!"
echo "Please input server port for shadowsocks-libev:"
read -p "(Default port: 443):" shadowsockspt
if [ "$shadowsockspt" = "" ]; then
    shadowsockspt="443"
fi
echo "port:$shadowsockspt"
done
echo "####################################"
# Get shadowsocks-libev config Encryption Method
echo "Please input Encryption Method for shadowsocks-libev:"
read -p "(Default port: rc4-md5):" shadowsocksem
if [ "$shadowsocksem" = "" ]; then
    shadowsocksem="rc4-md5"
fi
echo "encryption method:$shadowsocksem"
echo "####################################"
#any key go on
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
echo "press any key to start...or Press Ctrl+C to cancel"
echo ""
ss_char=`get_char`
}

function shadowsocks_update(){
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install shadowsocks-libev -y
sed -i 's|\(MAXFD=\).*|\151200|' /etc/default/shadowsocks-libev
}

function config_shadowsocks(){
# set config 
[ ! -d /etc/shadowsocks-libev ] && mkdir /etc/shadowsocks-libev
#only 0.0.0.0
cat > /etc/shadowsocks-libev/config.json<<EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsockspt},
    "password":"${shadowsockspwd}",
    "timeout":600,
    "method":"${shadowsocksem}"
}
EOF
}

function stop_shadowsocks(){
/etc/init.d/shadowsocks-libev stop
#stop all
ss_pid=`pidof ss-server`
if [ ! -z "$ss_pid" ]; then
    for pid in $ss_pid
    do
        kill -9 $pid > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Shadowsocks-libev process[$pid] has been killed"
        fi
    done
fi
}

function stop_start_shadowsocks(){
stop_shadowsocks
/etc/init.d/shadowsocks-libev start
}

function show_shadowsocks(){
# Get IP
IP=$(wget -qO- ipv4.icanhazip.com)
if [ $? -ne 0 -o -z $IP ]; then
    IP=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
fi
# Run success or not
ps -ef|grep -v grep|grep -v ps|grep -i 'ss-server' > /dev/null 2>&1
if [ $? -eq 0 ]; then 
    clear
    echo ""
    echo "Congratulations!Shadowsocks-libev start success!"
    echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
    echo -e "Your Server Port: \033[41;37m ${shadowsockspt} \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Encryption Method: \033[41;37m ${shadowsocksem} \033[0m"
    echo ""
    echo "Enjoy it!"
    echo ""
    exit
else
    echo "Shadowsocks-libev start failure!"
    exit
fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks_libev
    ;;
changeconfig|ch)
    changeconfig_shadowsocks_libev
    ;;
update|up)
    update_shadowsocks_libev
    ;;
uninstall|un)
    uninstall_shadowsocks_libev
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|changeconfig|update|uninstall}"
    ;;
esac
