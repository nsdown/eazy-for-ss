##开启分组模式

这里分为两组all和route，一个帐号可以选择全局模式（all）或国内外分流模式（route）。

=====

###用户密码方式分组

在ocserv.conf文件中取消相应行的注释，并且修改为如下值

```
select-group = Client[route]
default-select-group = all
auto-select-group = false
config-per-group = /etc/ocserv/config-per-group/
```

需要注意的是，`select-group`这一项的值，Client是后面所讲的配置文件的`文件全名`，方括号里面的则是可以自定义的提示。

修改或者创建Client组的用户，下面的username是自定义的用户名

```shell
ocpasswd -c /etc/ocserv/ocpasswd  -g "Client" username
```

然后，创建放置分流组配置文件的文件夹

```shell
mkdir /etc/ocserv/config-per-group
```

写入国内外分流路由规则（规则可以自定，只要写入/etc/ocserv/config-per-group/Client 文件中即可）

我们可以参考来自 https://github.com/humiaozuzu/ocserv-build 的一份优化好的路由表来完成分流，可以通过下面命令来配置

```shell
wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/routerulers -O /etc/ocserv/config-per-group/Client
```

重启ocserv即可

```shell
service ocserv restart
```

====

###证书方式分组

在ocserv.conf文件中取消相应行的注释，并且修改为如下值

```
cert-group-oid = 2.5.4.11
select-group = Client[route]
default-select-group = all
auto-select-group = false
config-per-group = /etc/ocserv/config-per-group/
```

需要注意的是，`select-group` 这一行后面的值，是客户端证书的unit项目的值，方括号里面的则是可以自定义的提示。

然后，创建放置分流组配置文件的文件夹

```shell
mkdir /etc/ocserv/config-per-group
```

写入国内外分流路由规则（规则可以自定，只要写入/etc/ocserv/config-per-group/Client 文件中即可）

我们可以参考来自 https://github.com/humiaozuzu/ocserv-build 的一份优化好的路由表来完成分流，可以通过下面命令来配置

```shell
wget https://raw.githubusercontent.com/fanyueciyuan/eazy-for-ss/master/ocservauto/routerulers -O /etc/ocserv/config-per-group/Client
```

重启ocserv即可

```shell
service ocserv restart
```

需要注意的是，安卓anyconnect客户端证书分组可能会出现只走全局的BUG。

====
