#!/bin/bash

# Please comment out the following line before executing
#exit 1

cd /etc/openvpn/easy-rsa/2.0/keys
ls *.crt | while read f; do

subject=$(openssl x509 -in $f -text -noout | grep Subject | grep emailAddress)
name=$(echo $subject | sed -rn 's/^.*O=(.+),.*/\1/p')
email=$(echo $subject | sed -rn 's/^.*emailAddress=([^ ]+).*$/\1/p')

[ "$email" = "lug@ustc.edu.cn" ] && continue
[ "$email" = "vpn@lug.ustc.edu.cn" ] && continue
echo "$name <$email>"

sendmail -F "USTC LUG VPN" -f "vpn@lug.ustc.edu.cn" $email <<EOF
Subject: LUG VPN is alive again after one day's downtime
To: "$name" <$email>

Hello,

Due to a file system corruption at 02:00 AM yesterday (2014-12-18), the LUG VPN server (co-located with blog.ustc.edu.cn) is down for maintainence. Now we are still investigating the problem. Sorry for the inconvenience this service downtime has brought to you in the past 24 hours, which is the longest downtime throughout LUG VPN history. The good news is, because many of us (including you) are in great need of this VPN service, we decide to recover it first.

To isolate LUG VPN from other services, we have enabled a new server for it. The domain name vpn.lug.ustc.edu.cn is resolved to the new VPN server. The old server (202.141.160.99, 202.141.176.99) would no longer run the VPN service. If you have old VPN config files, please replace "202.141.160.99" with "vpn.lug.ustc.edu.cn".

For more information, see https://vpn.lug.ustc.edu.cn/

Enjoy LUG VPN!
EOF

done
