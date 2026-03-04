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


exit 1

ip netns exec ns1 ipset create antigravity_proxy hash:ip timeout 300 -exist
ip netns exec ns1 iptables -t nat -F ANTIGRAVITY_PROXY 2>/dev/null
ip netns exec ns1 iptables -t nat -X ANTIGRAVITY_PROXY 2>/dev/null
ip netns exec ns1 iptables -t nat -N ANTIGRAVITY_PROXY

ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 0.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 10.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 169.254.0.0/16 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 172.16.0.0/12 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 192.168.0.0/16 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 224.0.0.0/4 -j RETURN
ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -d 240.0.0.0/4 -j RETURN


ip netns exec ns1 iptables -t nat -A ANTIGRAVITY_PROXY -p tcp -m set --match-set antigravity_proxy dst -j REDIRECT --to-ports 12345
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345


exit 1


