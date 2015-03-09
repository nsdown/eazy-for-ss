# OpenVPN Server Scripts

These scripts can be used to deploy a new OpenVPN server and add new clients on it.

## Usage

Run ```sudo ./install-server.sh``` to deploy on VPN server. Fill in the fields when prompted.

Run ```sudo ./create-vpn.sh <vpn-user-name>``` to create a new OpenVPN user.
A tarball containing config and keys will be created for the new user, and you can send the tarball to the VPN applicant.

## Dependencies

* OpenVPN 2.2 (OpenVPN 2.3 does not have easy-rsa bundled)
* iptables
* DNSmasq

## Forked From
https://git.ustclug.org/boj/openvpn-server.git
