# SSH and SFTP Troubleshooting

Quick-reference for SSH client diagnostics, server configuration, host keys, algorithms, and SFTP failures.

## Client diagnostics

```bash
ssh -vvv user@host
ssh -vvv -p 22 user@host
sftp -vvv user@host
scp -v file user@host:/path/
```

Useful client options:

```bash
ssh -o PreferredAuthentications=password user@host
ssh -o PubkeyAuthentication=no user@host
ssh -o StrictHostKeyChecking=no user@host       # diagnosis only
ssh -o UserKnownHostsFile=/dev/null user@host  # diagnosis only
```

## Server status and logs

```bash
systemctl status sshd --no-pager -l
journalctl -u sshd -n 100 --no-pager
journalctl -u sshd -f
sshd -t
sshd -T
```

Inspect effective settings:

```bash
sshd -T | grep -Ei 'passwordauthentication|pubkeyauthentication|kexalgorithms|ciphers|macs|subsystem'
```

For Match blocks:

```bash
sshd -T -C user=USERNAME,host=HOSTNAME,addr=CLIENT_IP
```

## Config locations

```text
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/*.conf
~/.ssh/config
~/.ssh/authorized_keys
~/.ssh/known_hosts
```

## Validate before restarting

```bash
sshd -t && systemctl reload sshd
```

Prefer reload over restart when possible.

## Host key problems

```bash
ssh-keygen -F hostname
ssh-keygen -R hostname
ssh-keygen -R 192.0.2.10
ssh-keyscan hostname
```

Inspect a host key fingerprint:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

## Key permissions

```text
~/.ssh                    700
~/.ssh/authorized_keys    600
private key               600
public key                644
```

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
restorecon -Rv ~/.ssh     # SELinux systems
```

## Algorithm discovery

Client-supported algorithms:

```bash
ssh -Q kex
ssh -Q cipher
ssh -Q mac
ssh -Q key
```

Effective client configuration:

```bash
ssh -G host | grep -Ei 'kex|cipher|mac|hostname|user|port'
```

Server-supported/effective algorithms:

```bash
sshd -T | grep -Ei 'kexalgorithms|ciphers|macs|hostkeyalgorithms'
```

## Test one legacy KEX explicitly

```bash
ssh -vvv -o KexAlgorithms=+diffie-hellman-group14-sha1 user@host
```

Use legacy algorithms only for controlled compatibility testing; avoid making global server-side exceptions unless required and documented.

## SFTP subsystem

```bash
grep -R '^Subsystem.*sftp' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null
sshd -T | grep subsystem
```

Typical entries:

```text
Subsystem sftp /usr/libexec/openssh/sftp-server
```

or

```text
Subsystem sftp internal-sftp
```

## Packet capture

```bash
tcpdump -ni any host CLIENT_IP and port 22
```

## Failure clues

```text
no matching key exchange method found
    Client/server KEX lists do not overlap.

DH GEX group out of range
    Legacy client cannot use the server-selected DH group size.

Permission denied
    Authentication/PAM/account/key problem after transport negotiation.

Connection refused
    Nothing listening or active rejection.

Connection timed out
    Network/firewall/path issue more likely.

subsystem request accepted
    SSH authentication succeeded and SFTP subsystem started.
```

## Fast troubleshooting sequence

```text
1. ssh -vvv / sftp -vvv from client
2. journalctl -u sshd -f on server
3. sshd -t then sshd -T
4. Compare KEX/cipher/MAC lists if negotiation fails
5. Check account/PAM/key permissions if authentication fails
6. Confirm Subsystem sftp if login succeeds but SFTP fails
7. tcpdump when client/server logs disagree
```
