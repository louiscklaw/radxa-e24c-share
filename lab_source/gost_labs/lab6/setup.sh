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

ip netns exec ns1 ip link add veth4 type veth peer name veth2 netns ns2
ip netns exec ns1 ip addr add 10.0.20.3/24 dev veth4
ip netns exec ns1 ip link set veth4 up

ip netns exec ns2 ip addr add 10.0.20.2/24 dev veth3
ip netns exec ns2 ip link set veth3 up

ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip route add default via 10.0.20.1 dev veth3

ip netns exec ns1 ip rule add fwmark 1 lookup 100
ip netns exec ns1 ip route add local default dev lo table 100

#
# 10.0.20.3:12345 , host running gost
# 10.0.20.0/24 , host network
#
ip netns exec ns1 iptables -t nat -N GOST
# 忽略局域网流量，请根据实际网络环境进行调整
ip netns exec ns1 iptables -t nat -A GOST -d 10.0.20.0/24 -j RETURN
# 忽略出口流量
ip netns exec ns1 iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN
# 重定向TCP流量到12345端口
ip netns exec ns1 iptables -t nat -A GOST -p tcp -j DNAT --to-destination 10.0.20.3:12345
# 拦截局域网流量
ip netns exec ns1 iptables -t nat -A PREROUTING -p tcp -j GOST
# 拦截本机流量
ip netns exec ns1 iptables -t nat -A OUTPUT -p tcp -j GOST
