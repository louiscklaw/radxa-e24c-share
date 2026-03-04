#!/usr/bin/env sh
# lab9

# without `ns` means geographically restricted network, currently local machine
# ns1 acts as an openwrt router
# ns2 acts as client
# ns3 acts without restriction network

ip netns delete ns1
ip netns delete ns2
ip netns delete ns3

set -ex

# setup network topology

ip netns add ns1

ip link add dev veth0 type veth peer name veth1 netns ns1
ip addr add 10.0.10.1/24 dev veth0
ip link set dev veth0 up
ip -n ns1 addr add 10.0.10.2/24 dev veth1
ip -n ns1 link set dev lo up
ip -n ns1 link set dev veth1 up

ip netns add ns2
# ns2 to ns1
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

# ns3 -> ns1
ip netns add ns3
ip netns exec ns3 ip link add veth5 type veth peer name veth6 netns ns1
ip netns exec ns3 ip addr add 10.0.40.2/24 dev veth5
ip netns exec ns3 ip link set veth5 up
ip netns exec ns3 ip link set lo up
ip netns exec ns3 ip route add default via 10.0.40.1 dev veth5

ip netns exec ns1 ip addr add 10.0.40.1/24 dev veth6
ip netns exec ns1 ip link set veth6 up

#
# network topology setup done
#

# ----- configuration under test

# ip netns exec ns3 ping 10.0.40.2
# ip netns exec ns3 ip route

ip netns exec ns1 ipset create antigravity_proxy hash:ip timeout 300 -exist
ip netns exec ns1 ipset add antigravity_proxy 10.0.10.1
ip netns exec ns1 ipset list antigravity_proxy

#
# 10.0.20.3:8080 , host running gost -> http proxy
# 10.0.20.0/24 , host network
#
ip netns exec ns1 iptables -t nat -N GOST
# 忽略局域网流量，请根据实际网络环境进行调整
ip netns exec ns1 iptables -t nat -A GOST -d 10.0.20.0/24 -j RETURN
# 忽略出口流量
ip netns exec ns1 iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN
# 重定向TCP流量到 8080 端口
ip netns exec ns1 iptables -t nat -A GOST -p tcp -j DNAT --to-destination 10.0.20.3:8080
# 拦截局域网流量
ip netns exec ns1 iptables -t nat -A PREROUTING -p tcp  -m set --match-set antigravity_proxy dst -j GOST
# 拦截本机流量
ip netns exec ns1 iptables -t nat -A OUTPUT -p tcp -j GOST

# ns1, openwrt router, enable NAT for ns2(client) browse ns3(e.g. google.com) web page
ip netns exec ns1 sysctl -w net.ipv4.ip_forward=1
ip netns exec ns1 iptables -t nat -A POSTROUTING -o veth35 -j MASQUERADE

# ip netns exec ns1 iptables -t nat -L -n -v

# -----

echo "done"

exit 0

#
# ip netns exec ns3 ping 10.0.40.1
#