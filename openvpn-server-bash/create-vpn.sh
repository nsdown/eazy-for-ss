#!/bin/bash
# script to create a openvpn user

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
if [ -f "$1.tar.gz" ]; then
	echo "User $1 already exists in current directory!"
	exit 1
fi

pushd `dirname $0` >/dev/null
if [ ! -f "client.conf" ]; then
    echo "Client conf template file is missing"
    exit 1
fi

SCRIPTDIR=/etc/openvpn/easy-rsa/2.0/
if [ ! -d "$SCRIPTDIR" ]; then
    echo "$SCRIPTDIR not found"
    exit 1
fi
pushd $SCRIPTDIR >/dev/null

. ./vars
./build-key $1

KEYDIR=/etc/openvpn/keys
mkdir -p $KEYDIR
TMPDIR=/tmp/openvpn/$1
mkdir -p $TMPDIR
cp -a keys/$1.* $TMPDIR
cp -a $KEYDIR/ca.crt $TMPDIR
popd >/dev/null # back to script dir

sed "s/clientname/$1/g" client.conf > $TMPDIR/$1.conf
mv $TMPDIR/$1.conf $TMPDIR/$1.ovpn # for Windows users
cp user-README $TMPDIR/LUG-VPN-README.txt

popd >/dev/null # back to original dir
tar -C $TMPDIR -czvf $1.tar.gz .
rm -rf $TMPDIR

echo "Rebuilding IPSec secrets file..."
$(dirname $0)/make-ipsec-secrets.sh

echo "===== DONE ====="
echo "Config for new OpenVPN user is in $1.tar.gz"
