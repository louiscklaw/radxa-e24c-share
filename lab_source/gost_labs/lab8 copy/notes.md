# Playground
通过网络命名空间可以在单机上构建测试环境而不影响正常的网络设置。
这里用

，默认命名空间模拟目标主机。

ns1模拟网关
ns2模拟客户机

新建网络命名空间ns1，通过 veth0(10.0.10.1/24) 和 veth1(10.0.10.2/24) 与默认命名空间互连

ns1, veth0, 10.0.10.1/24
ns1, veth1, 10.0.10.2/24

sudo su

ip netns add ns1
ip link add dev veth0 type veth peer name veth1 netns ns1
ip addr add 10.0.10.1/24 dev veth0
ip link set dev veth0 up
ip -n ns1 addr add 10.0.10.2/24 dev veth1
ip -n ns1 link set dev lo up
ip -n ns1 link set dev veth1 up


新建网络命名空间ns2，
通过 veth2(10.0.20.1/24)和veth3(10.0.20.2/24)让命名空间ns2与ns1互连，命名空间ns2把 ns1 作为网关

ns2, veth2, 10.0.20.1/24
ns2, veth3, 10.0.20.2/24

ip netns add ns2
ip netns exec ns1 ip link add veth2 type veth peer name veth3 netns ns2
ip netns exec ns1 ip addr add 10.0.20.1/24 dev veth2
ip netns exec ns1 ip link set veth2 up

ip netns exec ns2 ip addr add 10.0.20.2/24 dev veth3
ip netns exec ns2 ip link set veth3 up
ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip route add default via 10.0.20.1 dev veth3

在命名空间ns1中配置路由和iptables规则

ip netns exec ns1 ip rule add fwmark 1 lookup 100
ip netns exec ns1 ip route add local default dev lo table 100

# TCP
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

# UDP
ip netns exec ns1 iptables -t mangle -A GOST -p udp -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p udp -d 255.255.255.255/32 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345
ip netns exec ns1 iptables -t mangle -A PREROUTING -p udp -j GOST


在默认命名空间运行relay代理服务

gost -L relay://:8420
在命名空间ns1中运行GOST透明代理(TCP/UDP)，并通过默认命名空间的relay代理服务中转


ip netns exec ns1 gost -L "red://:12345?tproxy=true" -L "redu://:12345?ttl=30s" -F "relay://10.0.10.1:8420?so_mark=100"

在默认命名空间中运行iperf3服务


iperf3 -s

在命名空间ns2中执行iperf测试


# TCP
ip netns exec ns2 iperf3 -c 10.0.10.1

# UDP
ip netns exec ns2 iperf3 -c 10.0.10.1 -u

# 清理
ip netns delete ns1
ip netns delete ns2


```bash
sudo su

# should be root to create ns
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


# default ns, leave to listen all for easy troubleshooting
gost -L http://user:pass@:8080 &
iperf3 -s &
python -m http.server 8000 &

# ns1
ip netns exec ns1 gost -L "red://10.0.20.1:12345?tproxy=true" -F "http://user:pass@10.0.10.1:8080?so_mark=100"

# ns2
ip netns exec ns2 iperf3 -c 10.0.10.1
ip netns exec ns2 curl 10.0.10.1:8000

```