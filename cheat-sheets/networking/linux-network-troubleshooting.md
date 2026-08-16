# Linux Network Troubleshooting

Quick-reference for interface, routing, port, reachability, and packet-level troubleshooting.

## Interfaces and addresses

```bash
ip -br addr
ip addr
ip link
ip -s link
nmcli device status
nmcli connection show
```

## Routes

```bash
ip route
ip -6 route
ip route get 10.10.10.10
ip rule
```

`ip route get` is one of the fastest ways to answer: **which interface/source/gateway will Linux actually use?**

## Neighbor / ARP table

```bash
ip neigh
arp -an                # Legacy if installed
```

## Listening ports and sockets

```bash
ss -tulpn
ss -ltnp
ss -lunp
ss -tnp
ss -ltnp | grep ':22'
```

Useful flags:

```text
-l  listening
-t  TCP
-u  UDP
-n  numeric
-p  process
```

## Reachability

```bash
ping -c 4 HOST
ping -I INTERFACE HOST
tracepath HOST
traceroute HOST
```

## Test TCP ports

```bash
nc -vz HOST 22
nc -vz -w 3 HOST 443
timeout 3 bash -c '</dev/tcp/HOST/PORT' && echo open
```

## Test UDP

UDP has no handshake, so success can be ambiguous:

```bash
nc -vzu HOST 1812
```

Use packet capture when certainty matters.

## curl

```bash
curl -v https://host/
curl -vk https://host/                     # Ignore TLS validation for diagnosis only
curl -I https://host/
curl -sS -o /dev/null -w '%{http_code}\n' https://host/
curl --resolve name.example:443:10.0.0.10 https://name.example/
```

`--resolve` tests a specific IP while preserving the hostname/SNI.

## Packet capture

```bash
tcpdump -ni any host 10.0.0.10
tcpdump -ni any port 22
tcpdump -ni any 'host 10.0.0.10 and port 22'
tcpdump -ni eth0 udp port 1812
tcpdump -ni any -vvv -s0 -w capture.pcap
```

Read a capture:

```bash
tcpdump -nn -r capture.pcap
```

## NetworkManager

```bash
nmcli con show
nmcli con show 'CONNECTION'
nmcli dev show INTERFACE
nmcli con up 'CONNECTION'
nmcli con down 'CONNECTION'
nmcli con reload
```

Set static IPv4 example:

```bash
nmcli con mod 'CONNECTION' \
  ipv4.method manual \
  ipv4.addresses 192.168.68.60/22 \
  ipv4.gateway 192.168.68.1 \
  ipv4.dns '192.168.68.53'
nmcli con up 'CONNECTION'
```

## Firewall quick checks

```bash
firewall-cmd --state
firewall-cmd --get-active-zones
firewall-cmd --list-all
firewall-cmd --list-all-zones
nft list ruleset
```

## Fast troubleshooting order

```text
1. ip -br addr                 address/link state
2. ip route                    routing table
3. ip route get DEST           actual selected path
4. ping gateway                local L3
5. ping destination            end-to-end ICMP
6. getent/dig destination      DNS if hostname involved
7. nc/curl                     application port
8. ss -ltnp                    server listener
9. firewall-cmd / nft          firewall
10. tcpdump                    prove what is actually on the wire
```
