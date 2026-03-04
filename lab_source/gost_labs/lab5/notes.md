# Playground

run `setup.sh`

```bash
# default ns, act remote end
gost -L http://user:pass@:8080 &
iperf3 -s &
python -m http.server 8000 &

# ns1, gateway (openwrt)
ip netns exec ns1 gost -L "red://10.0.20.3:12345?sniffing=true" -F "http://user:pass@10.0.10.1:8080?so_mark=100" &
ip netns exec ns1 iperf3 -c 10.0.10.1
ip netns exec ns1 curl 10.0.10.1:8000


# ns2, client
ip netns exec ns2 ping 10.0.20.1
ip netns exec ns2 iperf3 -c 10.0.10.1
ip netns exec ns2 curl 10.0.10.1:8000

```
