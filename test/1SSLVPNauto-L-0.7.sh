#!/bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install OpenConnect VPN server for Debian
#   Ocservauto For Debian Copyright (C) liyangyijie released under GNU GPLv2
#   Ocservauto For Debian Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   Date: 2015-04-22 
#   Thanks For
#   http://www.infradead.org/ocserv/
#   https://www.stunnel.info  Travis Lee
#   http://luoqkk.com/ luoqkk
#   http://ttz.im/ tony
#   http://blog.ltns.info/ LTNS
#   https://github.com/clowwindy/ShadowVPN (server up/down script)
#   http://imkevin.me/post/80157872840/anyconnect-iphone
#   http://bitinn.net/11084/
#   http://zkxtom365.blogspot.jp/2015/02/centos-65ocservcisco-anyconnect.html
#   https://registry.hub.docker.com/u/tommylau/ocserv/dockerfile/
#   https://www.v2ex.com/t/158768
#   https://www.v2ex.com/t/165541
#   https://www.v2ex.com/t/172292
#   https://www.v2ex.com/t/170472
#   https://sskaje.me/2014/02/openconnect-ubuntu/
#   https://github.com/humiaozuzu/ocserv-build/tree/master/config
#===============================================================================================

###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################

#error and force-exit
function die(){
    echo -e "\033[33mERROR: $1 \033[0m" > /dev/null 1>&2
    exit 1
}

#info echo
function print_info(){
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

##### echo
function print_xxxx(){
    xXxX="#############################"
    echo
    echo "$xXxX$xXxX$xXxX$xXxX"
    echo
}

#warn echo
function print_warn(){
    echo -n -e '\033[41;37m'
    echo -n $1
    echo -e '\033[0m'
}

#get random word 获取$1位随机文本，剔除容易识别错误的字符例如0和O等等
function get_random_word(){
    D_Num_Random="8"
    Num_Random=${1:-$D_Num_Random}
    str=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c $Num_Random`
    echo $str
}

#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
#rewrite $ok
    if [  -f ${CONFIG_PATH_VARS} ]; then
        New_temp_default_var=`cat $CONFIG_PATH_VARS | grep "^$Temp_var_name=" | cut -d "'" -f 2`
        Temp_default_var=${New_temp_default_var:-$Temp_default_var}
    fi
#if yes or no 
    echo -e -n "\e[1;36m$Temp_question\e[0m""\033[31m(Default:$Temp_default_var)\033[0m"
    echo
    read Temp_var
    if [ "$Temp_default_var" = "y" ] || [ "$Temp_default_var" = "n" ]; then
        Temp_var=$(echo $Temp_var | sed 'y/YESNO0/yesnoo/')
        case $Temp_var in
            y|ye|yes)
                Temp_var=y
                ;;
            n|no)
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
    print_info "Your answer is : ${Temp_var}"
    echo
    print_xxxx
}

#Press any key to start 任意键开始
function press_any_key(){
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

#fast mode
function fast_Default_Ask(){
    if [ "$fast_install" = "y" ]; then
        print_info "In the fast mode, $3 will be loaded from $CONFIG_PATH_VARS"
    else
        Default_Ask "$1" "$2" "$3"
        [ -f ${CONFIG_PATH_VARS} ] && sed -i "/^${Temp_var_name}=/d" $CONFIG_PATH_VARS
        echo $Temp_cmd >> $CONFIG_PATH_VARS
    fi
}

###################################################################################################################
#core-function                                                                                                    #
###################################################################################################################

#install 安装主体
function install_OpenConnect_VPN_server(){
#check system , get IP and ocversion ,del test sources 检测系统 获取本机公网ip 最新版本 去除测试源
    check_Required

#custom-configuration or not 自定义安装与否
    fast_Default_Ask "Install ocserv with Custom Configuration?(y/n)" "n" "Custom_config_ocserv"
    if [ "$Custom_config_ocserv" = "y" ]; then
        clear
        print_xxxx
        print_info "Install ocserv with custom configuration."
        print_xxxx
        get_Custom_configuration
    else
        clear
        print_xxxx
        print_info "Automatic installation,choose the plain login."
        print_xxxx
        self_signed_ca="y"
        ca_login="n"    
    fi

#add a user 增加初始用户
    add_a_user

#press any key to start 任意键开始
    press_any_key

#install dependencies 安装依赖文件
    pre_install

#install ocserv 编译安装软件
    tar_ocserv_install

#make self-signd server-ca 制作服务器自签名证书
    if [ "$self_signed_ca" = "y" ]; then
    make_ocserv_ca
    fi

#make a client cert 若证书登录则制作客户端证书
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
    ca_login_ocserv
    fi

#configuration 设定软件相关选项
    set_ocserv_conf

#stop all 关闭所有正在运行的ocserv软件
    stop_ocserv

#no certificate,no start 没有服务器证书则不启动
    if [ "$self_signed_ca" = "y" ]; then
    start_ocserv
    fi

#show result 显示结果
    show_ocserv    
}

function check_Required(){
#check root
    [ $EUID -ne 0 ] && die 'Must be run by root user.'
    print_info "Root ok"
#debian-based only
    [ ! -f /etc/debian_version ] && die "Must be run on a Debian-based system."
    print_info "Debian-based ok"
#tun/tap
    [ ! -e /dev/net/tun ] && die "TUN/TAP is not available."
#only Debian 7+
    cat /etc/issue|grep -i 'debian' > /dev/null 2>&1 && {
        oc_D_V=`expr $(cat /etc/debian_version | cut -d. -f1)`
        [ $oc_D_V -lt 7 ] && die "Your system is debian $oc_D_V. Only for Debian 7+."
        [ "$oc_D_V" = "7" ] && oc_D_V="wheezy"
        [ "$oc_D_V" = "8" ] && oc_D_V="jessie"
        [ "$oc_D_V" = "9" ] && oc_D_V="stretch"
        print_info "Debian version ok"
    }
    cat /etc/issue|grep -i 'debian' > /dev/null 2>&1 || {
        print_info "Only test on ubuntu 14.04"
        oc_D_V="$(cat /etc/debian_version | cut -d/ -f1)"
    }
#check install 防止重复安装
    [ -f /usr/sbin/ocserv ] && die "Ocserv has been installed."
    print_info "Not installed ok"
#sources check,del test sources 去掉测试源 
    sed 's/^[ \t]*//' /etc/apt/sources.list | grep -v '^#' | grep 'wheezy-backports' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        oc_wheezy_backports="n"
     else
        sed -i '/wheezy-backports/d' /etc/apt/sources.list
    fi
    print_info "Sources ok"
#install base-tools 
    print_info "Installing base-tools......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed insserv dnsutils
    insserv -s  > /dev/null 2>&1 || sudo ln -s /usr/lib/insserv/insserv /sbin/insserv
    print_info "Get base-tools ok"
#get info from net 从网络中获取信息
    print_info "Getting info from net......"
    get_info_from_net
    print_info "Get info ok"
    clear
}

function get_info_from_net(){
    ocserv_hostname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $ocserv_hostname ]; then
        ocserv_hostname=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
    fi
    OC_version_latest=$(curl -s "http://www.infradead.org/ocserv/download.html" | sed -n 's/^.*version is <b>\(.*$\)/\1/p')
}

function get_Custom_configuration(){
#Which ocserv version to install 安装哪个版本的ocserv
    fast_Default_Ask "$OC_version_latest is the latest,but default version is recommended.Which to choose?" "$Default_oc_version" "oc_version"
#whether to use the certificate login 是否证书登录,默认为用户名密码登录
    fast_Default_Ask "Whether to choose the certificate login?(y/n)" "n" "ca_login"
#whether to generate a Self-signed CA 是否需要制作自签名证书
    fast_Default_Ask "Generate a Self-signed CA for your server?(y/n)" "y" "self_signed_ca"
    if [ "$self_signed_ca" = "n" ]; then
        Default_Ask "Input your own domain for ocserv." "$ocserv_hostname" "fqdnname"
    else 
#get CA's name
        fast_Default_Ask "Your CA's name?" "ocvpn" "caname"
#get Organization name
        fast_Default_Ask "Your Organization name?" "ocvpn" "ogname"
#get Company name
        fast_Default_Ask "Your Company name?" "ocvpn" "coname"
#get server's FQDN
        Default_Ask "Your server's domain?" "$ocserv_hostname" "fqdnname"
    fi
#set max router rulers 最大路由规则限制数目
    fast_Default_Ask "The maximum number of routing table rules?" "200" "max_router"
#which port to use for verification 选择验证端口
    fast_Default_Ask "Which port to use for verification?(Tcp-Port)" "999" "ocserv_tcpport_set"
#tcp-port only or not 是否仅仅使用tcp端口，即是否禁用udp
    fast_Default_Ask "Only use tcp-port or not?(y/n)" "n" "only_tcp_port"
#which port to use for data transmission 选择udp端口 即专用数据传输的udp端口
    if [ "$only_tcp_port" = "n" ]; then
        fast_Default_Ask "Which port to use for data transmission?(Udp-Port)" "1999" "ocserv_udpport_set"
    fi
#boot from the start 是否开机自起
    fast_Default_Ask "Start ocserv when system is started?(y/n)" "y" "ocserv_boot_start"
#Save user vars or not 是否保存脚本参数 以便于下次快速配置
    fast_Default_Ask "Save the vars for fast mode or not?" "n" "save_user_vars"
}

#add a user 增加一个初始用户
function add_a_user(){
#get username,4 figures default
    if [ "$ca_login" = "n" ]; then
        Default_Ask "Input your username for ocserv." "$(get_random_word 4)" "username"
#get password,6 figures default
        Default_Ask "Input your password for ocserv." "$(get_random_word 6)" "password"
    fi
#get password,if ca login,4 figures default
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
        Default_Ask "Input your password for your p12-cert file." "$(get_random_word 4)" "password"
#get expiration days for client p12-cert 获取客户端证书到期天数
        Default_Ask "Input the number of expiration days for your p12-cert file." "7777" "oc_ex_days"
    fi
}

#dependencies onebyone
function Dependencies_install_onebyone(){
    for OC_DP in $oc_dependencies
    do
        print_info "Installing $OC_DP "
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $TEST_S $OC_DP
        if [ $? -eq 0 ]; then
            print_info "[ ${OC_DP} ] ok!"
            apt-get clean
        else
            print_warn "[ ${OC_DP} ] not be installed!"
        fi
    done
}

#lz4 from github
function tar_lz4_install(){
    print_info "Installing lz4 from github"
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq remove --purge liblz4-dev
    apt-get autoremove -qq -y && apt-get clean
    mkdir lz4
    LZ4_VERSION=`curl "https://github.com/Cyan4973/lz4/releases/latest" | sed -n 's/^.*tag\/\(.*\)".*/\1/p'` 
    curl -SL "https://github.com/Cyan4973/lz4/archive/$LZ4_VERSION.tar.gz" -o lz4.tar.gz
    tar -xf lz4.tar.gz -C lz4 --strip-components=1 
    rm lz4.tar.gz 
    cd lz4 
    make -j"$(nproc)" && make install
    cd ..
    rm -r lz4
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ]; then
        ln -sf /usr/local/lib/liblz4.* /usr/lib/x86_64-linux-gnu/
    else
        ln -sf /usr/local/lib/liblz4.* /usr/lib/i386-linux-gnu/
    fi
    print_info "[ lz4 ] ok"
}

#install freeradius-client 1.1.7
function tar_freeradius_client_install(){
    print_info "Installing freeradius-client-1.1.7"
    wget -c ftp://ftp.freeradius.org/pub/freeradius/freeradius-client-1.1.7.tar.gz
    tar -zxf freeradius-client-1.1.7.tar.gz
    cd freeradius-client-1.1.7
    ./configure --prefix=/usr --sysconfdir=/etc
    make -j"$(nproc)" && make install
    cd ..
    rm -rf freeradius-client*
    print_info "[ freeradius-client ] ok"
}

#install dependencies 安装依赖文件
function pre_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | sudo dpkg --set-selections > /dev/null 2>&1
    apt-get upgrade -y
    echo linux-image-`uname -r` install | sudo dpkg --set-selections > /dev/null 2>&1
#no upgrade from test sources 不升级不安装测试源其他包
    [ ! -d /etc/apt/preferences.d ] && mkdir /etc/apt/preferences.d
    [ ! -d /etc/apt/apt.conf.d ] && mkdir /etc/apt/apt.conf.d
    cat > /etc/apt/preferences.d/my_ocserv_preferences<<'EOF'
Package: *
Pin: release wheezy
Pin-Priority: 900
Package: *
Pin: release wheezy-backports
Pin-Priority: 90
Package: *
EOF
    cat > /etc/apt/apt.conf.d/77ocserv<<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
#sources check @ check Required 源检测在前面 for ubuntu+3
    [ "$oc_D_V" = "wheezy" ] || oc_u_dependencies="libgnutls28-dev libseccomp-dev libhttp-parser-dev"
    oc_dependencies="build-essential pkg-config make gcc m4 gnutls-bin libgmp3-dev libwrap0-dev libpam0g-dev libdbus-1-dev libnl-route-3-dev libopts25-dev libnl-nf-3-dev libreadline-dev libpcl1-dev autogen libtalloc-dev $oc_u_dependencies"
    TEST_S=""
    Dependencies_install_onebyone
#add test source 
    echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
#install dependencies from wheezy-backports
    [ "$oc_D_V" = "wheezy" ] && {
        oc_dependencies="libgnutls28-dev libseccomp-dev" && TEST_S="-t wheezy-backports -f --force-yes"
        apt-get update
        Dependencies_install_onebyone
    }
#install freeradius-client-1.1.7
    tar_freeradius_client_install
#install dependencies lz4  增加lz4压缩必须包
#libprotobuf-c-dev libhttp-parser-dev
#lz4
    tar_lz4_install
#if sources del 如果本来没有测试源便删除
    [ "$oc_wheezy_backports" = "n" ] && sed -i '/wheezy-backports/d' /etc/apt/sources.list
#keep update
    rm -f /etc/apt/preferences.d/my_ocserv_preferences
    rm -f /etc/apt/apt.conf.d/77ocserv
    [ "$oc_D_V" = "wheezy" ] && apt-get update
    print_info "Dependencies  ok"
}

#install 编译安装
function tar_ocserv_install(){
    cd ${Script_Dir}
#default max route rulers
    max_router=${max_router:-200}
#default version  默认版本
    oc_version=${oc_version:-${Default_oc_version}}
    wget -c ftp://ftp.infradead.org/pub/ocserv/ocserv-$oc_version.tar.xz
    tar xvf ocserv-$oc_version.tar.xz
    rm -rf ocserv-$oc_version.tar.xz
    cd ocserv-$oc_version
#have to use "" then $ work ,set router limit 设定路由规则最大限制
    sed -i "s|\(#define MAX_CONFIG_ENTRIES \).*|\1$max_router|" src/vpn.h
    ./configure --prefix=/usr --sysconfdir=/etc 2>${Script_Dir}/ocerror.log
    make -j"$(nproc)" 2>>${Script_Dir}/ocerror.log
    make install
#check install 检测编译安装是否成功
    [ ! -f /usr/sbin/ocserv ] && {
        make clean
        die "Ocserv install failure,check ${Script_Dir}/ocerror.log"
    }
#mv files
    rm -f ${Script_Dir}/ocerror.log
    mkdir -p /etc/ocserv/CAforOC/revoke > /dev/null 2>&1
    mkdir /etc/ocserv/{config-per-group,defaults} > /dev/null 2>&1
    cp doc/profile.xml /etc/ocserv
    sed -i "s|localhost|$ocserv_hostname|" /etc/ocserv/profile.xml
    cd ..
    rm -rf ocserv-$oc_version
#get or set config file
    cd /etc/ocserv
    cat > /etc/init.d/ocserv <<'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ocserv
# Required-Start:    $network $local_fs $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO
# Copyright Rene Mayrhofer, Gibraltar, 1999
# This script is distibuted under the GPL
 
PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/ocserv
PIDFILE=/var/run/ocserv.pid
DAEMON_ARGS="-c /etc/ocserv/ocserv.conf"

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0
 
case "$1" in
start)
if [ ! -r $PIDFILE ]; then
echo -n "Starting OpenConnect VPN Server Daemon: "
. /etc/ocserv/start-ocserv-sysctl.sh
start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
$DAEMON_ARGS > /dev/null
echo "[ok]"
else
echo -n "OpenConnect VPN Server is already running.\n\r"
exit 0
fi
;;
stop)
echo -n "Stopping OpenConnect VPN Server Daemon: "
. /etc/ocserv/stop-ocserv-sysctl.sh
start-stop-daemon --stop --quiet --pidfile $PIDFILE --exec $DAEMON
echo "[ok]"
rm -f $PIDFILE
;;
force-reload|restart)
echo "Restarting OpenConnect VPN Server: "
$0 stop
sleep 3
$0 start
;;
status)
if [ ! -r $PIDFILE ]; then
echo "no pid file, process doesn't seem to be running correctly"
exit 3
fi
PID=`cat $PIDFILE | sed 's/ //g'`
EXE=/proc/$PID/exe
if [ -x "$EXE" ] &&
[ "`ls -l \"$EXE\" | cut -d'>' -f2,2 | cut -d' ' -f2,2`" = \
"$DAEMON" ]; then
echo "ok, process seems to be running"
exit 0
elif [ -r $PIDFILE ]; then
echo "process not running, but pidfile exists"
exit 1
else
echo "no lock file to check for, so simply return the stopped status"
exit 3
fi
;;
*)
echo "Usage: /etc/init.d/ocserv {start|stop|restart|force-reload|status}"
exit 1
;;
esac

:
EOF
    chmod 755 /etc/init.d/ocserv
    cat > start-ocserv-sysctl.sh <<'EOF'
#!/bin/bash

#vars
OCSERV_CONFIG="/etc/ocserv/ocserv.conf"

# turn on IP forwarding
#sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#get gateway and profiles
gw_intf_oc=`ip route show|sed -n 's/^default.* dev \([^ ]*\).*/\1/p'`
ocserv_tcpport=`sed -n 's/^tcp-.*=[ \t]*//p' $OCSERV_CONFIG`
ocserv_udpport=`sed -n 's/^udp-.*=[ \t]*//p' $OCSERV_CONFIG`
ocserv_ip4_work_mask=`sed -n 's/^ipv4-.*=[ \t]*//p' $OCSERV_CONFIG|sed 'N;s|\n|/|g'`

# turn on NAT over default gateway and VPN
if !(iptables-save -t nat | grep -q "$gw_intf_oc (ocserv)"); then
iptables -t nat -A POSTROUTING -s $ocserv_ip4_work_mask -o $gw_intf_oc -m comment --comment "$gw_intf_oc (ocserv)" -j MASQUERADE
fi

if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv2)"); then
iptables -A FORWARD -s $ocserv_ip4_work_mask -m comment --comment "$gw_intf_oc (ocserv2)" -j ACCEPT
fi

if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv3)"); then
iptables -A INPUT -p tcp --dport $ocserv_tcpport -m comment --comment "$gw_intf_oc (ocserv3)" -j ACCEPT
fi

if [ "$ocserv_udpport" != "" ]; then
    if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv4)"); then
        iptables -A INPUT -p udp --dport $ocserv_udpport -m comment --comment "$gw_intf_oc (ocserv4)" -j ACCEPT
    fi
fi

if !(iptables-save -t filter | grep -q "$gw_intf_oc (ocserv5)"); then
iptables -A FORWARD  -m state --state RELATED,ESTABLISHED -m comment --comment "$gw_intf_oc (ocserv5)" -j ACCEPT
fi

# turn on MSS fix
# MSS = MTU - TCP header - IP header
if !(iptables-save -t mangle | grep -q "$gw_intf_oc (ocserv6)"); then
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -m comment --comment "$gw_intf_oc (ocserv6)" -j TCPMSS --clamp-mss-to-pmtu
fi

echo "..."
EOF
    chmod +x start-ocserv-sysctl.sh
    cat > stop-ocserv-sysctl.sh <<'EOF'
#!/bin/bash

# uncomment if you want to turn off IP forwarding
# sysctl -w net.ipv4.ip_forward=0

#del iptables

iptables-save | grep 'ocserv' | sed 's/^-A P/iptables -t nat -D P/' | sed 's/^-A FORWARD -p/iptables -t mangle -D FORWARD -p/' | sed 's/^-A/iptables -D/' | bash

echo "..."
EOF
    chmod +x stop-ocserv-sysctl.sh
    while [ ! -f ocserv.conf ]; do
        wget -c $OC_CONF_NET_DOC/ocserv.conf --no-check-certificate
    done
    while [ ! -f config-per-group/Route ]; do
        wget -c $OC_CONF_NET_DOC/routerulers -O config-per-group/Route --no-check-certificate
    done
    if [ ! -f dh.pem ]; then
        print_info "Perhaps generate DH parameters will take some time , please wait..."
        certtool --generate-dh-params --sec-param high --outfile dh.pem
    fi
    clear
    print_info "Ocserv install ok"
    
}

function make_ocserv_ca(){
    print_info "Generating Self-signed CA..."
#all in one doc
    cd /etc/ocserv/CAforOC
#Self-signed CA set
#ca's name#organization name#company name#server's FQDN
    caname=${caname:-ocvpn}
    ogname=${ogname:-ocvpn}
    coname=${coname:-ocvpn}
    fqdnname=${fqdnname:-$ocserv_hostname}
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
#generating a local server key-certificate pair 通过自签证书授权中心制作服务器的私钥与证书
    certtool --generate-privkey --outfile server-key.pem
    cat << _EOF_ > server.tmpl
cn = "$fqdnname"
organization = "$coname"
serial = 2
expiration_days = 7777
signing_key
encryption_key
tls_www_server
_EOF_
    certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
    [ ! -f server-cert.pem ] && die "server-cert.pem NOT Found , make failure!"
    [ ! -f server-key.pem ] && die "server-key.pem NOT Found , make failure!"
    cp server-cert.pem /etc/ocserv && cp server-key.pem /etc/ocserv
    cp ca-cert.pem /etc/ocserv
    print_info "Self-signed CA for ocserv ok"
}

function ca_login_ocserv(){
#make a client cert
    print_info "Generating a client cert..."
    cd /etc/ocserv/CAforOC
    caname=`cat ca.tmpl | grep cn | cut -d '"' -f 2`
    if [ "X${caname}" = "X" ]; then
        Default_Ask "Tell me your CA's name." "ocvpn" "caname"
    fi
    name_user_ca=$(get_random_word 4)
    while [ -d user-${name_user_ca} ]; do
        name_user_ca=$(get_random_word 4)
    done
    mkdir user-${name_user_ca}
    oc_ex_days=${oc_ex_days:-7777}
    cat << _EOF_ > user-${name_user_ca}/user.tmpl
cn = "user-${name_user_ca}"
unit = "Route"
expiration_days = ${oc_ex_days}
signing_key
tls_www_client
_EOF_
#user key
    certtool --generate-privkey --outfile user-${name_user_ca}/user-${name_user_ca}-key.pem
#user cert
    certtool --generate-certificate --load-privkey user-${name_user_ca}/user-${name_user_ca}-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template user-${name_user_ca}/user.tmpl --outfile user-${name_user_ca}/user-${name_user_ca}-cert.pem
#p12
    openssl pkcs12 -export -inkey user-${name_user_ca}/user-${name_user_ca}-key.pem -in user-${name_user_ca}/user-${name_user_ca}-cert.pem -name "user-${name_user_ca}" -certfile ca-cert.pem -caname "$caname" -out user-${name_user_ca}/user-${name_user_ca}.p12 -passout pass:$password
#cp to ${Script_Dir}
    cp user-${name_user_ca}/user-${name_user_ca}.p12 ${Script_Dir}
#make a empty revocation list
    if [ ! -f crl.tmpl ];then
    cat << _EOF_ >crl.tmpl
crl_next_update = 7777 
crl_number = 1 
_EOF_
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --template crl.tmpl --outfile ../crl.pem
    fi
    print_info "Generate client cert ok"
}

#set 设定相关参数
function set_ocserv_conf(){
#default vars
    ocserv_tcpport_set=${ocserv_tcpport_set:-999}
    ocserv_udpport_set=${ocserv_udpport_set:-1999}
    save_user_vars=${save_user_vars:-n}
    ocserv_boot_start=${ocserv_boot_start:-y}
    only_tcp_port=${only_tcp_port:-n}
#set port
    sed -i "s|\(tcp-port = \).*|\1$ocserv_tcpport_set|" /etc/ocserv/ocserv.conf
    sed -i "s|\(udp-port = \).*|\1$ocserv_udpport_set|" /etc/ocserv/ocserv.conf
#default domain compression dh.pem
    sed -i "s|^[# \t]*\(default-domain = \).*|\1$fqdnname|" /etc/ocserv/ocserv.conf
    sed -i "s|^[# \t]*\(compression = \).*|\1true|" /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(dh-params = \).*|\1/etc/ocserv/dh.pem|' /etc/ocserv/ocserv.conf
#2-group 增加组 bug 证书登录无法正常使用Default组
    [ "$open_two_group" = "y" ] && two_group_set
    echo "route = 0.0.0.0/128.0.0.0" > /etc/ocserv/defaults/group.conf
    echo "route = 128.0.0.0/128.0.0.0" >> /etc/ocserv/defaults/group.conf
    echo "route = 0.0.0.0/128.0.0.0" > /etc/ocserv/config-per-group/All
    echo "route = 128.0.0.0/128.0.0.0" >> /etc/ocserv/config-per-group/All
#boot from the start 开机自启
    [ "$ocserv_boot_start" = "y" ] && sudo insserv ocserv > /dev/null 2>&1
#add a user 增加一个初始用户
    [ "$ca_login" = "n" ] && plain_login_set
#set only tcp-port 仅仅使用tcp端口
    [ "$only_tcp_port" = "y" ] && sed -i 's|^[ \t]*\(udp-port = \)|#\1|' /etc/ocserv/ocserv.conf
#set ca_login
    if [ "$ca_login" = "y" ]; then
        sed -i 's|^[ \t]*\(auth = "plain\)|#\1|' /etc/ocserv/ocserv.conf
        sed -i 's|^[# \t]*\(auth = "certificate"\)|\1|' /etc/ocserv/ocserv.conf
        ca_login_set
    fi
#save custom-configuration files or not
    [ "$save_user_vars" = "n" ] && rm -f $CONFIG_PATH_VARS
    print_info "Set ocserv ok"
}

function two_group_set(){
    sed -i 's|^[# \t]*\(cert-group-oid = \).*|\12.5.4.11|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(select-group = \)group1.*|\1Route|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(select-group = \)group2.*|\1All|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(default-select-group = \).*|\1Default|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(auto-select-group = \).*|\1false|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(config-per-group = \).*|\1/etc/ocserv/config-per-group|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(default-group-config = \).*|\1/etc/ocserv/defaults/group.conf|' /etc/ocserv/ocserv.conf
}

function plain_login_set(){
    [ "$open_two_group" = "y" ] && group_name='-g "Route,All"'
    (echo "$password"; sleep 1; echo "$password") | ocpasswd -c /etc/ocserv/ocpasswd $group_name $username
}

function ca_login_set(){
    sed -i 's|^[# \t]*\(ca-cert = \).*|\1/etc/ocserv/ca-cert.pem|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(crl = \).*|\1/etc/ocserv/crl.pem|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(cert-user-oid = \).*|\12.5.4.3|' /etc/ocserv/ocserv.conf
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
}

function start_ocserv(){
    [ ! -f /etc/ocserv/server-cert.pem ] && die "server-cert.pem NOT Found !!!"
    [ ! -f /etc/ocserv/server-key.pem ] && die "server-key.pem NOT Found !!!"
#start
    /etc/init.d/ocserv start
}

function show_ocserv(){
    ocserv_port=`sed -n 's/^[ \t]*tcp-port[ \t]*=[ \t]*//p' /etc/ocserv/ocserv.conf`
    clear
    ps cax | grep ocserv > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ "$ca_login" = "y" ]; then
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
            echo -e "\033[41;37m Your p12-cert's number of expiration days is \033[0m" "$oc_ex_days"
            print_warn "You could get user-${name_user_ca}.p12 from ${Script_Dir}."
            print_warn "You could stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn "Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info "Enjoy it!"
            echo ""
        else
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your username is \033[0m" "$username"
            echo -e "\033[41;37m Your password is \033[0m" "$password"
            print_warn "You could use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users. "
            print_warn "You could stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn "Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info "Enjoy it!"
            echo ""
        fi
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "n" ]; then    
        print_warn "1,You should change Server Certificate and Server Key's name to server-cert.pem and server-key.pem !!!"
        print_warn "2,You should put them to /etc/ocserv !!!"
        print_warn "3,You should start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn "4,You could use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users."
        print_warn "5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo -e "\033[41;37m Your username is \033[0m" "$username"
        echo -e "\033[41;37m Your password is \033[0m" "$password"
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "y" ]; then
        print_warn "1,You should change your Server Certificate and Server Key's name to server-cert.pem and server-key.pem !!!"
        print_warn "2,You should change your Certificate Authority Certificates and Certificate Authority Key's  name to ca-cert.pem and ca-key.pem!!!"
        print_warn "3,You should put server-cert.pem server-key.pem and ca-cert.pem to /etc/ocserv !!!"
        print_warn "4,You should put ca-cert.pem and ca-key.pem to /etc/ocserv/CAforOC !!!"
        print_warn "5,You should use ' bash `basename $0` gc ' to get a client cert !!!"
        print_warn "6,You could start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn "7,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
    else
        print_warn "Ocserv start failure,ocserv is offline!"
    fi
}

function check_ca_cert(){
    [ ! -f /usr/sbin/ocserv ] && die "Ocserv NOT Found !!!"
    [ ! -f /etc/ocserv/CAforOC/ca-cert.pem ] && die "ca-cert.pem NOT Found !!!"
    [ ! -f /etc/ocserv/CAforOC/ca-key.pem ] && die "ca-key.pem NOT Found !!!"
}

function get_new_userca(){
    check_ca_cert
    ca_login="y"
    self_signed_ca="y"
    add_a_user
    press_any_key
    ca_login_ocserv
    clear
}

function get_new_userca_show(){
    echo
    echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
    echo -e "\033[41;37m Your p12-cert's number of expiration days is \033[0m" "$oc_ex_days"
    print_warn " You could get user-${name_user_ca}.p12 from ${Script_Dir}."
    print_warn " You should import the certificate to your device at first."
    echo
    print_info "Enjoy it"
}

function Outdate_Autoclean(){
    My_All_Ca=`ls -F|sed -n 's/\(user-.*\)\//\1/p'|sed ':a;N;s/\n/ /;ba;'`
    for My_One_Ca in $My_All_Ca
    do
        Client_EX_Days=`sed -n 's/.*days = //p' $My_One_Ca/user.tmpl`
        Client_Ifsign_Date=`expr $(date +%Y%m%d -d "-$Client_EX_Days day")`
        Client_Truesign_Date=`expr $(date -r $My_One_Ca/user.tmpl +%Y%m%d)`
        if [ $Client_Truesign_Date -lt $Client_Ifsign_Date ]; then
            mv $My_One_Ca -t revoke/
        fi
    done
}

function revoke_userca(){
    check_ca_cert
#get info
    cd /etc/ocserv/CAforOC
    Outdate_Autoclean
    clear
    print_xxxx
    print_info "The following is the user list..."
    echo
    ls -F|grep /|grep user|cut -d/ -f1
    print_xxxx
    print_info "Which user do you want to revoke?"
    echo
    read -p "Which: " -e -i user- revoke_ca
    if [ ! -f /etc/ocserv/CAforOC/$revoke_ca/$revoke_ca-cert.pem ]
    then
        die "$revoke_ca NOT Found !!!"
    fi
    echo
    print_warn "Okay,${revoke_ca} will be revoked."
    print_xxxx
    press_any_key
#revoke   
    cat ${revoke_ca}/${revoke_ca}-cert.pem >>revoked.pem
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --load-certificate revoked.pem --template crl.tmpl --outfile ../crl.pem
#show
    mv ${revoke_ca} revoke/
    print_info "${revoke_ca} was revoked."
    echo    
}

function reinstall_ocserv(){
    stop_ocserv
    rm -rf /etc/ocserv
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    install_OpenConnect_VPN_server
}

function upgrade_ocserv(){    
    get_info_from_net
    Default_Ask "The latest is ${OC_version_latest}.Input the version you want to upgrade?" "$OC_version_latest" "oc_version"
    Default_Ask "The maximum number of routing table rules?" "200" "max_router"
    press_any_key
    stop_ocserv
    rm -f /etc/ocserv/profile.xml
    rm -f /usr/sbin/ocserv
    tar_ocserv_install
    start_ocserv
    ps cax | grep ocserv > /dev/null 2>&1
    if [ $? -eq 0 ]; then
    print_info "Your ocserv upgrade was successful!"
    else
    print_warn "Ocserv start failure,ocserv is offline!"
    print_info "You could use ' bash `basename $0` ri' to forcibly upgrade your ocserv."
    fi
}

function enable_both_login_open_ca(){
    get_new_userca
    sed -i 's|^[# \t]*\(enable-auth = certificate\)|\1|' /etc/ocserv/ocserv.conf
    ca_login_set
    stop_ocserv
    start_ocserv
    clear
    echo
    print_info "The plain login and the certificate login are Okay~"
    print_info "The following is your certificate login info~"
    get_new_userca_show
}

function enable_both_login_open_plain(){
    ca_login="n"
    add_a_user
    press_any_key
    plain_login_set
    sed -i 's|^[ \t]*\(auth = "certificate"\)|#\1|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(auth = "plain\)|\1|' /etc/ocserv/ocserv.conf
    sed -i 's|^[# \t]*\(enable-auth = certificate\)|\1|' /etc/ocserv/ocserv.conf
    stop_ocserv
    start_ocserv
    clear
    echo
    print_info "The plain login and the certificate login are Okay~"
    print_info "The following is your plain login info~"
    echo
    echo -e "\033[41;37m Your username is \033[0m" "$username"
    echo -e "\033[41;37m Your password is \033[0m" "$password"
    echo
    print_info "Enjoy it"
}

function help_ocservauto(){
    print_xxxx
    print_info "######################## Parameter Description ####################################"
    echo
    print_info " install ----------------------- Install ocserv for Debian 7+"
    echo
    print_info " fastmode or fm ---------------- Rapid installation for ocserv through $CONFIG_PATH_VARS"
    echo
    print_info " getuserca or gc --------------- Get a new client certificate"
    echo
    print_info " revokeuserca or rc ------------ Revoke a client certificate"
    echo
    print_info " upgrade or ug ----------------- Smoothly upgrade your ocserv"
    echo
    print_info " reinstall or ri --------------- Force to reinstall your ocserv(Destroy All Data)"
    echo
    print_info " pc ---------------------------- At the same time,enable the plain login and the certificate login"
    echo
    print_info " help or h --------------------- Show this description"
    print_xxxx
}
###################################################################################################################
#main                                                                                                             #
###################################################################################################################

#install info
clear
echo "==============================================================================================="
echo
print_info " System Required:  Debian 7+"
echo
print_info " Description:  Install OpenConnect VPN server"
echo
print_info " Help Info:  bash `basename $0` help"
echo
echo "==============================================================================================="

#脚本所在文件夹
Script_Dir="$(cd "$(dirname $0)"; pwd)"
#fastmode vars 存放配置参数文件的绝对路径，快速安装模式可用
CONFIG_PATH_VARS="${Script_Dir}/vars_ocservauto"
#ocserv配置文件所在的网络文件夹位置，请勿轻易改变
OC_CONF_NET_DOC="https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto"
#推荐的默认版本
Default_oc_version="0.10.2"
open_two_group="n"


#Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_OpenConnect_VPN_server
    ;;
fastmode | fm)
    fast_install="y"
    [ ! -f $CONFIG_PATH_VARS ] && die "$CONFIG_PATH_VARS Not Found !"
    . $CONFIG_PATH_VARS
    install_OpenConnect_VPN_server
    ;;
getuserca | gc)
    get_new_userca
    get_new_userca_show
    ;;
revokeuserca | rc)
    revoke_userca
    ;;
upgrade | ug)
    upgrade_ocserv
    ;;
reinstall | ri)
    reinstall_ocserv
    ;;
pc)
    [  -f /etc/ocserv/crl.pem ] && enable_both_login_open_plain
    [ ! -f /etc/ocserv/crl.pem ] && enable_both_login_open_ca
    ;;
help | h)
    help_ocservauto
    ;;
*)
    clear
    print_warn "Arguments error! [ ${action} ]"
    print_warn "Usage:  bash `basename $0` {install|fm|gc|rc|ug|ri|pc|help}"
    help_ocservauto
    ;;
esac
