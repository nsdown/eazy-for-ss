#!/bin/bash

cd /etc/openvpn/easy-rsa/2.0/keys
ls *.crt | while read f; do

subject=$(openssl x509 -in $f -text -noout | grep Subject | grep emailAddress)
name=$(echo $subject | sed -rn 's/^.*O=(.+),.*/\1/p')
email=$(echo $subject | sed -rn 's/^.*emailAddress=([^ ]+).*$/\1/p')

[ "$email" = "lug@ustc.edu.cn" ] && continue
[ "$email" = "vpn@lug.ustc.edu.cn" ] && continue
echo "$name <$email>"

done
