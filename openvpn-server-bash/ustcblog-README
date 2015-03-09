Special concerns for blog.ustc.edu.cn OpenVPN proxy
---------------------------------------------------

USTC Blog OpenVPN uses IP-IP tunnel to improve speed to several other ISPs.
Since routing is before SNAT, output interface has been selected. In POSTROUTING we should set different source IPs for different output interfaces.

Instead of the original rule, OpenVPN on blog.ustc.edu.cn should use the following rules:

iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o tunipip -j SNAT --to 10.141.160.99
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o tunipip2 -j SNAT --to 10.38.160.99
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j SNAT --to 202.141.160.99

To delete the original rule:

iptables -t nat -D POSTROUTING -s 10.8.0.0/16 -j SNAT --to 202.141.160.99
