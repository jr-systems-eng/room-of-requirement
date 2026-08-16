# Networking Snippets

## Local state

```bash
ip -br addr
ip route
ip route get 8.8.8.8
ss -lntup
```

## DNS

```bash
getent ahosts host.example.com
dig host.example.com A +short
dig host.example.com AAAA +short
dig @8.8.8.8 host.example.com
```

## TCP connectivity

```bash
nc -vz host.example.com 22
nc -vz host.example.com 443
```

## HTTP/S

```bash
curl -v http://host.example.com/
curl -vk https://host.example.com/
curl -sS -o /dev/null -w '%{http_code}\n' https://host.example.com/
```

## TLS certificate

```bash
openssl s_client -connect host.example.com:443 -servername host.example.com </dev/null
```

Certificate summary:

```bash
openssl s_client -connect host.example.com:443 -servername host.example.com </dev/null 2>/dev/null |
  openssl x509 -noout -subject -issuer -dates -fingerprint -sha256
```

## SSH debug

```bash
ssh -vvv user@host
ssh -G host | less
ssh -Q kex
```

## Packet capture

```bash
sudo tcpdump -ni any host 10.0.0.10
sudo tcpdump -ni any host 10.0.0.10 and port 22
sudo tcpdump -ni eth0 -w capture.pcap host 10.0.0.10
```

## Trace path

```bash
traceroute host.example.com
tracepath host.example.com
```
