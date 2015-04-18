##What
These are pdnsd's profiles.You cloud use these configurations to build a public dns server. 
##How
Well,Just need to overwrite the old one.
##Additional information
About China's domains, we could get newer info from

https://github.com/felixonmars/dnsmasq-china-list

And command
```shell
wget -qO- http://git.io/jkgU --no-check-certificate|grep -v ^#|cut -d/ -f2|sed s/^/./ > chinadomains
```
At last, del old info and add the new to pdnsd.conf.
```shell
sed -i '/^\..*/d' pdnsd.conf
sed -i '/include=/ r chinadomains' pdnsd.conf
```
