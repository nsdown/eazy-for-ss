#!/bin/bash
OC_CONFIG="/etc/ocserv/ocserv.conf"
device=`sed -n 's/^device.*=[ \t]*//p' $OC_CONFIG`
wanif=`ip a|awk '{print $NF}'|grep $device|sed ':a;N;s/\n/ /;ba;'`
[ "$wanif" = "" ] || wanif=" $wanif"
gwif=`ip route show|sed -n 's/^default.* dev \([^ ]*\).*/\1/p'`
sed -i "s/^accif=.*/accif=\"${gwif}${wanif}\"/" /serverspeeder/etc/config
sleep 1
/serverspeeder/bin/serverSpeeder.sh reload
