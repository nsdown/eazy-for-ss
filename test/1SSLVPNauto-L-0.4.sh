#! /bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install OpenConnect VPN server for Debian
#   Ocservauto For Debian Copyright (C) liyangyijie released under GNU GPLv2
#   Ocservauto For Debian Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   
#===============================================================================================

###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################

#error and force-exit
function die {
    echo -e "\033[33mERROR: $1 \033[0m" > /dev/null 1>&2
    exit 1
}

#info echo
function print_info {
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

##### echo
function print_xxxx {
    xXxX="#############################"
    echo
    echo "$xXxX$xXxX$xXxX$xXxX"
    echo
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

#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
#rewrite $ok
    if [  -f ${CONFIG_PATH_VARS} ] ; then
        New_temp_default_var=`cat $CONFIG_PATH_VARS | grep "^$Temp_var_name=" | cut -d "'" -f 2`
        Temp_default_var=${New_temp_default_var:-$Temp_default_var}
        sed -i "/^${Temp_var_name}=/d" $CONFIG_PATH_VARS
    fi
#if yes or no 
    echo -e -n "\e[1;36m$Temp_question\e[0m""\033[31m(Default:$Temp_default_var): \033[0m"
    read Temp_var
    if [ "$Temp_default_var" = "y" ] || [ "$Temp_default_var" = "n" ] ; then
        case $Temp_var in
            Y|y|YES|Yes|yes|YEs|YE|ye|Ye)
                Temp_var=y
                ;;
            N|n|NO|No|no)
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
    echo $Temp_cmd >> $CONFIG_PATH_VARS
    echo
    print_info "Your answer is : ${Temp_var}"
    echo
    print_xxxx
}

#Press any key to start 任意键开始
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

#fast mode
function fast_Default_Ask(){
    if [ "$fast_install" = "y" ] ; then
        print_info "In the fast mode, $3 will be loaded from $CONFIG_PATH_VARS"
    else
        Default_Ask "$1" "$2" "$3"
    fi
}

###################################################################################################################
#core-function                                                                                                    #
###################################################################################################################

#install 安装主体
function install_OpenConnect_VPN_server(){
#check system , get IP and port ,del test sources 检测系统 获取本机公网ip、默认验证端口 去除测试源
    check_Required
	
#custom-configuration or not 自定义安装与否
    fast_Default_Ask "Install ocserv with Custom Configuration?(y/n)" "n" "Custom_config_ocserv"
    if [ "$Custom_config_ocserv" = "y" ]; then
        clear
        print_xxxx
        print_info "Install ocserv with custom configuration."
        echo
        print_info "You should know what you are modifying , it is recommended that you use the default settings."
        print_xxxx
        get_Custom_configuration
    else
        print_xxxx
        print_info "Automatic installation."
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

#make a client cert 制作证书登录	
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
    oc_D_V=`expr $(cat /etc/debian_version | cut -d. -f1)`
    if [ $oc_D_V -lt 7 ]
    then
        die "Looks like your system is debian $oc_D_V. Only for Debian 7+"
    fi
    print_info "Debian version ok"
#check install 防止重复安装
    if [ -f /usr/sbin/ocserv ]
    then
        die "Ocserv has been installed!!!"
    fi
    print_info "Not installed ok"
#get IPv4 info,install base-tools 
    print_info "Getting ip and base-tools from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed insserv dnsutils
    ocserv_hostname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $ocserv_hostname ]; then
        ocserv_hostname=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
    fi
    print_info "Get ip and base-tools ok"
#sources check,del test sources 去掉测试源 
    cat /etc/apt/sources.list | grep -v '^#' | grep 'jessie' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        oc_jessie="n"
     else
        sed -i '/jessie/d' /etc/apt/sources.list
    fi
    cat /etc/apt/sources.list | grep -v '^#' | grep 'wheezy-backports' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        oc_wheezy_backports="n"
     else
        sed -i '/wheezy-backports/d' /etc/apt/sources.list
    fi
    print_info "Sources ok"
#get profiles from net 从网络中获取配置
    print_info "Getting default port from net......"
    ocserv_tcpport_Default=$(wget -qO- --no-check-certificate $OC_CONF_NET_DOC/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g')
    ocserv_udpport_Default=$(wget -qO- --no-check-certificate $OC_CONF_NET_DOC/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g')
    OC_version_latest=$(curl -s "http://www.infradead.org/ocserv/download.html" | sed -n 's/^.*version is <b>\(.*$\)/\1/p')
    print_info "Get profiles ok"
    clear
}

function get_Custom_configuration(){
#whether to make a Self-signed CA 是否需要制作自签名证书
    fast_Default_Ask "Make a Self-signed CA for your server?(y/n)" "y" "self_signed_ca"
    if [ "$self_signed_ca" = "n" ]; then
        fast_Default_Ask "Input your own domain for ocserv:" "$ocserv_hostname" "fqdnname"
    else 
#get CA's name
        fast_Default_Ask "Your CA's name:" "ocvpn" "caname"
#get Organization name
        fast_Default_Ask "Your Organization name:" "ocvpn" "ogname"
#get Company name
        fast_Default_Ask "Your Company name:" "ocvpn" "coname"
#get server's FQDN
        Default_Ask "Your server's FQDN:" "$ocserv_hostname" "fqdnname"
    fi
#set max router rulers 最大路由规则限制数目
    fast_Default_Ask "The maximum number of routing table rules?" "200" "max_router"
#which port to use for verification 选择验证端口
    fast_Default_Ask "Which port to use for verification?(Tcp-Port)" "$ocserv_tcpport_Default" "ocserv_tcpport_set"
#tcp-port only or not 是否仅仅使用tcp端口，即是否禁用udp
    fast_Default_Ask "Only use tcp-port or not?(y/n)" "n" "only_tcp_port"
#which port to use for data transmission 选择udp端口 即专用数据传输的udp端口
    if [ "$only_tcp_port" = "n" ]; then
        fast_Default_Ask "Which port to use for data transmission?(Udp-Port)" "$ocserv_udpport_Default" "ocserv_udpport_set"
    fi
#boot from the start 是否开机自起
    fast_Default_Ask "Start ocserv when system is started?(y/n)" "y" "ocserv_boot_start"
#whether to use the certificate login 是否证书登录或者用户名密码登录
    fast_Default_Ask "Whether to choose the certificate login?(y/n)" "n" "ca_login"
#Which ocserv version to install 安装哪个版本的ocserv
    fast_Default_Ask "$OC_version_latest is the latest ocserv version,but default version is recommended.Which to choose?" "0.9.2" "oc_version"
#Save user vars or not 是否保存脚本参数 以便于下次快速配置
    fast_Default_Ask "Save the vars for fast mode or not?" "n" "save_user_vars"
}

#add a user 增加一个初始用户
function add_a_user(){
#get username,4 figures default
    if [ "$ca_login" = "n" ]; then
        fast_Default_Ask "Input your username for ocserv:" "$(get_random_word 4)" "username"
#get password,6 figures default
        Default_Ask "Input your password for ocserv:" "$(get_random_word 6)" "password"
        sed -i '/password=/d' $CONFIG_PATH_VARS
    fi
#get password,if ca login,4 figures default
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
        Default_Ask "Input your password for your p12-cert file:" "$(get_random_word 4)" "password"
        sed -i '/password=/d' $CONFIG_PATH_VARS
    fi
}
#dependencies onebyone
function Dependencies_install_onebyone {
    for OC_DP in $oc_dependencies
    do
        print_info "Installing the $OC_DP "
        apt-get install -y $TEST_S $OC_DP
        if [ $? -eq 0 ]; then
            print_info "[$OC_DP] ok!"
        else
            print_warn "[$OC_DP] not be installed!"
        fi
    done
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
Pin: release wheezy
Pin-Priority: 900
Package: *
Pin: release wheezy-backports
Pin-Priority: 90
Package: *
Pin: release jessie
Pin-Priority: 60
EOF
#sources check @ check Required 源检测在前面 增加压缩必须包
    oc_dependencies="build-essential pkg-config make gcc m4 gnutls-bin libgmp3-dev libwrap0-dev libpam0g-dev libdbus-1-dev libnl-route-3-dev libopts25-dev libnl-nf-3-dev libreadline-dev libpcl1-dev autogen libtalloc-dev"
    TEST_S=""
    Dependencies_install_onebyone
#add test source 
    echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
    echo "deb http://ftp.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list
    apt-get update
#install dependencies from wheezy-backports
    oc_dependencies="libgnutls28-dev libseccomp-dev"
    TEST_S="-t wheezy-backports"
    Dependencies_install_onebyone
#install dependencies from jessie
#    oc_dependencies="libprotobuf-c-dev libhttp-parser-dev liblz4-dev" #虽然可以完善编译项目 但是意义不大
    oc_dependencies="liblz4-dev"
    TEST_S="-t jessie"
    Dependencies_install_onebyone
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
    cd /root
#default max route rulers
    max_router=${max_router:-200}
#default version is 0.9.2 默认版本是为0.9.2
    oc_version=${oc_version:-0.9.2}
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
    mkdir -p $OC_LC_DOC/CAforOC/revoke
    cp doc/profile.xml $OC_LC_DOC
    cp doc/dbus/org.infradead.ocserv.conf /etc/dbus-1/system.d
    cd ..
    rm -rf ocserv-$oc_version
#get config file from net
    cd $OC_LC_DOC
    wget $OC_CONF_NET_DOC/ocserv.conf --no-check-certificate
    wget $OC_CONF_NET_DOC/start-ocserv-sysctl.sh  --no-check-certificate
    wget $OC_CONF_NET_DOC/stop-ocserv-sysctl.sh  --no-check-certificate
    wget $OC_CONF_NET_DOC/ocserv  --no-check-certificate
    chmod 755 ocserv
    mv ocserv /etc/init.d
    chmod +x start-ocserv-sysctl.sh
    chmod +x stop-ocserv-sysctl.sh
    print_info "Ocserv install ok"
}

function make_ocserv_ca {
#all in one doc
    cd $OC_LC_DOC/CAforOC
#Self-signed CA set
#ca's name #organization name#company name#server's FQDN
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
#generating a local server key-certificate pair 通过自签证书授权中心制作服务器的证书与私钥
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
    if [ ! -f server-cert.pem ] || [ ! -f server-key.pem ]; then	
        die "server-cert.pem or server-key.pem NOT Found , make failure!"
    fi
    cp server-cert.pem $OC_LC_DOC && cp server-key.pem $OC_LC_DOC
    cp ca-cert.pem $OC_LC_DOC && cp ca-cert.pem /root
    print_info "Self-signed CA for ocserv ok , you could get the ca-cert.pem from /root"
}

function ca_login_ocserv {
#make a client cert
    print_info "Making a client cert..."
    cd $OC_LC_DOC/CAforOC
    caname=`cat ca.tmpl | grep cn | cut -d '"' -f 2`
    if [ "X${caname}" = "X" ]; then
        Default_Ask "Tell me your CA's name." "ocvpn" "caname"
    fi
    name_user_ca=$(get_random_word 4)
    if [ -d user-${name_user_ca} ];then
        name_user_ca=$(get_random_word 8)${name_user_ca}
    fi
    cat << _EOF_ > user.tmpl
cn = "Client ${name_user_ca}"
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
    openssl pkcs12 -export -inkey user-key.pem -in user-cert.pem -name "Client ${name_user_ca}" -certfile ca-cert.pem -caname "$caname" -out user.p12 -passout pass:$password
#rename
    mkdir user-${name_user_ca}
    mv user-key.pem user-${name_user_ca}/user-${name_user_ca}-key.pem
    mv user-cert.pem user-${name_user_ca}/user-${name_user_ca}-cert.pem
    mv user.p12 user-${name_user_ca}/user-${name_user_ca}.p12
#cp to root
    cp user-${name_user_ca}/user-${name_user_ca}.p12 /root
#make a empty revocation list
    if [ ! -f crl.tmpl ];then
    cat << EOF >crl.tmpl
crl_next_update = 7777 
crl_number = 1 
EOF
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --template crl.tmpl --outfile ../crl.pem
    fi
    print_info "Set client cert ok"
}

#set 设定相关参数
function set_ocserv_conf(){
#set port
    if [ "$ocserv_tcpport_set" != "" ]; then
        sed -i "s@tcp-port = $ocserv_tcpport_Default@tcp-port = $ocserv_tcpport_set@g" $OC_LC_FILE
    fi
    if [ "$ocserv_udpport_set" != "" ]; then
        sed -i "s@udp-port = $ocserv_udpport_Default@udp-port = $ocserv_udpport_set@g" $OC_LC_FILE
    fi
#default domain 
    sed -i "s@#default-domain = example.com@default-domain = $fqdnname@" $OC_LC_FILE 
#boot from the start 开机自启
    if [ "$ocserv_boot_start" = "y" ]; then
        sudo insserv ocserv
    fi
#add a user 增加一个初始用户
    if [ "$ca_login" = "n" ]; then
    (echo "$password"; sleep 1; echo "$password") | ocpasswd -c "$OC_LC_DOC/ocpasswd" $username
    fi
#set only tcp-port 仅仅使用tcp端口
    if [ "$only_tcp_port" = "y" ]; then
        sed -i 's@udp-port = @#udp-port = @g' $OC_LC_FILE
    fi
#set ca_login
    if [ "$ca_login" = "y" ]; then
        sed -i 's@auth = "plain@#auth = "plain@g' $OC_LC_FILE
        sed -i 's@#auth = "certificate"@auth = "certificate"@' $OC_LC_FILE
        sed -i 's@#ca-cert = /path/to/ca.pem@ca-cert = $OC_LC_DOC/ca-cert.pem@' $OC_LC_FILE
        sed -i 's@#crl = /path/to/crl.pem@crl = $OC_LC_DOC/crl.pem@' $OC_LC_FILE
        sed -i 's@#cert-user-oid = @cert-user-oid = @' $OC_LC_FILE
    fi
#save custom-configuration files or not ,del password
    sed -i '/password=/d' $CONFIG_PATH_VARS
    sed -i '/export fqdnname=/d' $CONFIG_PATH_VARS
    save_user_vars=${save_user_vars:-n}
    if [ $save_user_vars = "n" ] ; then
        rm -rf $CONFIG_PATH_VARS
    fi
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
}

function start_ocserv(){
    if [ ! -f $OC_LC_DOC/server-cert.pem ] || [ ! -f $OC_LC_DOC/server-key.pem ]; then
        die "server-cert.pem or server-key.pem NOT Found !!!"
    fi
#start
    /etc/init.d/ocserv start
}

function show_ocserv(){
    ocserv_port=`cat $OC_LC_FILE | grep '^tcp-port' | sed 's/tcp-port = //g'`
    clear
    ps -ef | grep -v grep | grep -v ps | grep -i '/usr/sbin/ocserv' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ "$ca_login" = "y" ]; then
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
            print_warn " You could get user-${name_user_ca}.p12 from /root."
            print_warn " You could stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn " Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info " Enjoy it!"
            echo ""
        else
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your username is \033[0m" "$username"
            echo -e "\033[41;37m Your password is \033[0m" "$password"
            print_warn " You could use ' sudo ocpasswd -c $OC_LC_DOC/ocpasswd username ' to add users. "
            print_warn " You could stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn " Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info " Enjoy it!"
            echo ""
        fi
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "n" ]; then    
        print_warn " 1,You should change Server Certificate and Server Key's name to server-cert.pem and server-key.pem !!!"
        print_warn " 2,You should put them to $OC_LC_DOC !!!"
        print_warn " 3,You should start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn " 4,You could use ' sudo ocpasswd -c $OC_LC_DOC/ocpasswd username ' to add users."
        print_warn " 5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo -e "\033[41;37m Your username is \033[0m" "$username"
        echo -e "\033[41;37m Your password is \033[0m" "$password"
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "y" ]; then
        print_warn " 1,You should change your Server Certificate and Server Key's name to server-cert.pem and server-key.pem !!!"
        print_warn " 2,You should change your Certificate Authority Certificates and Certificate Authority Key's  name to ca-cert.pem and ca-key.pem!!!"
        print_warn " 3,You should put server-cert.pem server-key.pem and ca-cert.pem to $OC_LC_DOC !!!"
        print_warn " 4,You should put ca-cert.pem and ca-key.pem to $OC_LC_DOC/CAforOC !!!"
        print_warn " 5,You should use ' bash `basename $0` gc ' to get a client cert !!!"
        print_warn " 6,You could start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn " 7,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
    else
        print_warn "Ocserv start failure,ocserv is offline!"	
    fi
}

function get_new_userca {
    if [ ! -f /usr/sbin/ocserv ]; then
        die "Ocserv NOT Found !!!"
    fi
    if [ ! -f $OC_LC_DOC/CAforOC/ca-cert.pem ] || [ ! -f $OC_LC_DOC/CAforOC/ca-key.pem ]; then
        die "ca-cert.pem or ca-key.pem NOT Found !!!"
    fi
    ca_login="y"
    self_signed_ca="y"
    add_a_user
    press_any_key
    ca_login_ocserv
    clear
    echo -e "\033[41;37m Your p12-cert's password is \033[0m" "$password"
    print_warn " You could get user-${name_user_ca}.p12 from /root."
    print_warn " You should import the certificate to your device at first."
}

function revoke_userca {
    if [ ! -f /usr/sbin/ocserv ]
    then
        die "Ocserv NOT Found !!!"
    fi
    if [ ! -f $OC_LC_DOC/CAforOC/ca-cert.pem ] || [ ! -f $OC_LC_DOC/CAforOC/ca-key.pem ]; then
        die "ca-key.pem or ca-cert.pem NOT Found !!!"
    fi
#get info
    cd $OC_LC_DOC/CAforOC
    clear
    print_xxxx
    print_info "The following is the user list..."
    echo
    ls -F|grep /|grep user|cut -d/ -f1
    print_xxxx
    print_info "Which user do you want to revoke?"
    echo
	read -p "Which: " -e -i user- revoke_ca
    if [ ! -f $OC_LC_DOC/CAforOC/$revoke_ca/$revoke_ca-cert.pem ]
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
    /etc/init.d/ocserv restart
    clear
    print_info "${revoke_ca} was revoked."
    echo    
}

function reinstall_ocserv {
    stop_ocserv
    rm -rf $OC_LC_DOC
    rm -rf /etc/dbus-1/system.d/org.infradead.ocserv.conf
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    install_OpenConnect_VPN_server
}

function help_ocservauto {
    print_xxxx
    print_info "######################## Parameter Description ####################################"
    echo
    print_info " install ------------------------- Install ocserv for Debian 7+"
    echo
    print_info " fastmode or fm ------------------ Rapid installation for ocserv through $CONFIG_PATH_VARS"
    echo
    print_info " getuserca or gc ----------------- Get a new client certificate"
    echo
    print_info " revokeuserca or rc -------------- Revoke a client certificate"
    echo
    print_info " reinstall or ri ----------------- Reinstall or upgrade your ocserv"
    echo
    print_info " help or h ----------------------- Show this description"
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

#vars 
#fastmode vars 脚本参数 可以保存配置下次快速部署
CONFIG_PATH_VARS="/root/ocservauto_vars"
OC_CONF_NET_DOC="https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto"
OC_LC_DOC="/etc/ocserv"
OC_LC_FILE="$OC_LC_DOC/ocserv.conf"

#Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_OpenConnect_VPN_server
    ;;
fastmode | fm)
    fast_install="y"
    . $CONFIG_PATH_VARS
    install_OpenConnect_VPN_server
    ;;
getuserca | gc)
    get_new_userca
    ;;
revokeuserca | rc)
    revoke_userca
    ;;
reinstall | ri)
    reinstall_ocserv
    ;;
help | h)
    help_ocservauto
    ;;
*)
    clear
    print_warn "Arguments error! [ ${action} ]"
    print_warn "Usage:  bash `basename $0` {install|fm|gc|rc|ri|h}"
    help_ocservauto
    ;;
esac
