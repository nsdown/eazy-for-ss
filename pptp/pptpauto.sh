#!/bin/bash

###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################

#force-exit
function die {
    echo -e "\033[33mERROR: $1 \033[0m" > /dev/null 1>&2
    exit 1
}
#info echo
function print_xxxx {
    xXxX="#############################"
    echo
    echo "$xXxX$xXxX$xXxX$xXxX"
    echo
}
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
#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
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
    echo
    print_info "Your answer is : ${Temp_var}"
    echo
    print_xxxx
}
#Press any key to start
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
#get random word
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

###################################################################################################################
#main-function                                                                                                    #
###################################################################################################################

#setup
function setup_pptp {
#install pptp
    echo ""
    print_xxxx
    print_info "Downloading and Installing PPTP"
    print_xxxx
    apt-get update
    apt-get -y install pptpd gawk sed nano dnsutils
    echo
    print_xxxx
    print_info "Server Config"
    print_xxxx
#ms-dns
    echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options
    echo "ms-dns 8.8.4.4" >> /etc/ppp/pptpd-options
#distribute network ip
    echo "localip 10.1.0.1" >> /etc/pptpd.conf
    echo "remoteip 10.1.0.100-254" >> /etc/pptpd.conf
#adding new user
    echo "$u pptpd $p *" >> /etc/ppp/chap-secrets
#forwarding and iptables
    echo
    print_xxxx
    print_info "Forwarding IPv4 and Updating IPtables Routing"
    print_xxxx
#get files about forwarding and iptables
    wget -q --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/pptp/pptp-up.sh -O /etc/ppp/pptp-up.sh
    wget -q --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/pptp/pptp-down.sh -O /etc/ppp/pptp-down.sh
    chmod +x /etc/ppp/pptp-up.sh
    chmod +x /etc/ppp/pptp-down.sh
#add them to the pptpd script
    sed -i '/"Starting PPTP Daemon: "/a\. /etc/ppp/pptp-up.sh' /etc/init.d/pptpd
    sed -i '/"Stopping PPTP: "/a\. /etc/ppp/pptp-down.sh' /etc/init.d/pptpd
#restart pptp
    print_xxxx
    print_info "Restarting PoPToP..."
    print_xxxx
    sleep 2
    /etc/init.d/pptpd restart
#show result
    clear
    ps -ef | grep -v grep | grep -v ps | grep -i '/usr/sbin/pptpd' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_xxxx
        print_info "Server setup complete!"
        print_info "Connect to your VPS at $ip with these credentials:"
        print_warn "Username:$u 　　　 Password: $p"
        print_xxxx
    else
        die "PPTPD start failure,It is offline!"
    fi
}
#get a user
function creat_user {
    Default_Ask "Input your username" "$(get_random_word 3)" "u"
    Default_Ask "Input your password" "$(get_random_word 6)" "p"
    press_any_key
    if [ -f /etc/ppp/chap-secrets ] && [ -f /etc/init.d/pptpd ] ; then
        echo "$u pptpd $p *" >> /etc/ppp/chap-secrets
        clear
        print_xxxx
        print_info "Addtional user added!"
        print_info "Connect to your VPS at $ip with these credentials:"
        print_warn "Username:$u ##### Password: $p"
        print_xxxx
    fi
}

###################################################################################################################
#main                                                                                                             #
###################################################################################################################

clear
print_xxxx
echo "Interactive PoPToP Install Script for an debian VPS"
echo
echo "Make sure to contact your provider and have them enable"
echo "IPtables and ppp modules prior to setting up PoPToP."
echo "PPP can also be enabled from SolusVM."
echo
echo "You need to set up the server before creating more users."
echo "A separate user is required per connection or machine."
print_xxxx
print_xxxx
echo
print_info "Select on option:"
print_info "1) Set up new PoPToP server AND create one user"
print_info "2) Create additional users"
echo
print_xxxx

#vars
ip=$(wget -qO- ipv4.icanhazip.com)
if [ $? -ne 0 -o -z $ip ]; then
    ip=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
fi

#choice
read x
if test $x -eq 1; then
    creat_user
    setup_pptp
elif test $x -eq 2; then
    creat_user
else
    die "Invalid selection, quitting."
fi
