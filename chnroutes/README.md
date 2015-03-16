#WIKI
https://github.com/fivesheep/chnroutes/wiki
===========
#EXTRA
脚本增加了对ocserv(>=0.9.2)的支持，在编译安装时建议将路由规则最大数目修改到6000

如下使用

```shell
python chnroutes.py -p ocserv
```

然后在当前目录下出现routes.conf，把内容追加到ocserv.conf中即可。

```shell
cat routes.conf >> /etc/ocserv/ocserv.conf
```

去除

```shell
sed -i '/^no-route/d' /etc/ocserv/ocserv.conf
```
