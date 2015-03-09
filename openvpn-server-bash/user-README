LUG@USTC OpenVPN Usage
======================

For Windows Users
-----------------

1. Download and install OpenVPN.
- 64 bit, Windows Vista/7/8: https://vpn.lug.ustc.edu.cn/downloads/openvpn-install-2.3.5-I601-x86_64.exe
- 32 bit, Windows Vista/7/8: https://vpn.lug.ustc.edu.cn/downloads/openvpn-install-2.3.5-I601-i686.exe
- 64 bit, Windows XP:        https://vpn.lug.ustc.edu.cn/downloads/openvpn-install-2.3.5-I001-x86_64.exe
- 32 bit, Windows XP:        https://vpn.lug.ustc.edu.cn/downloads/openvpn-install-2.3.5-I001-i686.exe

2. Extract this tarball to a temporary folder.

3. Copy the extracted files to C:\Program Files\OpenVPN\config\
If you are in Windows Vista/7/8 and did not find the above dir, try C:\Program Files (x86)\OpenVPN\config\
Note: You need administrator privilege to copy these files.

4. Run "OpenVPN GUI" application as Administrator (right click, run as administrator)

5. Double click OpenVPN icon on system tray, and you will be connected.


For Linux Users
---------------

1. Install OpenVPN. For Ubuntu/Debian users, you can "apt-get install openvpn".

2. Extract this tarball to /etc/openvpn/
You need root privilege to do this, and you can typically do it with "sudo tar -C /etc/openvpn/ -xvf <yourname>.tar.gz"

3. mv /etc/openvpn/${yourname}.ovpn /etc/openvpn/${yourname}.conf

4. service openvpn restart

(This step is courtesy of stephenpcg)

Note: If you cannot connect to VPN, run "cd /etc/openvpn/; sudo openvpn --config ${yourname}.conf" to debug.


Contact
-------

Should you have any problem or suggestion, please see FAQ: https://vpn.lug.ustc.edu.cn/ or email vpn@lug.ustc.edu.cn

You are welcomed to regularly check our news site https://servers.blog.ustc.edu.cn/index.php/category/vpn/ 
