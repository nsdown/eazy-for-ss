#!/bin/bash
# delete an existing VPN

if [ -z "$1" ]; then
	echo "Usage: $0 <vpn-user-name>"
	exit 1
fi
if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid VPN user name"
    exit 1
fi
if [ `whoami` != "root" ]; then
	echo "You should be root to run this!"
	exit 1
fi

pushd /etc/openvpn/easy-rsa/2.0 || exit 1
. ./vars || exit 2
echo $KEY_DIR
openssl ca -config $KEY_CONFIG -revoke $KEY_DIR/$1.crt || exit 3
openssl ca -config $KEY_CONFIG -gencrl -out $KEY_DIR/crl.pem || exit 4
popd

echo "Certificate revoked. Removing it from archives..."
rm -f /etc/openvpn/easy-rsa/2.0/keys/$1.*
rm -f /etc/openvpn/keys/$1.*
rm -f /srv/vpn/ovpn-users/$1.tar.gz
[ -f "$1.tar.gz" ] && rm -f $1.tar.gz

echo "Re-generating ipsec secrets..."
$(dirname $0)/make-ipsec-secrets.sh
