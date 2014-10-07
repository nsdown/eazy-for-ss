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

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!!"
    exit 1
fi
    
#Set shadowsocks-libev config password
    echo "Please input password for shadowsocks-libev:"
    read -p "(Default password: 123456):" shadowsockspwd
    if [ "$shadowsockspwd" = "" ]; then
        shadowsockspwd="123456"
    fi
    echo "password:$shadowsockspwd"
    echo "####################################"
# Set shadowsocks-libev config servers port
    echo "Please input servers port for shadowsocks-libev:"
    read -p "(Default port: 443):" shadowsockspt
    if [ "$shadowsockspt" = "" ]; then
        shadowsockspt="443"
    fi
    echo "port:$shadowsockspt"
    echo "####################################"
# Set shadowsocks-libev config Encryption Method
    echo "Please input Encryption Method for shadowsocks-libev:"
    read -p "(Default port: rc4-md5):" shadowsocksem
    if [ "$shadowsocksem" = "" ]; then
        shadowsocksem="rc4-md5"
    fi
    echo "port:$shadowsocksem"
    echo "####################################"
	
# install
apt-get update -y
apt-get upgrade -y
apt-get install build-essential autoconf libtool libssl-dev gcc vim -y
apt-get install git -y
git clone https://github.com/madeye/shadowsocks-libev.git
cd shadowsocks-libev 
./configure 
make && make install

#IP
IP=$(wget -qO- ipv4.icanhazip.com)

# keepalive and no log
nohup /usr/local/bin/ss-server >/dev/null 2>&1 &
nohup /usr/local/bin/ss-server -s :: -p ${shadowsockspt} -k ${shadowsockspwd} -m ${shadowsocksem} &
sed -i "/By default this script does nothing./a\nohup /usr/local/bin/ss-server -s :: -p ${shadowsockspt} -k ${shadowsockspwd} -m ${shadowsocksem} &" /etc/rc.local

#set iptables only for debian
iptables -I  INPUT -p tcp -m tcp --dport ${shadowsockspt} -j ACCEPT
iptables -I  INPUT -p udp -m udp --dport ${shadowsockspt} -j ACCEPT
sed -i "/By default this script does nothing./a\iptables -I  INPUT -p tcp -m tcp --dport ${shadowsockspt} -j ACCEPT" /etc/rc.local
sed -i "/By default this script does nothing./a\iptables -I  INPUT -p udp -m udp --dport ${shadowsockspt} -j ACCEPT" /etc/rc.local

# end
    clear
    echo ""
    echo "Congratulations, shadowsocks-libev install completed!"
    echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
    echo -e "Your Server Port: \033[41;37m ${shadowsockspt} \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Encryption Method: \033[41;37m ${shadowsocksem} \033[0m"
    echo ""
    echo "Enjoy it!"
    echo ""
exit
