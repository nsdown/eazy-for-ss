#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  Only Debian 7+!!! （x64 ok）
#   Description:  Install OpenConnect VPN server for Debian
#   SSLVPNauto-L v0.1 For Debian Copyright (C) liyangyijie@Gmail released under GNU GPLv2
#   SSLVPNauto-L v0.1 Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install  OpenConnect VPN server for Debian 7+"
echo "#############################################################"
echo ""

# install 
function install_OpenConnect_VPN_server(){
        root
	debian
	pre_install
	tar_ocserv_install
	make_ocserv_ca
	config_ocserv
	stop_ocserv
	start_ocserv
	show_ocserv    
}

# Check root
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
   echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
   echo linux-image-`uname -r` hold | sudo dpkg --set-selections
   apt-get update && sudo apt-get upgrade -y
   apt-get install -y vim sudo git gawk debhelper wget curl
   apt-get install -y -t wheezy-backports  libgnutls28-dev
   apt-get install -y libgmp3-dev m4 gcc pkg-config make gnutls-bin
   apt-get install -y build-essential libwrap0-dev libpam0g-dev libdbus-1-dev libreadline-dev libnl-route-3-dev libprotobuf-c0-dev libpcl1-dev libopts25-dev autogen libseccomp-dev libnl-nf-3-dev
   apt-get install -y libreadline6 libreadline5 libreadline6-dev
   clear
}
#get and install
function tar_ocserv_install(){
   cd ~
   wget ftp://ftp.infradead.org/pub/ocserv/ocserv-0.8.9.tar.xz
   tar xvf ocserv-0.8.9.tar.xz
   rm -rf ocserv-0.8.9.tar.xz
   cd ocserv-0.8.9
   sed -i 's/#define MAX_CONFIG_ENTRIES 64/#define MAX_CONFIG_ENTRIES 200/g' src/vpn.h
   ./configure --prefix=/usr --sysconfdir=/etc && make && make install
   mkdir /etc/ocserv
   cp doc/profile.xml /etc/ocserv
   cd ..
   rm -rf ocserv-0.8.9
  
}
function git_ocserv_install(){
   cd ~
   git clone git://git.infradead.org/ocserv.git
   cd ocserv
   git submodule update --init
   bash autogen.sh
   ./configure --prefix=/usr --sysconfdir=/etc && make && make install
   cd ..
   rm -rf ocserv
}
function make_ocserv_ca(){

#one file
cd /etc/ocserv
mkdir CAforOC
cd CAforOC

#get CA info
hostname=$(wget -qO- ipv4.icanhazip.com)
   if [ -z $hostname ]; then
      hostname=`curl -s liyangyijie.sinaapp.com/ip/`
   fi
   
clear

echo -e " \033[41;37m Now,We are making Your CA for ocserv! \033[0m"

# Get CA's name
    echo "Your CA's name:"
    read -p "(Default :ocvpn):" caname
    if [ "$caname" = "" ]; then
        caname="ocvpn"
    fi
    echo "Your CA's name:$caname"
    echo "####################################"
# Get Organization name
    echo "Your Organization name:"
    read -p "(Default :ocvpn):" ogname
    if [ "$ogname" = "" ]; then
        ogname="ocvpn"
    fi
    echo "Your Organization name:$ogname"
    echo "####################################"
# Get Company name
    echo "Your Company name:"
    read -p "(Default :ocvpn):" oname
    if [ "$oname" = "" ]; then
        oname="ocvpn"
    fi
    echo "Your Company name:$oname"
    echo "####################################"
# Get server's FQDN
    echo "Your server's FQDN:"
    read -p "(Default :$hostname):" fqdnname
    if [ "$fqdnname" = "" ]; then
        fqdnname=$hostname
    fi
    echo "Your server's FQDN:$fqdnname"
    echo "####################################"


#server-ca
certtool --generate-privkey --outfile ca-key.pem
cat << _EOF_ > ca.tmpl
cn = "$caname"
organization = "$ogname"
serial = 1
expiration_days = 9999
ca
signing_key
cert_signing_key
crl_signing_key
_EOF_

certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem

#server-key
certtool --generate-privkey --outfile server-key.pem
cat << _EOF_ > server.tmpl
cn = "$fqdnname"
organization = "$oname"
serial = 2
expiration_days = 9999
signing_key
encryption_key
tls_www_server
_EOF_

certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

cp server-cert.pem /etc/ocserv/ && cp server-key.pem /etc/ocserv/

}
function config_ocserv(){
cd /etc/ocserv
wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocserv.conf --no-check-certificate
wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocserv-sysctl.sh  --no-check-certificate
chmod +x ocserv-sysctl.sh
touch ocpasswd
chmod 600 ocpasswd

}
function stop_ocserv(){
#stop all
oc_pid=`pidof ocserv`
if [ ! -z "$oc_pid" ]; then
        for pid in $oc_pid
        do
            kill -9 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
            echo "ocserv process[$pid] has been killed"
            fi
        done
fi
}
function start_ocserv(){
#start
bash /etc/ocserv/ocserv-sysctl.sh
#Add run on system start up
cat /etc/rc.local | grep 'bash /etc/ocserv/ocserv-sysctl.sh' > /dev/null 2>&1
if [ $? -ne 0 ]; then
       cp -rpf /etc/rc.local /opt/rc.local_no_ocservbak
       sed -i "/By default this script does nothing./a\bash /etc/ocserv/ocserv-sysctl.sh" /etc/rc.local
       
fi
}
function show_ocserv(){
ocserv_port=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
clear
echo "Config finished."
echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
#echo -e "\033[41;37m Your username is \033[0m 8964" 
#echo -e "\033[41;37m Your password is \033[0m 8964"
#echo -e "\033[41;37m You can use 'sudo ocpasswd -c /etc/ocserv/ocpasswd username' to add users. \033[0m "
echo -e "\033[41;37m You have to use 'sudo ocpasswd -c /etc/ocserv/ocpasswd username' to add users. \033[0m "

}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_OpenConnect_VPN_server
    ;;
restart)
    stop_ocserv
    start_ocserv
    ;;
test)
    show_ocserv
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|restart}"
    ;;
esac
