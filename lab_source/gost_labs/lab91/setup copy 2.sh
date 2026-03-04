#!/usr/bin/env sh
# lab9

# without `ns` means geographically restricted network, currently local machine
# ns1 acts as an openwrt router
# ns2 acts as client
# ns3 acts without restriction network

ip netns delete ns1
ip netns delete ns2
ip netns delete ns3

ip link delete veth0
ip link delete veth1
ip link delete veth2
ip link delete veth3
ip link delete veth4
ip link delete veth5
#
ip link delete veth24
ip link delete veth34
ip link delete veth35

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

ip netns exec ns1 ip link add veth24 type veth peer name veth2 netns ns2
ip netns exec ns1 ip addr add 10.0.20.3/24 dev veth24
ip netns exec ns1 ip link set veth24 up

ip netns exec ns2 ip addr add 10.0.20.2/24 dev veth3
ip netns exec ns2 ip link set veth3 up
ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip route add default via 10.0.20.1 dev veth3

ip netns add ns3
ip netns exec ns1 ip link add veth35 type veth peer name veth34 netns ns3
ip netns exec ns1 ip addr add 10.0.30.2/24 dev veth35
ip netns exec ns1 ip link set veth35 up
ip netns exec ns3 ip addr add 10.0.30.1/24 dev veth34
ip netns exec ns3 ip link set veth34 up
# ip netns exec ns3 ip link set lo up
# ip netns exec ns3 ip route add default via 10.0.30.2 dev veth34

ip netns exec ns1 ip rule add fwmark 1 lookup 100
ip netns exec ns1 ip route add local default dev lo table 100

# ----- configuration under test

ip netns exec ns1 iptables -t mangle -N DIVERT
ip netns exec ns1 iptables -t mangle -A DIVERT -j MARK --set-mark 1
ip netns exec ns1 iptables -t mangle -A DIVERT -j ACCEPT
ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

ip netns exec ns1 iptables -t mangle -N GOST
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 255.255.255.255/32 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345

# ns1, openwrt router, enable NAT for ns2(client) browse ns3(e.g. google.com) web page
ip netns exec ns1 sysctl -w net.ipv4.ip_forward=1
ip netns exec ns1 iptables -t nat -A POSTROUTING -o veth35 -j MASQUERADE

ip netns exec ns1 ipset create antigravity_proxy hash:ip timeout 300 -exist
ip netns exec ns1 ipset add antigravity_proxy 10.0.10.1

ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp  -m set --match-set antigravity_proxy dst  -j GOST
# ip netns exec ns1 iptables -t mangle -D PREROUTING 2

ip netns exec ns1 ipset list antigravity_proxy

# -----

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

cp /labs/lab8/dnsmasq.conf /etc/dnsmasq.conf

cp /labs/lab8/proxy-domains.conf /etc/dnsmasq.d/proxy-domains.conf

# ip netns exec ns1 ipset create antigravity_proxy hash:ip timeout 300 -exist


echo "done"

exit 0

#
#
#
#
# below command for testing
#
#
#
#

# default ns, leave to listen all for easy troubleshooting
gost -L http://user:pass@:8080 &
python -m http.server 8000 &
iperf3 -s &

# ns1
ip netns exec ns1 gost -L "red://10.0.20.1:12345?tproxy=true" -F "http://user:pass@10.0.10.1:8080?so_mark=100"

# ns2
ip netns exec ns2 curl 10.0.10.1:8000  # should be ok, through GOST, from ns2 to my machine
ip netns exec ns2 iperf3 -c 10.0.10.1

# ns3
ip netns exec ns3 python -m http.server 8000 &
ip netns exec ns3 iperf3 -s &

ip netns exec ns2 curl 10.0.30.1:8000  # should be ok, direct NAT
ip netns exec ns2 iperf3 -c 10.0.30.1

#
# command for troubleshooting
#

ip netns exec ns2 ping 10.0.10.1   # cannot ping -> is ok
ip netns exec ns2 ping 10.0.20.1   # ping -> is ok
ip netns exec ns1 ping 10.0.10.1   # ping -> is ok
ip netns exec ns1 ping 10.0.20.2   # ping -> is ok

ip netns exec ns2 ping 10.0.30.1   # cannot ping -> is ok after enable NAT
ip netns exec ns2 curl 10.0.30.1:8000   # cannot ping -> is ok after enable NAT
ip netns exec ns2 traceroute 10.0.30.1   # cannot ping -> is ok
ip netns exec ns1 ip route   # cannot ping -> is ok
ip netns exec ns1 ping 10.0.30.1   # cannot ping -> is ok

ip netns exec ns3 ip route add 10.0.30.2 via 192.168.1.1
ip netns exec ns3 ip route   # cannot ping -> is ok
ip netns exec ns3 ping 10.0.30.2   # cannot ping -> is ok

ip netns exec ns1 curl 10.0.30.1:8000
