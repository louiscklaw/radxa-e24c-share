#!/usr/bin/env sh

set -ex

# Remove its resolv.conf
rm /etc/resolv.conf

# Point to our dnsmasq (which we'll set up next)
echo "nameserver 127.0.0.1" | tee /etc/resolv.conf

# Make it immutable to prevent automatic changes
chattr +i /etc/resolv.conf

echo "recreate resolv.conf done"

exit 0
