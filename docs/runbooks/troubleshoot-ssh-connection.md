# Troubleshoot an SSH / SFTP Connection

## Symptoms

- Timeout or connection refused.
- Host key failure.
- Authentication failure.
- `no matching ... found` negotiation errors.
- SFTP subsystem failure after SSH authentication.

## Safety

Collect both client and server evidence before weakening SSH cryptography or changing PAM/authentication. Avoid broad global compatibility changes when a per-host/per-user exception can isolate the risk.

## First checks

### Client

```bash
ssh -vvv user@host
ssh -G host | less
nc -vz host 22
```

### Server

```bash
ror diagnose ssh
ss -lntp | grep ':22 '
journalctl -u sshd -f
sshd -T
```

For SFTP:

```bash
grep -RIn '^Subsystem[[:space:]]\+sftp' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null
```

## Interpret the stage of failure

1. **No TCP connection** — routing, firewall, listener, DNS, NAT.
2. **SSH negotiation failure** — KEX, cipher, MAC, host key algorithm.
3. **Authentication failure** — key/password/PAM/RADIUS/account state.
4. **Session/subsystem failure** — shell restrictions, SFTP subsystem, chroot, permissions.

Do not debug authentication until negotiation succeeds.

## Negotiation diagnostics

Client-supported algorithms:

```bash
ssh -Q kex
ssh -Q cipher
ssh -Q mac
ssh -Q key
```

Server effective configuration:

```bash
sshd -T | grep -Ei 'kexalgorithms|ciphers|macs|hostkeyalgorithms'
```

The server journal often records the exact algorithm list offered by an incompatible client. Preserve that line before changing anything.

## Authentication checks

```bash
id <user>
passwd -S <user>            # distro-dependent
getent passwd <user>
sudo -l -U <user>
grep -vE '^[[:space:]]*(#|$)' /etc/pam.d/sshd
```

For key authentication:

```bash
namei -l ~/.ssh/authorized_keys
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Typical safe permissions are `700` for `.ssh` and `600` for `authorized_keys`, with ownership matching the account.

## Validation

```bash
ssh -vv user@host true
sftp -vv user@host
```

Validate the actual application/client after a manual test; a modern OpenSSH client succeeding does not prove a legacy Java/JSch client will negotiate successfully.
