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
#sources must '.' not 'bash'
#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
#default path 如果为空 则定为/temp_vars
    CONFIG_PATH_VARS=${CONFIG_PATH_VARS:-$(Get_shell_path)/temp_vars}
#rewrite $ok
    if [  -f ${CONFIG_PATH_VARS} ] ; then
        New_temp_default_var=`cat $CONFIG_PATH_VARS | grep "export $Temp_var_name=" | cut -d "'" -f 2`
        Temp_default_var=${New_temp_default_var:-$Temp_default_var}
#"变量替换有效 '变量不替换
        sed -i "/export $Temp_var_name=/d" $CONFIG_PATH_VARS
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
    echo "export $Temp_var_name='$Temp_var'" >> $CONFIG_PATH_VARS
    . $CONFIG_PATH_VARS
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
    fi
}
#$1位随机文本 去除容易认混单字
function get_random_word_no_mistake(){
    str_no_mistake=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c $1`
    echo $str_no_mistake
}
#shell path 获取当前脚本路径
function Get_shell_path {
    Now_work_path=`pwd`
    cd `dirname $0`
    This_shell_path=`pwd`
    cd $Now_work_path
    echo $This_shell_path
}
