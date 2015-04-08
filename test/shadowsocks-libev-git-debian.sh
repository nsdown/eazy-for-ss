#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
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
        shadowsocks_install
        config_shadowsocks
	stop_shadowsocks
	start_shadowsocks
	show_shadowsocks    
}

#change config
function changeconfig_shadowsocks_libev(){
        get_config
	config_shadowsocks
	stop_shadowsocks
	start_shadowsocks
	show_shadowsocks
}

#update shadowsocks-libev
function update_shadowsocks_libev(){
	stop_shadowsocks
	shadowsocks_update
	start_shadowsocks
}

#unistall shadowsocks-libev
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
        # restore /etc/rc.local
        if [[ -s /opt/rc.local_bak_ss_l ]]; then
            rm -f /opt/rc.local_bak_ss_l
            sed -i "s@nohup /usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json -u > /dev/null 2>&1 &@@" /etc/rc.local
			sed -i "s@ulimit -n 51200@@" /etc/rc.local
        fi
        # delete config file
        rm -rf /etc/shadowsocks-libev
        # delete shadowsocks
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/share/man/man8/shadowsocks-libev.8
        rm -f /usr/local/share/man/man8/shadowsocks.8
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
   cd ~
   echo linux-image-`uname -r` hold | sudo dpkg --set-selections
   apt-get update 
   apt-get upgrade -y
   ulimit -n 51200
   apt-get install -y build-essential autoconf libtool libssl-dev gcc make 
   apt-get install -y vim sudo git gawk debhelper curl
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
    echo "port:$shadowsocksem"
    echo "####################################"
}

function shadowsocks_install(){
# install check
if [ -s /usr/local/bin/ss-server ];then
        echo "shadowsocks-libev has been installed!"
        echo "change config!"
else
   shadowsocks_update
fi
}

function shadowsocks_update(){
   cd ~
   git clone https://github.com/madeye/shadowsocks-libev.git
   cd shadowsocks-libev 
   ./configure 
   make && make install
   cd ..
   rm -rf shadowsocks-libev
}

function config_shadowsocks(){
# set config 
 if [ ! -d /etc/shadowsocks-libev ];then
        mkdir /etc/shadowsocks-libev
 fi
        cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":"::",
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

function start_shadowsocks(){
#start
nohup /usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json -u > /dev/null 2>&1 &
#Add run on system start up
cat /etc/rc.local | grep 'ss-server -c /etc/shadowsocks-libev/config.json -u' > /dev/null 2>&1
if [ $? -ne 0 ]; then
       cp -rpf /etc/rc.local /opt/rc.local_bak_ss_l
       sed -i "/By default this script does nothing./a\nohup /usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json -u > /dev/null 2>&1 &" /etc/rc.local
       sed -i "/By default this script does nothing./a\ulimit -n 51200" /etc/rc.local
fi

}


function show_shadowsocks(){
# Get IP
    IP=$(wget -qO- ipv4.icanhazip.com)
	if [ -z $IP ]; then
        IP=`curl -s liyangyijie.sinaapp.com/ip/`
        fi
# Run success or not
ps -ef | grep -v grep | grep -v ps | grep -i '/usr/local/bin/ss-server' > /dev/null 2>&1
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
