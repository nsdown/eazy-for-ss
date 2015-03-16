#! /bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install OpenConnect VPN server for Debian
#   Ocservauto For Debian Copyright (C) liyangyijie released under GNU GPLv2
#   Ocservauto For Debian Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install  OpenConnect VPN server for Debian 7+"
echo "#############################################################"
echo ""

#证书登录实验 路由表加入
#install 安装主体
function install_OpenConnect_VPN_server(){
    
#check system , get IP and port ,del test sources 检测系统 获取本机公网ip、默认验证端口 去除测试源
    check_Required
	
#custom-configuration or not 自定义安装与否
    print_info "Do you want to install ocserv with Custom Configuration?(y/n)"
    read -p "(Default :n):" Custom_config_ocserv
    if [ "$Custom_config_ocserv" = "y" ]; then
    print_info "Install ocserv with custom configuration!!!"
    print_warn "You have to know what you are modifying , it is recommended that you use the default settings!"
    get_Custom_configuration
    else
    print_info "Automatic installation."
    self_signed_ca="y"
    ca_login="n"    
    fi

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
    ocserv_char=`get_char`

#install dependencies 安装依赖文件
    pre_install
	
#install ocserv 编译安装软件	
    tar_ocserv_install

#make self-signd server-ca 制作服务器自签名证书	
    if [ "$self_signed_ca" = "y" ]; then
    make_ocserv_ca
    fi

#make a client cert 制作证书登录	
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
    ca_login_ocserv	
    fi

#configuration 设定软件相关选项	
    set_ocserv_conf

#stop all 关闭所有正在运行的ocserv软件
    stop_ocserv

#no certificate,no start 没有服务器证书不启动	
    if [ "$self_signed_ca" = "y" ]; then	
    start_ocserv
    fi

#show result 显示结果	
    show_ocserv    
}

function get_new_userca {
    if [ ! -f /usr/sbin/ocserv ]
    then
        die "Ocserv NOT Found !!!"
    fi
    if [ ! -f /etc/ocserv/CAforOC/ca-cert.pem ] || [ ! -f /etc/ocserv/CAforOC/ca-key.pem ]; then
        die "CA or KEY NOT Found !!!Only Support Self-signed CA!!!"
    fi
    ca_login="y"
    self_signed_ca="y"
    add_a_user
    ca_login_ocserv
    print_info "You can get user.p12 from /root"
    echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
    print_warn " You have to import the certificate to your device at first."
}

function revoke_userca {
    if [ ! -f /usr/sbin/ocserv ]
    then
        die "Ocserv NOT Found !!!"
    fi
    if [ ! -f /etc/ocserv/CAforOC/ca-cert.pem ] || [ ! -f /etc/ocserv/CAforOC/ca-key.pem ]; then
        die "CA or KEY NOT Found !!!Only Support Self-signed CA!!!"
    fi
#get info
    cd /etc/ocserv/CAforOC
    ls -F|grep /|grep user|cut -d '/' -f 1
    echo "Which user do you want to revoke?"
	read -p "Which: " -e -i user- revoke_ca
    if [ ! -f /etc/ocserv/CAforOC/$revoke_ca/$revoke_ca.p12 ]
    then
        die "$revoke_ca NOT Found !!!"
    fi
    echo "Okay,${revoke_ca} will be revoked."
	read -n1 -r -p "Press any key to continue...or Press Ctrl+C to cancel"
#revoke   
    cat ${revoke_ca}/${revoke_ca}-cert.pem >>revoked.pem
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --load-certificate revoked.pem --template crl.tmpl --outfile ../crl.pem
#show
    mv ${revoke_ca} revoke/
    /etc/init.d/ocserv restart
    print_info "${revoke_ca} was revoked."
    
}

function reinstall_ocserv {
    stop_ocserv
    rm -rf /etc/ocserv
    rm -rf /etc/dbus-1/system.d/org.infradead.ocserv.conf
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    install_OpenConnect_VPN_server
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
#only Debian 7+
    if grep ^6. /etc/debian_version > /dev/null
    then
        die "Your system is debian 6. Only for Debian 7+"
    fi
	
    if grep ^5. /etc/debian_version > /dev/null
    then
        die "Your system is debian 5. Only for Debian 7+"
    fi
    print_info "Debian version ok"
#check install 防止重复安装
    if [ -f /usr/sbin/ocserv ]
    then
        die "Ocserv has been installed!!!"
    fi
    print_info "Not installed ok"
#sources check,del test sources 去掉测试源 
    cat /etc/apt/sources.list | grep 'deb ftp://ftp.debian.org/debian/ jessie main' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        oc_jessie=n
     else
        sed -i '/jessie/d' /etc/apt/sources.list
    fi
    print_info "Sources ok"
#get IPv4 info,install base-tools 
    print_info "Getting ip and base-tools from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed insserv dnsutils
    ocserv_hostname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $ocserv_hostname ]; then
        ocserv_hostname=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
    fi
    print_info "Get ip and base-tools ok"
#get default port 从网络配置中获取默认使用端口
    print_info "Getting default port from net......"
    ocserv_tcpport_Default=$(wget -qO- --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g')
    ocserv_udpport_Default=$(wget -qO- --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g')
    print_info "Get default port ok"
    clear
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

function get_Custom_configuration(){
    echo "####################################"
#whether to make a Self-signed CA 是否需要制作自签名证书
    print_info "Do you need make a Self-signed CA for your server?(y/n)"
    read -p "(Default :y):" self_signed_ca
    if [ "$self_signed_ca" = "n" ]; then
        print_warn "You have to put your CA and Key to /etc/ocserv !!!"
        print_warn "You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        echo "####################################"
        print_info "Input your own domain for ocserv:"
        read -p "(Default :$ocserv_hostname):" fqdnname
        if [ "$fqdnname" = "" ]; then
            fqdnname=$ocserv_hostname
        fi
            print_info "Your own domain for ocserv:$fqdnname"
    else 
        self_signed_ca="y"
        print_info "Make a Self-signed CA"
        echo "####################################"
#get CA's name
        print_info "Your CA's name:"
        read -p "(Default :ocvpn):" caname
        if [ "$caname" = "" ]; then
            caname="ocvpn"
        fi
        print_info "Your CA's name:$caname"
        echo "####################################"
#get Organization name
        print_info "Your Organization name:"
        read -p "(Default :ocvpn):" ogname
        if [ "$ogname" = "" ]; then
            ogname="ocvpn"
        fi
        print_info "Your Organization name:$ogname"
        echo "####################################"
#get Company name
        print_info "Your Company name:"
        read -p "(Default :ocvpn):" oname
        if [ "$oname" = "" ]; then
            oname="ocvpn"
        fi
        print_info "Your Company name:$oname"
        echo "####################################"
#get server's FQDN
        print_info "Your server's FQDN:"
        read -p "(Default :$ocserv_hostname):" fqdnname
        if [ "$fqdnname" = "" ]; then
            fqdnname=$ocserv_hostname
        fi
        print_info "Your server's FQDN:$fqdnname"
    fi
    echo "####################################"    
#set max router rulers 最大路由规则限制数目
    print_info "The maximum number of routing table rules?(Cisco Anyconnect client limit: 200)"
    read -p "(Default :200):" max_router
    if [ "$max_router" = "" ]; then
        max_router="200"
    fi
    print_info "$max_router"
    echo "####################################"
#which port to use, and upd-port + 1 选择验证端口，自定义后，udp端口数为+1
    print_info "Which port to use for verification?(Tcp-Port)"
    read -p "(Default :$ocserv_tcpport_Default):" which_port
    if [ "$which_port" != "" ]; then
        ocserv_tcpport_set=$which_port
        ocserv_udpport_set=`expr $which_port + 1`
        print_info "Your Tcp-Port Is:$ocserv_tcpport_set"
        print_info "Your Udp-Port Is:$ocserv_udpport_set"
    else
        print_info "Your Tcp-Port Is:$ocserv_tcpport_Default"
        print_info "Your Udp-Port Is:$ocserv_udpport_Default"
    fi
    echo "####################################"
#boot from the start 是否开机自起
    print_info "Boot from the start?(y/n)"
    read -p "(Default :y):" ocserv_boot_start
    if [ "$ocserv_boot_start" = "n" ]; then
        ocserv_boot_start="n"
        print_info "Do not start with the system!"	
    else
        ocserv_boot_start="y"
        print_info "Boot from the start!"
    fi
    echo "####################################"
#tcp-port only or not 是否仅仅使用tcp端口，即是否禁用udp
    print_info "Only use tcp-port or not?(y/n)"
    read -p "(Default :n):" only_tcp_port
    if [ "$only_tcp_port" = "y" ]; then
        only_tcp_port="y"
        print_info "Only tcp-port model!"	
    else
        only_tcp_port="n"
        print_info "Tcp-udp model!"
    fi
    echo "####################################"
#whether to use the certificate login
    print_info "Whether to use the certificate login?(y/n)"
    read -p "(Default :n):" ca_login 
    if [ "$ca_login" = "y" ]; then
#ca login support~
        print_warn "You can get user.p12 from /root !!!"
        print_warn "NEXT you have to input a password for you client cert! "
    else
        ca_login="n"
        print_info "The plain login."
    fi
    echo "####################################"
}

#add a user 增加一个初始用户
function add_a_user(){
#get username,4 figures default
    if [ "$ca_login" = "n" ]; then
        Default_username=$(get_random_word 4)
        print_info "Input your username for ocserv:"
        read -p "(Default :$Default_username):" username
        if [ "$username" = "" ]; then
            username="$Default_username"
        fi
        print_info "Your username:$username"
        echo "####################################"
#get password,6 figures default
        Default_password=$(get_random_word 6)
        print_info "Input your password for ocserv:"
        read -p "(Default :$Default_password):" password
        if [ "$password" = "" ]; then
            password="$Default_password"
        fi
        print_info "Your password:$password"
        echo "####################################"
    fi
#get password,if ca login,4 figures default
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
        Default_password=$(get_random_word 4)
        print_info "Input your password for your p12-cert file:"
        read -p "(Default :$Default_password):" password
        if [ "$password" = "" ]; then
            password="$Default_password"
        fi
        print_info "Your password:$password"
        echo "####################################"
    fi
}

#install dependencies 安装依赖文件
function pre_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | sudo dpkg --set-selections
    apt-get upgrade -y
#no update from test sources
    if [ ! -d /etc/apt/preferences.d ];then
        mkdir /etc/apt/preferences.d
    fi
    cat > /etc/apt/preferences.d/my_ocserv_preferences<<EOF
Package: *
Pin: release wheezy-backports
Pin-Priority: 90
Package: *
Pin: release jessie
Pin-Priority: 60
EOF
#sources check, Do not change the order 不要轻易改变升级顺序
    cat /etc/apt/sources.list | grep 'deb http://ftp.debian.org/debian wheezy-backports main' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
        oc_wheezy_backports=n
    fi
    apt-get update
    apt-get install -y libprotobuf-c0-dev 
    apt-get install -y libreadline6 libreadline5 libreadline6-dev libgmp3-dev m4 gcc pkg-config make gnutls-bin libtalloc-dev build-essential libwrap0-dev libpam0g-dev libdbus-1-dev libreadline-dev libnl-route-3-dev libpcl1-dev libopts25-dev autogen  libnl-nf-3-dev debhelper libseccomp-dev
    apt-get install -y -t wheezy-backports  libgnutls28-dev 
#sources check @ check Required 源检测在前面 增加压缩必须包
    echo "deb ftp://ftp.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
    apt-get update
    apt-get install -y -t jessie  liblz4-dev 
#if sources del 如果本来没有测试源便删除
    if [ "$oc_wheezy_backports" = "n" ]; then
        sed -i '/wheezy-backports/d' /etc/apt/sources.list
    fi
    if [ "$oc_jessie" = "n" ]; then
        sed -i '/jessie/d' /etc/apt/sources.list
    fi
#keep update
    rm -rf /etc/apt/preferences.d/my_ocserv_preferences
    apt-get update
    print_info "Dependencies  ok"
}
#install 编译安装
function tar_ocserv_install(){
    cd ~
#max router rulers
    if [ "$max_router" = "" ]; then
        max_router="200"
    fi
    oc_version=0.9.2
    wget ftp://ftp.infradead.org/pub/ocserv/ocserv-$oc_version.tar.xz
    tar xvf ocserv-$oc_version.tar.xz
    rm -rf ocserv-$oc_version.tar.xz
    cd ocserv-$oc_version
#have to use "" then $ work ,set router limit 0.10.0版本默认96条目
    D_MAX_ROUTER=`cat src/vpn.h | grep MAX_CONFIG_ENTRIES`
    sed -i "s/$D_MAX_ROUTER/#define MAX_CONFIG_ENTRIES $max_router/g" src/vpn.h
    ./configure --prefix=/usr --sysconfdir=/etc && make && make install
#check install 检测编译安装是否成功
    if [ ! -f /usr/sbin/ocserv ]
    then
        die "Ocserv install failure,check dependencies!"
    fi
#mv files
    mkdir -p /etc/ocserv/CAforOC/revoke
    cp doc/profile.xml /etc/ocserv
    cp doc/dbus/org.infradead.ocserv.conf /etc/dbus-1/system.d/
    sed -i "s@localhost@$ocserv_hostname@g" /etc/ocserv/profile.xml
    cd ..
    rm -rf ocserv-$oc_version
#get config file from net
    cd /etc/ocserv
    wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/ocserv.conf --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/start-ocserv-sysctl.sh  --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/stop-ocserv-sysctl.sh  --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/ocserv  --no-check-certificate
    chmod 755 ocserv
    mv ocserv /etc/init.d
    chmod +x start-ocserv-sysctl.sh
    chmod +x stop-ocserv-sysctl.sh
    print_info "Ocserv install ok"
}

function make_ocserv_ca(){
#all in one doc
    cd /etc/ocserv/CAforOC
#Self-signed CA set
#ca's name
    if [ "$caname" = "" ]; then
        caname="ocvpn"
    fi
#organization name
    if [ "$ogname" = "" ]; then
        ogname="ocvpn"
    fi
#company name
    if [ "$oname" = "" ]; then
        oname="ocvpn"
    fi
#server's FQDN
    if [ "$fqdnname" = "" ]; then
        fqdnname=$ocserv_hostname
    fi
#generating the CA 制作自签证书授权中心
    certtool --generate-privkey --outfile ca-key.pem
    cat << _EOF_ > ca.tmpl
cn = "$caname"
organization = "$ogname"
serial = 1
expiration_days = 7777
ca
signing_key
cert_signing_key
crl_signing_key
_EOF_
    certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
#generating a local server key-certificate pair 通过自签证书授权中心制作服务器的证书与秘钥
    certtool --generate-privkey --outfile server-key.pem
    cat << _EOF_ > server.tmpl
cn = "$fqdnname"
organization = "$oname"
serial = 2
expiration_days = 7777
signing_key
encryption_key
tls_www_server
_EOF_
    certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
    if [ ! -f server-cert.pem ] || [ ! -f server-key.pem ]; then	
        die "CA or KEY NOT Found , make failure!"
    fi
    cp server-cert.pem /etc/ocserv/ && cp server-key.pem /etc/ocserv/
    cp ca-cert.pem /etc/ocserv/
    print_info "Self-signed CA for ocserv ok"
}

function ca_login_ocserv(){
#make a client cert
    cd /etc/ocserv/CAforOC
    caname=`cat ca.tmpl | grep cn | cut -d '"' -f 2`
    name_user_ca=$(get_random_word 4)
    if [ -d user-${name_user_ca} ];then
        name_user_ca=$(get_random_word 8)${name_user_ca}
    fi
    cat << _EOF_ > user.tmpl
cn = "Client${name_user_ca}"
unit = "Client"
expiration_days = 7777
signing_key
tls_www_client
_EOF_
#user key
    certtool --generate-privkey --outfile user-key.pem
#user cert
    certtool --generate-certificate --load-privkey user-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template user.tmpl --outfile user-cert.pem
#p12
    openssl pkcs12 -export -inkey user-key.pem -in user-cert.pem -name "Client${name_user_ca}" -certfile ca-cert.pem -caname "$caname" -out user.p12 -passout pass:$password
#rename
    mkdir user-${name_user_ca}
    mv user-key.pem user-${name_user_ca}/user-${name_user_ca}-key.pem
    mv user-cert.pem user-${name_user_ca}/user-${name_user_ca}-cert.pem
    mv user.p12 user-${name_user_ca}/user-${name_user_ca}.p12
#cp to root
    cp user-${name_user_ca}/user-${name_user_ca}.p12 /root/
#make a empty revocation list
    if [ ! -f crl.tmpl ];then
    cat << EOF >crl.tmpl
crl_next_update = 7777 
crl_number = 1 
EOF
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --template crl.tmpl --outfile ../crl.pem
    fi
}

#set 设定相关参数
function set_ocserv_conf(){
#set port
    if [ "$ocserv_tcpport_set" != "" ]; then
        sed -i "s@tcp-port = $ocserv_tcpport_Default@tcp-port = $ocserv_tcpport_set@g" /etc/ocserv/ocserv.conf
    fi
    if [ "$ocserv_udpport_set" != "" ]; then
        sed -i "s@udp-port = $ocserv_udpport_Default@udp-port = $ocserv_udpport_set@g" /etc/ocserv/ocserv.conf
    fi
#default domain 
    sed -i "s@#default-domain = example.com@default-domain = $fqdnname@" /etc/ocserv/ocserv.conf 
#boot from the start 开机自启
    if [ "$ocserv_boot_start" = "y" ]; then
        sudo insserv ocserv
    fi
#add a user 增加一个初始用户
    if [ "$ca_login" = "n" ]; then
    (echo "$password"; sleep 1; echo "$password") | ocpasswd -c "/etc/ocserv/ocpasswd" $username
    fi
#set only tcp-port 仅仅使用tcp端口
    if [ "$only_tcp_port" = "y" ]; then
        sed -i 's@udp-port = @#udp-port = @g' /etc/ocserv/ocserv.conf
    fi
#set ca_login
    if [ "$ca_login" = "y" ]; then
        sed -i 's@auth = "plain@#auth = "plain@g' /etc/ocserv/ocserv.conf
        sed -i 's@#auth = "certificate"@auth = "certificate"@' /etc/ocserv/ocserv.conf
        sed -i 's@#ca-cert = /path/to/ca.pem@ca-cert = /etc/ocserv/ca-cert.pem@' /etc/ocserv/ocserv.conf
    fi
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
    sed -i 's@#crl = /path/to/crl.pem@crl = /etc/ocserv/crl.pem@' /etc/ocserv/ocserv.conf
    fi
#0.9.2 compression 0.9.2 增加压缩指令
    echo 'compression = true' >> /etc/ocserv/ocserv.conf
    print_info "Set ocserv ok"
}

function stop_ocserv(){
#stop all
    /etc/init.d/ocserv stop
    oc_pid=`pidof ocserv`
    if [ ! -z "$oc_pid" ]; then
        for pid in $oc_pid
        do
            kill -9 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "Ocserv process[$pid] has been killed"
            fi
        done
    fi
#clean iptables
    bash /etc/ocserv/stop-ocserv-sysctl.sh
}

function start_ocserv(){
    if [ ! -f /etc/ocserv/server-cert.pem ] || [ ! -f /etc/ocserv/server-key.pem ]; then
        print_warn "You have to put your CA and Key to /etc/ocserv !!!"
        print_warn "You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        die "CA or KEY NOT Found !!!"
    fi
#start
    /etc/init.d/ocserv start
}

function show_ocserv(){
    ocserv_port=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
    clear
    ps -ef | grep -v grep | grep -v ps | grep -i '/usr/sbin/ocserv' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ "$ca_login" = "y" ]; then
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
            print_warn " You have to import the certificate to your device at first."
            print_warn " You can stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn " Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info " Enjoy it!"
            echo ""
        else
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your username is \033[0m" "$username"
            echo -e "\033[41;37m Your password is \033[0m" "$password"
            print_warn " You can use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users. "
            print_warn " You can stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn " Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info " Enjoy it!"
            echo ""
        fi
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "n" ]; then    
        print_warn " 1,You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        print_warn " 2,You have to put your CA and Key to /etc/ocserv !!!"
        print_warn " 3,You have to start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn " 4,You can use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users."
        print_warn " 5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo -e "\033[41;37m Your username is \033[0m" "$username"
        echo -e "\033[41;37m Your password is \033[0m" "$password"
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "y" ]; then
        print_warn " 1,You have to change your Server Certificates and Server Key's name to server-cert.pem and server-key.pem !!!"
        print_warn " 2,You have to change your Certificate Authority Certificates' name to ca-cert.pem!!!"
        print_warn " 3,You have to put them to /etc/ocserv !!!"
        print_warn " 4,You have to start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn " 5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
    else
        print_warn "Ocserv start failure,ocserv is offline!"	
    fi
}

#Initialization step
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
getuserca)
    get_new_userca
    ;;
revokeuserca)
    revoke_userca
    ;;
reinstall)
    reinstall_ocserv
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|restart|getuserca|revokeuserca|reinstall}"
    ;;
esac
