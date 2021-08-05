#!/bin/bash

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

DEVICE=$1

. /tmp/cms.conf

strglobin "$IPADDR" '*:*:*' && ipv6=1

if [ "$ipv6" ] && ! str_starts "$IPADDR" "["; then
    IPADDR="[$IPADDR]"
fi

if [ "$ipv6" ] && ! str_starts "$GATEWAY" "["; then
    GATEWAY="[$GATEWAY]"
fi

if [ "$ipv6" ]; then
    # shellcheck disable=SC2153
    IFS="," read -r DNS1 DNS2 _ <<< "$DNS"
else
    IFS=":" read -r DNS1 DNS2 _ <<< "$DNS"
fi

{
    echo "ip=$IPADDR::$GATEWAY:$NETMASK:$HOSTNAME:$DEVICE:none:$MTU:$MACADDR"
    for i in $DNS1 $DNS2; do
        echo "nameserver=$i"
    done
} > /etc/cmdline.d/80-cms.conf

[ -e "/tmp/net.ifaces" ] && read -r IFACES < /tmp/net.ifaces
IFACES="$IFACES $DEVICE"
echo "$IFACES" >> /tmp/net.ifaces

if [ -x /usr/libexec/nm-initrd-generator ]; then
    type nm_generate_connections > /dev/null 2>&1 || . /lib/nm-lib.sh
    nm_generate_connections
else
    exec ifup "$DEVICE"
fi
