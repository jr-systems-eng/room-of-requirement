# DNS Troubleshooting

Quick-reference for resolver checks, authoritative lookups, records, and split/internal DNS troubleshooting.

## Host resolution through the OS

```bash
getent hosts hostname.example
getent ahosts hostname.example
```

Use `getent` when you want to know what the system resolver/NSS stack will actually return.

## dig basics

```bash
dig hostname.example
dig A hostname.example
dig AAAA hostname.example
dig CNAME hostname.example
dig MX example.com
dig TXT example.com
dig PTR 53.68.168.192.in-addr.arpa
```

Short output:

```bash
dig +short hostname.example
```

Query a specific DNS server:

```bash
dig @192.168.68.53 hostname.example
dig @8.8.8.8 example.com
```

## Trace delegation

```bash
dig +trace example.com
```

## Ask authoritative nameservers directly

```bash
dig NS example.com +short
dig @ns1.example.net hostname.example A
```

## Reverse lookup

```bash
dig -x 192.168.68.53
host 192.168.68.53
```

## Resolver configuration

```bash
cat /etc/resolv.conf
resolvectl status
nmcli dev show | grep -i DNS
```

## Query details worth checking

```text
status: NOERROR / NXDOMAIN / SERVFAIL / REFUSED
ANSWER SECTION
AUTHORITY SECTION
SERVER
Query time
TTL
```

## Common failures

### `NXDOMAIN`
Name does not exist according to the answering server.

```bash
dig @SERVER name.example
```

### `SERVFAIL`
Often DNSSEC, upstream failure, recursion failure, or broken delegation.

```bash
dig +trace name.example
dig @AUTHORITATIVE name.example
```

### Works with `dig @server`, fails normally
Check the host's configured resolver and search domains:

```bash
cat /etc/resolv.conf
resolvectl status
getent hosts name.example
```

### Internal and public answers differ
Likely split DNS. Always compare explicit resolvers:

```bash
dig @INTERNAL_DNS name.example
dig @PUBLIC_DNS name.example
```

## Pi-hole quick checks

```bash
pihole status
pihole -t
```

From a client:

```bash
dig @PIHOLE_IP internal.home.example
```

## DNS record reminders

```text
A       hostname -> IPv4
AAAA    hostname -> IPv6
CNAME   alias -> canonical hostname
PTR     IP -> hostname
MX      mail exchanger
TXT     arbitrary text, verification, SPF/DKIM-related data
NS      authoritative nameserver
SOA     zone authority/serial/timers
```

## Fast DNS workflow

```text
1. getent hosts NAME             what the OS sees
2. cat /etc/resolv.conf          resolver config
3. dig NAME                      normal DNS result
4. dig @SERVER NAME              isolate resolver
5. dig NS DOMAIN                 identify authority
6. dig @AUTH NAME                ask authority directly
7. dig +trace NAME               delegation/path issues
```
