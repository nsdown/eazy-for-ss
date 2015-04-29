#!/bin/bash

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
#default path 如果为空 则定为脚本所在文件夹
    CONFIG_PATH_VARS=${CONFIG_PATH_VARS:-$(Get_shell_path)/temp_vars}
#rewrite $ok
    if [ -f ${CONFIG_PATH_VARS} ] ; then
        New_temp_default_var=`cat $CONFIG_PATH_VARS | grep "^$Temp_var_name=" | cut -d "'" -f 2`
        Temp_default_var=${New_temp_default_var:-$Temp_default_var}
    fi
#if yes or no 
    echo -e -n "\e[1;36m$Temp_question\e[0m""\033[31m(Default:$Temp_default_var): \033[0m"
    read Temp_var
    if [ "$Temp_default_var" = "y" ] || [ "$Temp_default_var" = "n" ] ; then
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
#fast mode
function fast_Default_Ask(){
    if [ "$fast_install" = "y" ] ; then
        CONFIG_PATH_VARS=${CONFIG_PATH_VARS:-$(Get_shell_path)/temp_vars}
        print_info "In the fast mode, $3 will be loaded from $CONFIG_PATH_VARS"
    else
        Default_Ask "$1" "$2" "$3"
        [ -f ${CONFIG_PATH_VARS} ] && sed -i "/^${Temp_var_name}=/d" $CONFIG_PATH_VARS
        echo $Temp_cmd >> $CONFIG_PATH_VARS
    fi
}
#$1位随机文本 去除容易认混单字
function get_random_word_no_mistake(){
    D_Num_Random="8"
    Num_Random=${1:-$D_Num_Random}
    str=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c $Num_Random`
    echo $str
}
#shell path 获取当前脚本路径
function Get_shell_path {
    Now_work_path=`pwd`
    cd `dirname $0`
    This_shell_path=`pwd`
    cd $Now_work_path
    echo $This_shell_path
}
#if !(Check_Tcp_Port "123"); then
#echo "tcp-port 123 is in use"
#fi
function Check_Tcp_Port(){
    All_Listen_Tcp_Port=`netstat -nalt|grep LISTEN|awk '{print $4}'|sed 's/.*://'|sort|uniq`
    Port=""
    for Port in $All_Listen_Tcp_Port
    do
        if [ "$1" = "$Port" ]; then
            return 1
        fi
    done
}
function Check_Udp_Port(){
    All_Udp_Port=`netstat -nalu|grep udp|awk '{print $4}'|sed 's/.*://'|sort|uniq`
    Port=""
    for Port in $All_Udp_Port
    do
        if [ "$1" = "$Port" ]; then
            return 1
        fi
    done
}
# Get the directory where this script is and set ROOT_DIR to that path. This
# allows script to be run from different directories but always act on the
# directory of the project (which is where this script is located).
ROOT_DIR="$(cd "$(dirname $0)"; pwd)";
