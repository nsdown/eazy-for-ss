#!/bin/bash

cd $(dirname $0)

name=$1
student_id=$2
email=$3

FN=$(echo $email | sed 's/@.*//')
[ -z "$FN" ] && exit 1

function create_vpn() {
    pushd $SCRIPT_DIR >/dev/null || send_failure_email "SCRIPT_DIR $SCRIPT_DIR does not exist"
    . ./vars || send_failure_email "environment variable file does not exist"
    BATCH="-batch"
    OPENSSL="openssl"
    KEY_EXPIRE="3650"
    NODES_REQ="-nodes"
    $OPENSSL req $BATCH -days $KEY_EXPIRE $NODES_REQ -new -newkey rsa:$KEY_SIZE \
    	        -keyout "$KEY_DIR/$FN.key" -out "$KEY_DIR/$FN.csr" $REQ_EXT -config "$KEY_CONFIG" \
                -subj "/C=CN/ST=Anhui/L=Hefei/O=$name/CN=$student_id/emailAddress=$email" || send_failure_email "generating key"
    $OPENSSL ca $BATCH -days $KEY_EXPIRE -out "$KEY_DIR/$FN.crt" \
    	        -in "$KEY_DIR/$FN.csr" $CA_EXT -md sha1 -config "$KEY_CONFIG" || send_failure_email "signing certificate"
    chmod 600 $KEY_DIR/$FN.key || send_failure_email "wrong path for generated key"
    rm -f $KEY_DIR/$FN.csr
    popd >/dev/null ## back to $(dirname $0)
}

function create_tarball() {
    pushd $SCRIPT_DIR >/dev/null || send_failure_email "SCRIPT_DIR $SCRIPT_DIR does not exist"
    TMPDIR=/tmp/openvpn/$FN
    mkdir -p $TMPDIR
    cp -a $KEY_DIR/$FN.* $TMPDIR || send_failure_email "copy keys"
    cp -a $VPN_KEYDIR/ca.crt $TMPDIR || send_failure_email "copy CA cert"
    popd >/dev/null ## back to $(dirname $0)
    
    sed "s/clientname/$FN/g" client.conf > $TMPDIR/$FN.conf || send_failure_email "generate openvpn config"
    mv $TMPDIR/$FN.conf $TMPDIR/$FN.ovpn # for Windows users
    cp user-README $TMPDIR/LUG-VPN-README.txt || send_failure_email "copy LUG-VPN-README.txt"
    
    tar -C $TMPDIR -czvf $VPN_ARCHIVE/$FN.tar.gz . || send_failure_email "generate tarball"
    rm -rf $TMPDIR
    
    echo "Rebuilding IPSec secrets file..."
    ./make-ipsec-secrets.sh || send_failure_email "rebuild ipsec secrets"
}

export EMAIL="USTC LUG VPN <vpn@lug.ustc.edu.cn>"

function send_email() {
    mutt -e 'set assumed_charset="utf-8"' -s "USTC LUG VPN Account" -a "$VPN_ARCHIVE/$FN.tar.gz" -- $email <<EOF
$name 您好！

[中文]

欢迎使用 LUG VPN 服务。本邮件是由于您申请了 LUG VPN，如果您没有申请，请忽略此邮件。

请您解压附件压缩包，按照 LUG-VPN-README.txt 的指南安装。
FAQ: https://vpn.lug.ustc.edu.cn/ 
如有问题欢迎反馈。

[ENGLISH]

Welcome to LUG VPN Service. This email is for that you have applied for LUG VPN. If you didn't make the request, you can ignore this email.

Please untar the attached tarball and see LUG-VPN-README.txt for installation instructions.
FAQ: https://vpn.lug.ustc.edu.cn/
Should you have any problem please contact us.

--
Enjoy LUG VPN!
EOF
}

function send_failure_email() {
    mutt -e 'set assumed_charset="utf-8"' -s "USTC LUG VPN failed to generate" -b "servmon@blog.ustc.edu.cn" -a "$VPN_ARCHIVE/$FN.tar.gz" -- $email <<EOF
$name 您好！

抱歉，系统出了点问题，您的 VPN key 未能成功生成，系统将把这个问题报告给技术人员。

Sorry, there seems to be some problem with our system and your VPN key was not generated successfully. This incident will be reported to technical staff.

Technical Info: $1
EOF
    exit 1
}

SCRIPT_DIR=/etc/openvpn/easy-rsa/2.0
KEY_DIR=$SCRIPT_DIR/keys
VPN_KEYDIR=/etc/openvpn/keys
VPN_ARCHIVE=/srv/vpn/ovpn-users
if [ -f "$VPN_ARCHIVE/$FN.tar.gz" ]; then
    create_tarball
    send_email
else
    create_vpn
    create_tarball
    send_email
fi
