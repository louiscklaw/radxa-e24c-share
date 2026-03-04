#!/usr/bin/env sh


ip netns delete ns1
ip netns delete ns2

set -ex

ip netns add ns1

ip link add dev veth0 type veth peer name veth1 netns ns1
ip addr add 10.0.10.1/24 dev veth0
ip link set dev veth0 up
ip -n ns1 addr add 10.0.10.2/24 dev veth1
ip -n ns1 link set dev lo up
ip -n ns1 link set dev veth1 up

ip netns add ns2
ip netns exec ns1 ip link add veth2 type veth peer name veth3 netns ns2
ip netns exec ns1 ip addr add 10.0.20.1/24 dev veth2
ip netns exec ns1 ip link set veth2 up
ip netns exec ns2 ip addr add 10.0.20.2/24 dev veth3
ip netns exec ns2 ip link set veth3 up
ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip route add default via 10.0.20.1 dev veth3

ip netns exec ns1 ip rule add fwmark 1 lookup 100
ip netns exec ns1 ip route add local default dev lo table 100

ip netns exec ns1 iptables -t mangle -N DIVERT
ip netns exec ns1 iptables -t mangle -A DIVERT -j MARK --set-mark 1
ip netns exec ns1 iptables -t mangle -A DIVERT -j ACCEPT
ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

ip netns exec ns1 iptables -t mangle -N GOST
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 255.255.255.255/32 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345
ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp -j GOST

# -----

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

cp /labs/lab8/dnsmasq.conf /etc/dnsmasq.conf

cp /labs/lab8/proxy-domains.conf /etc/dnsmasq.d/proxy-domains.conf



ip netns exec ns1 ipset create antigravity_proxy hash:ip timeout 300 -exist


echo "done"
