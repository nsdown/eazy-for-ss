#!/bin/bash

TMPFILE=$(mktemp)
chmod 700 $TMPFILE
cat /etc/ipsec.secrets.head >>$TMPFILE

cd /etc/openvpn/easy-rsa/2.0/keys
linecount=$(ls *.crt | while read f; do

username=${f%.crt}
[ -z "$username" ] && continue

subject=$(openssl x509 -in $f -text -noout 2>/dev/null | grep Subject | grep emailAddress)
name=$(echo $subject | sed -rn 's/^.*O=(.+),.*/\1/p')
email=$(echo $subject | sed -rn 's/^.*emailAddress=([^ ]+).*$/\1/p')

[ -z "$email" ] && continue
[ "$email" = "lug@ustc.edu.cn" ] && continue
[ "$email" = "vpn@lug.ustc.edu.cn" ] && continue

echo "$name <$email>"
echo "'$email' : EAP \"$(echo "$email" | openssl sha1 -sign $username.key -sha1 | head -c 6 | base64)\"" >>$TMPFILE

done | wc -l)

echo "Found $linecount users in total."
mv $TMPFILE /etc/ipsec.secrets

ipsec rereadsecrets
