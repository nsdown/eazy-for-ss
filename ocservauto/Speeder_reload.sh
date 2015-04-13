#!/bin/bash
wanif=`ip a|awk '{print $NF}'|grep vpns|sed ':a;N;s/\n/ /;ba;'`
[ "$wanif" = "" ] || wanif=" $wanif"
gwif=`ip route show|sed -n 's/^default.* dev \([^ ]*\).*/\1/p'`
sed -i "s/^accif=.*/accif=\"${gwif}${wanif}\"/" /serverspeeder/etc/config
sleep 1
/serverspeeder/bin/serverSpeeder.sh reload
