#!/bin/bash
#######################################################
#debian 7                                             #
#RAM>=128M                                            #
#添加安全模块                                         #
###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################
#force-exit
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
#question mod 提问模板
#source must '.' not 'bash'
#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
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
#get random word 获取$1位随机文本
function get_random_word(){
    D_Num_Random="8"
    Num_Random=${1:-$D_Num_Random}
    str=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c $Num_Random`
    echo $str
}
###################################################################################################################
#core-function                                                                                                    #
###################################################################################################################
function Check_Required {
#check root
    [ $EUID -ne 0 ] && die 'Must be run by root user.'
    print_info "Root ok"
#debian-based only
    [ ! -f /etc/debian_version ] && die "Must be run on a Debian-based system."
    print_info "Debian-based ok"
#get IPv4 info
    get_info_from_net
    print_info "Get ip ok"
#install base-tools 
    print_info "Installing base-tools from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed dnsutils   
    print_info " Install base-tools ok"
}
function get_info_from_net(){
    IP=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $IP ]; then
        IP=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
    fi

}
function Add_dotdeb {
    cat /etc/apt/sources.list | grep -v '^#' | grep 'dotdeb' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if grep ^6. /etc/debian_version > /dev/null
        then
            echo "deb http://packages.dotdeb.org squeeze all" >> /etc/apt/sources.list
            echo "deb-src http://packages.dotdeb.org squeeze all" >> /etc/apt/sources.list
        else
            echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
            echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
        fi
        wget -q -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -
        apt-get update
    fi
}
function Get_config_SC {
    Default_Ask "Your domain for the web panel?" "$IP" "My_Domain"
    Default_Ask "Your username?" "$username" "username"
    Default_Ask "Your password?" "$password" "password"
    Default_Ask "Everyone's Start_Traffic?" "$Start_Traffic" "Start_Traffic"
    Default_Ask "Are there any other ss-manyuser servers?" "n" "Other_SS"
}
function Get_config_ONLYS {
    Default_Ask "Your domain for the web panel?" "$IP" "My_Domain"
    Default_Ask "Your username?" "$username" "username"
    Default_Ask "Your password?" "$password" "password"
    Default_Ask "Everyone's Start Traffic(G)?" "$Start_Traffic" "Start_Traffic"
    Other_SS="y"
}
function Get_config_ONLYC {
    Default_Ask "The manage server's global ip?" "127.0.0.1" "DB_BIND_IP"
    Default_Ask "The manage server's shadowsocks database password?" "12345678" "DB_SS_PW"
}
function Install_lnmp {
    invoke-rc.d sendmail stop > /dev/null  2>&1
    apt-get -q -y remove --purge sendmail* apache2* portmap samba* nscd bind9*
    apt-get -q -y autoremove
    apt-get -q -y autoclean
    apt-get -q -y clean
    apt-get upgrade -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q nginx-full php5-cli php5-fpm php5-gd php5-mysqlnd php5-curl mysql-server mysql-client
#Nginx
    cat > /etc/nginx/conf.d/nginx_Our_Private_Panel.conf <<'EOF'
server {
    listen 88;
    server_name Our_Private_Panel_Domain;
    root /var/www/Our_Private_Panel_Domain;
    index index.html index.htm index.php;
    client_max_body_size 32m;
    access_log  off;
    error_log  off;
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
        access_log off;
	}
    location / {
        index index.html index.php;
        try_files $uri $uri/ =404;
        if (-f $request_filename/index.html){
            rewrite (.*) $1/index.html break;
        }
        if (-f $request_filename/index.php){
            rewrite (.*) $1/index.php;
        }
        if (!-f $request_filename){
            rewrite (.*) /index.php;
        }
    }
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
    location ~ /\.ht {
        deny  all;
    }
}
EOF
    sed -i "s/Our_Private_Panel_Domain/$My_Domain/" /etc/nginx/conf.d/nginx_Our_Private_Panel.conf
    sed -i "s/listen 88/listen $Web_Listen_Port/" /etc/nginx/conf.d/nginx_Our_Private_Panel.conf
#Mysql
    /etc/init.d/mysql stop
    cat > /etc/mysql/conf.d/OurPrivatePanel.cnf <<'EOF'
[mysqld]
key_buffer = 8M
query_cache_size = 0
expire_logs_days        = 3
max_binlog_size         = 1M
performance_schema_max_table_instances = 16
table_definition_cache = 8
table_open_cache = 8
EOF
#监听外网地址
    [ "$Other_SS" = "y" ] && sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/my.cnf
    /etc/init.d/mysql start
    if [ ! -e ~/.my.cnf ]; then
    mysqladmin -u root password "$DB_ROOT_PW"
    cat > ~/.my.cnf <<END
[client]
user = root
password = $DB_ROOT_PW
END
	fi
    chmod 600 ~/.my.cnf    
    echo "mysql_ROOT_PW=$DB_ROOT_PW" >> /root/OPP.conf
    cd /root
    while [ ! -f shadowsocks.sql ]; do
        wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/Our-Private-Panel/shadowsocks.sql --no-check-certificate
    done
    Panel_Admin_Passwd=`echo -n "$password"|md5sum|cut -d ' ' -f1`
    sed -i "s/25d55ad283aa400af464c76d713c07ad/$Panel_Admin_Passwd/" shadowsocks.sql
    sed -i "s/Our_Private_Panel_Domain/$My_Domain/" shadowsocks.sql
    sed -i "s/Our_Private_Panel/$username/" shadowsocks.sql
    sed -i "s/My_Passwd/$(get_random_word 8)/" shadowsocks.sql
    mysqladmin create "shadowsocks"
    echo "GRANT ALL PRIVILEGES ON \`shadowsocks\`.* TO \`shadowsocks\`@\`%\` IDENTIFIED BY '$DB_SS_PW';" | mysql
    mysql shadowsocks < ./shadowsocks.sql
    rm shadowsocks.sql
    echo "shadowsocks_DB_PW=$DB_SS_PW" >> /root/OPP.conf
}
function Set_sysctl_for_ss {
    /sbin/modprobe tcp_hybla > /dev/null 2>&1
    sysctl net.ipv4.tcp_available_congestion_control | grep 'hybla' > /dev/null 2>&1
    if [ $? -eq 0 ]; then 
        tcp_congestion_ss="hybla"
    else
        tcp_congestion_ss="cubic"
    fi
#sysctl file
    cat > /etc/sysctl.d/local_ss.conf<<EOF
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
#sysctl set
    sysctl -p /etc/sysctl.d/local_ss.conf
}
function Install_shadowsocks_manyuser {
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q build-essential autoconf libtool libssl-dev git python-pip python-m2crypto supervisor
    pip install cymysql
    cd /root
    git clone -b manyuser https://github.com/mengskysama/shadowsocks.git
    cd shadowsocks/shadowsocks
    echo "MANAGE_PASS = $DB_PASS" >> /root/OPP.conf
    echo "MANAGE_PORT = $DB_PORT" >> /root/OPP.conf
    echo "MANAGE_BIND_IP = $DB_BIND_IP" >> /root/OPP.conf
    cat > Config.py <<EOF
MYSQL_HOST = '$DB_BIND_IP'
MYSQL_PORT = 3306
MYSQL_USER = 'shadowsocks'
MYSQL_PASS = '$DB_SS_PW'
MYSQL_DB = 'shadowsocks'

MANAGE_PASS = '$DB_PASS'
#if you want manage in other server you should set this value to global ip
MANAGE_BIND_IP = '127.0.0.1'
#make sure this port is idle
MANAGE_PORT = $DB_PORT
EOF
#修改默认加密为128 修改加密方式必须从json中修改
    sed -i 's/\(.*meth.*:\).*/\1"aes-128-cfb"/' config.json
    sed -i 's/\(.*timeout.*:\).*/\160,/' config.json
    mkdir -p /etc/shadowsocks-manyuser
    mv * /etc/shadowsocks-manyuser
    cd /root
    rm -rf shadowsocks
#增加web-ss用户并且禁止登录
    useradd web-ss
    /bin/false web-ss
    cat > /etc/supervisor/conf.d/shadowsocks-manyuser.conf<<'EOF'
[program:shadowsocks-manyuser]
command=python /etc/shadowsocks-manyuser/server.py -c /etc/shadowsocks-manyuser/config.json
autostart=true
autorestart=true
user=web-ss
EOF
    echo 'ulimit -n 51200' >>  /etc/default/supervisor
}
function Install_ss_panel {
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git
    cd /root
    git clone -b master https://github.com/fanyueciyuan/ss-panel.git
    cd ss-panel/lib
    mv config-simple.php config.php
    sed -i "s/password/$DB_SS_PW/" config.php
    sed -i "s/togb\*30/togb\*$Start_Traffic/" config.php
    sed -i "s/panel\.com/${My_Domain}:${Web_Listen_Port}/" config.php
    cd ..
    rm -rf sql && rm -rf .git*
    mkdir -p /var/www/$My_Domain
    mv * /var/www/$My_Domain
    cd ..
    rm -rf ss-panel
    cd /var/www/$My_Domain
    chown -R www-data.www-data /var/www/$My_Domain
    Safe_code=$(get_random_word 12)
    mkdir tools${Safe_code}
    cd tools
    sed -i "s|= '1'|= '${Traffic_Zero_Day}'|" reset_transfer.php
    mv * ../tools${Safe_code}
    cd ..
    rm -r tools
    chown -R root.root tools${Safe_code}
    chmod -R 700 tools${Safe_code}
    echo "1-2 1 1-31 * * root cd /var/www/$My_domain/tools${Safe_code} && /usr/bin/php -f cron.php" >> /etc/crontab
    cd /root
}
function Start_all {
    if [ "$Install_status" = "sc" -o "$Install_status" = "s" ]; then
        /etc/init.d/nginx stop
        /etc/init.d/nginx start
        /etc/init.d/mysql stop
        /etc/init.d/mysql start
    fi
    if [ "$Install_status" = "sc" -o "$Install_status" = "c" ]; then
        /etc/init.d/supervisor stop
        /etc/init.d/supervisor start
        supervisorctl reload
    fi
}
function Show_result {
    if [ "$Install_status" = "sc" -o "$Install_status" = "s" ]; then
        print_info "The admin and the first user's username is $username"
        print_info "The admin and the first user's password is $password"
        print_info "You cloud find your configuration file at /root/OPP.conf"
        print_info "Visit 'http://${My_Domain}:${Web_Listen_Port}/admin/' to manage Your Panel"
    else 
        print_info "The manage server's global ip is $DB_BIND_IP"
#        print_info "The manage server's ss-manage-port is $DB_PORT"
#        print_info "The manage server's ss-manage-pass is $DB_PASS"
        print_info "The manage server's shadowsocks database password is $DB_SS_PW"
    fi
    
}
function Install_Our_Private_Panel_SC {
    Check_Required
    Default_Vars
    Get_config_SC
#    Add_dotdeb
    Install_lnmp
    Set_sysctl_for_ss
    Install_shadowsocks_manyuser
    Install_ss_panel
    Start_all
    Show_result
}
function Install_Our_Private_Panel_ONLYS {
    Check_Required
    Default_Vars
    Get_config_ONLYS
#    Add_dotdeb
    Install_lnmp
    Install_ss_panel
    Start_all
    Show_result
}
function Install_Our_Private_Panel_ONLYC {
    Check_Required
    Default_Vars
    Get_config_ONLYC
    Set_sysctl_for_ss
    Install_shadowsocks_manyuser
    Start_all
    Show_result
}
function help_Our_Private_Panel {
 print_xxxx
    print_info "######################## Parameter Description ####################################"
    echo
    print_info " sc ----------- Install LNMP , ss-panel and shadowsocks-manyuser"
    echo
    print_info " s ------------ Only Install LNMP and ss-panel,As a database center "
    echo
    print_info " c ------------ Only Install shadowsocks-manyuser,Get info from the database center"
    echo
    print_info " help or h ---- Show this description"
    print_xxxx
}
###################################################################################################################
#default-vars                                                                                                     #
###################################################################################################################
function Default_Vars {
#数据库默认信息  
    DB_PASS="$(get_random_word 12)"
    DB_PORT="23333"
    DB_BIND_IP="127.0.0.1"
#数据库shadowsocks密码
    DB_SS_PW="$(get_random_word 12)"
#数据库root用户密码
    DB_ROOT_PW="$(get_random_word 12)"
#每位成员的初始可用流量，单位G；以及流量清零日1-31
    Traffic_Zero_Day="1"
    Start_Traffic="30"
#自己站点的域名或者IP
    My_Domain="$IP"
#网页监听端口
    Web_Listen_Port="88"
#管理员和第一位用户的用户名以及密码 ss的密码和端口请在面板中寻找
    username="$(get_random_word 8)"
    password="$(get_random_word 8)"
}
###################################################################################################################
#main                                                                                                             #
###################################################################################################################

action=$1
[  -z $1 ] && action=sc
case "$action" in
sc)
    Install_status="sc"
    Install_Our_Private_Panel_SC
    ;;
s)
    Install_status="s"
    Install_Our_Private_Panel_ONLYS
    ;;
c)
    Install_status="c"
    Install_Our_Private_Panel_ONLYC
    ;;
help | h)
    help_Our_Private_Panel
    ;;
*)
    print_warn "Arguments error! [ ${action} ]"
    print_warn "Usage:  bash `basename $0` {sc|s|c|h}"
    help_Our_Private_Panel
    ;;
esac

exit 0
