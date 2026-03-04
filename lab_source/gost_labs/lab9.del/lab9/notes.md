# Playground

run `setup.sh`

```bash
# default ns, act remote end
gost -L http://:8080 &
iperf3 -s &
python -m http.server 8000 &


# ns3, public wan e.g. www.google.com
ip netns exec ns3 gost -L http://:8080 &
ip netns exec ns3 python -m http.server 8000 &

ip netns exec ns2 curl 10.0.30.1:8000


# ns1, gateway (openwrt)
# ip netns exec ns1 gost -L "red://10.0.20.3:12345?sniffing=true" -F "http://10.0.10.1:8080?so_mark=100" &
ip netns exec ns1 gost -C ./gost_ns1.yaml



# testing on ns2, client
ip netns exec ns2 ping 10.0.20.1   # should be ok
ip netns exec ns1 ping 10.0.30.1   # should be ok
ip netns exec ns2 traceroute 10.0.30.1   # should be ok
ip netns exec ns2 ping 10.0.10.1   # should be failed


ip netns exec ns2 iperf3 -c 10.0.10.1
ip netns exec ns2 curl 10.0.10.1:8000
ip netns exec ns2 curl 10.0.30.1:8000


ip netns exec ns1 ping 10.0.30.1
ip netns exec ns1 ip route
```
