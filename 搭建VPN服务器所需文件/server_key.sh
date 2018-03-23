#!/bin/bash
if [ $1 ];	then
	CN=$1
	echo "generating keys for $CN ..."
else
	echo "usage:\n sh server_key.sh YOUR EXACT HOST NAME or SERVER IP\n Run this script in directory to store your keys"
	exit 1
fi

mkdir -p private && mkdir -p cacerts && mkdir -p certs

ipsec pki --gen --type rsa --size 4096 --outform pem > private/strongswanKey.pem
ipsec pki --self --ca --lifetime 3650 --in private/strongswanKey.pem --type rsa --dn "C=CH, O=strongSwan, CN=$CN" --outform pem > cacerts/strongswanCert.pem
echo 'CA certs at cacerts/strongswanCert.pem\n'
ipsec pki --print --in cacerts/strongswanCert.pem

sleep 1
echo "\ngenerating server keys ..."
ipsec pki --gen --type rsa --size 2048 --outform pem > private/vpnHostKey.pem
ipsec pki --pub --in private/vpnHostKey.pem --type rsa | \
	ipsec pki --issue --lifetime 730 \
	--cacert cacerts/strongswanCert.pem \
	--cakey private/strongswanKey.pem \
	--dn "C=CH, O=strongSwan, CN=$CN" \
	--san $CN \
	--flag serverAuth --flag ikeIntermediate \
	--outform pem > certs/vpnHostCert.pem
echo "vpn server cert at certs/vpnHostCert.pem\n"
ipsec pki --print --in certs/vpnHostCert.pem