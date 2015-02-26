cat > /usr/bin/checkvpn <<"END"
#!/bin/sh

if [ -f "/tmp/vpn_status_check.lock" ]
then
    exit 0
fi

selfip="\$(wget -q -O - ip.keithscode.com)"
vpnip="\$(resolveip vpn.myserver.com)"

if [ -z "\$(ifconfig | grep openconnect)" ]
then
    touch /tmp/vpn_status_check.lock
    echo WAN_VPN_RECONNECT at: > /tmp/vpn_status_reconnect.log
    date >> /tmp/vpn_status_reconnect.log

    ifdown openconnect
    sleep 10
    ifup openconnect
    sleep 30
    rm /tmp/vpn_status_check.lock
else
    if [ \$selfip = \$vpnip ];
    then
        date > /tmp/vpn_status_check.log
    else
        touch /tmp/vpn_status_check.lock
        echo WAN_VPN_RECONNECT at: >> /tmp/vpn_status_reconnect.log
        date >> /tmp/vpn_status_reconnect.log

        ifdown openconnect
        sleep 10
        ifup openconnect
        rm /tmp/vpn_status_check.lock
    fi
    date > /tmp/vpn_status_check.log
fi
END
chmod a+x /usr/bin/checkvpn
echo '*/5 * * * * /usr/bin/checkvpn' > /etc/crontabs/root
/etc/init.d/cron restart
