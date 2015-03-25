##What
These are pdnsd's profiles.You cloud use these configurations to build a public dns server. 
##How
Well,Just need to overwrite the old one.
##Additional information
About China's domains, we could get from
https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf

And command
```shell
wget -qO- http://git.io/jkgU --no-check-certificate|grep -v ^#|cut -d/ -f2|sed s/^/./ > chinadomains
```
At last, add it to pdnsd.conf.
