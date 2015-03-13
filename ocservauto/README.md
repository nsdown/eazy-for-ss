##SSLVPNauto-L For Debian

This script will let you setup your own ocserv on debian_7.

这是一枚适用于deibian_7的openconnect_server安装脚本。

============

##USAGE
```shell
apt-get update
apt-get install wget
wget http://git.io/p9r8 --no-check-certificate -O ocservauto.sh
bash ocservauto.sh
```

Profiles in /etc/ocserv/

When you change the profiles,restart the vpn server.
```shell
/etc/init.d/ocserv restart
```

============

##LICENCE
SSLVPNauto-L For Debian Copyright (C) liyangyijie@Gmail released under GNU GPLv2

SSLVPNauto-L Is Based On SSLVPNauto v0.1-A1

SSLVPNauto For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
