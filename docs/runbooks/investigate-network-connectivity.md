# Investigate Network Connectivity

## Symptoms

- Timeout, connection refused, intermittent reachability.
- Host works by IP but not name.
- Application cannot reach a remote service.
- Route differs from expectation.

## First checks

```bash
ror diagnose network
ror diagnose dns <hostname>
```

For a specific endpoint:

```bash
getent ahosts host.example.com
ip route get <destination-ip>
nc -vz host.example.com 443
curl -vk --connect-timeout 5 https://host.example.com/
```

## Work layer by layer

### 1. Local interface/state

```bash
ip -br addr
ip link
```

Confirm the expected interface is up and has the expected address/prefix.

### 2. Routing

```bash
ip route
ip route get <destination-ip>
```

`ip route get` is especially useful because it shows the route, source IP, and interface the kernel would actually choose.

### 3. DNS

```bash
getent hosts <name>
dig <name>
cat /etc/resolv.conf
resolvectl status
```

If IP connectivity works but hostname connectivity does not, stay focused on DNS/search-domain/resolver behavior.

### 4. TCP/UDP service reachability

```bash
nc -vz <host> <port>
curl -v http://<host>:<port>/
```

Interpret common results:

- **timeout**: packet filtering, route, remote host down, asymmetric path.
- **connection refused**: host reachable, nothing listening or an active reject.
- **connected**: network path exists; move upward to TLS/application protocol.

### 5. Local listener

On the server:

```bash
ss -lntup
lsof -i :<port>
```

Check whether it is bound to the expected address (`0.0.0.0`, `::`, or a specific interface).

### 6. Firewall / policy

```bash
firewall-cmd --list-all 2>/dev/null
nft list ruleset 2>/dev/null
iptables -S 2>/dev/null
```

Do not flush firewall rules as a troubleshooting shortcut.

### 7. Packet capture

When application logs and route checks are insufficient:

```bash
sudo tcpdump -ni any host <remote-ip> and port <port>
```

Look for SYN with no SYN/ACK, resets, repeated retransmits, or traffic leaving on an unexpected interface.

## Validation

Re-test the exact application protocol, not only ping. ICMP success does not prove TCP/UDP service reachability, and ICMP failure does not necessarily prove the service is unreachable.
