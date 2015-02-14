#! /bin/bash

#===============================================================================================
#   System Required:  Debian/Ubuntu (32bit/64bit)
#   Description:  Install Shadowsocks(libev) for Debian/Ubuntu
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install Shadowsocks(libev) for Debian/Ubuntu (32bit/64bit)"
echo "#############################################################"
echo ""

# install Shadowsocks-libev
function install_shadowsocks_libev(){
    root
    debian
    get_config
    pre_install
    config_shadowsocks
    shadowsocks_update
    show_shadowsocks    
}

#change config
function changeconfig_shadowsocks_libev(){
    get_config
    config_shadowsocks
    stop_shadowsocks
    sudo /etc/init.d/shadowsocks-libev start
    show_shadowsocks
}

#update shadowsocks-libev
function update_shadowsocks_libev(){
	stop_shadowsocks
	shadowsocks_update
	
}

#uninstall shadowsocks-libev
function uninstall_shadowsocks_libev(){
    printf "Are you sure uninstall Shadowsocks-libev? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        #stop ss
        stop_shadowsocks
        #remove
        apt-get remove -y -purge shadowsocks-libev
        echo "Shadowsocks-libev uninstall success!"
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

#tcp choice
sysctl net.ipv4.tcp_available_congestion_control | grep 'hybla' > /dev/null 2>&1
if [ $? -eq 0 ]; then 
tcp_congestion_ss="hybla"
else
tcp_congestion_ss="cubic"
fi

cat > /etc/sysctl.d/local.conf<<EOF

fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = $tcp_congestion_ss
EOF

sysctl -p /etc/sysctl.d/local.conf
   
# Debian version 6.x.x
if grep ^6. /etc/debian_version > /dev/null
then
	echo "deb http://shadowsocks.org/debian squeeze main" >> /etc/apt/sources.list
fi

# Debian version 7.x.x
if grep ^7. /etc/debian_version > /dev/null
then
	echo "deb http://shadowsocks.org/debian wheezy main" >> /etc/apt/sources.list
fi

#add gpg
wget -O- http://shadowsocks.org/debian/1D27208A.gpg | sudo apt-key add -	
	   
clear
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

echo linux-image-`uname -r` hold | sudo dpkg --set-selections

sudo apt-get update

apt-get upgrade -y
   
sudo apt-get install shadowsocks-libev -y --force-yes

N_MAXFD=`cat /etc/default/shadowsocks-libev | grep '^MAXFD' | sed 's/MAXFD=//g'`
sed -i "s@MAXFD=$N_MAXFD@MAXFD=51200@" /etc/default/shadowsocks-libev

sudo /etc/init.d/shadowsocks-libev restart

}

function config_shadowsocks(){
# set config 
 if [ ! -d /etc/shadowsocks-libev ];then
    mkdir /etc/shadowsocks-libev
 fi
#:: not wort only 0.0.0.0
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



function show_shadowsocks(){
# Get IP
    IP=$(wget -qO- ipv4.icanhazip.com)
	if [ $? -ne 0 -o -z $IP ]; then
        IP=`wget -qO- liyangyijie.sinaapp.com/ip/`
        fi
# Run success or not
ps -ef | grep -v grep | grep -v ps | grep -i 'ss-server' > /dev/null 2>&1
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
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks_libev
    ;;
changeconfig)
    changeconfig_shadowsocks_libev
    ;;
update)
    update_shadowsocks_libev
    ;;
uninstall)
    uninstall_shadowsocks_libev
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|changeconfig|update|uninstall}"
    ;;
esac
