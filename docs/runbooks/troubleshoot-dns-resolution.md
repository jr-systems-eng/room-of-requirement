# Troubleshoot DNS Resolution

## Scope

Use this runbook when a Linux host cannot resolve a name, resolves the wrong address, behaves differently from another host, or an application reports a DNS/name-resolution failure.

Treat DNS as one layer in the path. A successful lookup does not prove the destination service is reachable, and a failed application connection does not automatically mean DNS is broken.

## Safety notes

- Start with read-only resolver and lookup checks.
- Do not replace `/etc/resolv.conf` until you know whether NetworkManager, systemd-resolved, DHCP, cloud-init, or another manager owns it.
- Do not disable DNSSEC, firewalls, or security controls just to make a lookup pass.
- Compare the system resolver path (`getent`) with direct DNS tools (`dig`) before changing configuration.

## 1. Capture the current resolver state

```bash
ror diagnose dns example.com
```

Then inspect the local configuration:

```bash
cat /etc/resolv.conf
getent hosts example.com
getent ahosts example.com
```

When available:

```bash
resolvectl status
nmcli dev show | grep -i dns
```

Record which nameservers and search domains the host is actually using.

## 2. Separate system-resolver behavior from direct DNS queries

System resolver:

```bash
getent ahosts example.com
```

Direct query using the configured resolver:

```bash
dig example.com A

dig example.com AAAA
```

Direct query to a specific resolver:

```bash
dig @__DNS_SERVER__ example.com A
```

Interpretation:

- `getent` succeeds and `dig` succeeds: DNS is probably functioning; continue to application/network checks.
- `dig` succeeds but `getent` fails: inspect NSS configuration, search domains, local resolver services, and `/etc/hosts`.
- both fail against the configured resolver but a known-good resolver succeeds: investigate the configured DNS server or the route/firewall path to it.
- all resolvers return the same negative answer: confirm the record should exist and check the authoritative zone.

## 3. Check NSS and local overrides

```bash
grep '^hosts:' /etc/nsswitch.conf
cat /etc/hosts
```

Common `hosts:` sources include `files`, `dns`, `resolve`, and `myhostname`.

A stale `/etc/hosts` entry can override DNS depending on NSS order.

## 4. Check search-domain behavior

If short names fail but FQDNs work:

```bash
getent hosts app01
getent hosts app01.example.com
```

Inspect search/domain entries:

```bash
grep -E '^(search|domain|nameserver)' /etc/resolv.conf
resolvectl status 2>/dev/null || true
```

Avoid adding a search domain unless the host is intended to use it.

## 5. Check reachability to the DNS server

Find the route:

```bash
ip route get __DNS_SERVER__
```

Test UDP and TCP 53 when tooling allows:

```bash
nc -zvu __DNS_SERVER__ 53
nc -zv __DNS_SERVER__ 53
```

Capture traffic during a lookup if needed:

```bash
sudo tcpdump -ni any host __DNS_SERVER__ and port 53
```

In another terminal:

```bash
dig @__DNS_SERVER__ example.com A
```

Useful evidence:

- query leaves but no response returns: inspect routing, firewall, ACL, VPN, or DNS-server health;
- no query leaves: inspect local resolver configuration/service;
- response returns with `SERVFAIL`: inspect upstream/authoritative DNS and DNSSEC state;
- response returns `NXDOMAIN`: confirm the exact name and zone contents.

## 6. Inspect common response states

```bash
dig example.com A +noall +comments +answer +authority
```

Common statuses:

- `NOERROR` — the query was processed successfully; an empty answer can still be valid.
- `NXDOMAIN` — the queried name does not exist from that resolver's perspective.
- `SERVFAIL` — the resolver could not complete resolution; investigate upstream, DNSSEC, delegation, or authoritative availability.
- `REFUSED` — the resolver intentionally refused the query, often because of policy/ACL/recursion settings.

## 7. Compare multiple hosts before changing anything

On a working and failing host, compare:

```bash
cat /etc/resolv.conf
grep '^hosts:' /etc/nsswitch.conf
ip route
getent ahosts example.com
dig example.com A +noall +comments +answer
```

Differences in resolver, search domain, VPN, route, or local overrides are often more useful than changing the failing host immediately.

## 8. Remediation paths

Only after identifying ownership and the failure point:

- correct a stale `/etc/hosts` entry;
- correct NetworkManager/systemd-resolved/DHCP DNS configuration through its owning mechanism;
- repair DNS-server ACL/recursion/zone configuration;
- correct missing or incorrect authoritative records;
- repair routing/firewall access to the configured resolver.

Do not hand-edit generated `/etc/resolv.conf` on a managed system unless the owning mechanism explicitly expects that.

## Validation

Re-test using both system and direct paths:

```bash
getent ahosts example.com
dig example.com A +noall +comments +answer
```

Then validate the actual application path, for example:

```bash
curl -v https://example.com/
```

or the service-specific connection test.

## Rollback

If resolver configuration was changed, restore it through the same manager that owns it and re-run the validation commands. If a local override was added, remove only that override and confirm the system returns to the intended DNS behavior.
