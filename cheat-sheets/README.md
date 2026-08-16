# Cheat Sheets

Quick-reference material for common administration, engineering, troubleshooting, automation, and homelab tasks.

These are intentionally concise: enough context to choose the right command, but optimized for fast lookup rather than full tutorials.

## Structure

```text
cheat-sheets/
├── README.md
├── automation/
│   └── ansible.md
├── containers/
│   ├── docker-compose.md
│   └── kubernetes-kubectl.md
├── development/
│   ├── bash-scripting.md
│   └── git.md
├── java/
│   └── java-keystores.md
├── linux/
│   ├── command-line.md
│   ├── packages-rpm-dnf.md
│   ├── storage-filesystems.md
│   ├── systemd-journalctl.md
│   └── users-permissions.md
├── networking/
│   ├── dns.md
│   ├── linux-network-troubleshooting.md
│   ├── ssh-sftp.md
│   └── subnetting.md
├── security/
│   └── openssl-certificates.md
└── virtualization/
    └── govc.md
```

Add new sheets under a topic directory so the collection stays easy to browse as it grows.

## Index

### Linux

- [Linux Command Line](linux/command-line.md) — files, `find`, `grep`, `less`, text processing, archives, history, and shell shortcuts.
- [systemd and journalctl](linux/systemd-journalctl.md) — service lifecycle, unit inspection, boot/service logs, filtering, and startup-failure workflow.
- [Users, Groups, and Permissions](linux/users-permissions.md) — account state, permissions, sudo, ACLs, SELinux contexts, and path traversal troubleshooting.
- [Storage and Filesystems](linux/storage-filesystems.md) — disks, mounts, space/inodes, LVM expansion, XFS/ext4, deleted-open files, and SMART.
- [RPM and DNF](linux/packages-rpm-dnf.md) — package ownership, repositories, history, version locks, verification, and EL kernel package checks.

### Networking

- [IPv4 Subnetting](networking/subnetting.md) — CIDR prefixes, subnet masks, address counts, usable hosts, block sizes, wildcard masks, private ranges, formulas, and examples.
- [Linux Network Troubleshooting](networking/linux-network-troubleshooting.md) — interfaces, routes, sockets, `nc`, `curl`, `tcpdump`, NetworkManager, firewalls, and a troubleshooting order.
- [DNS Troubleshooting](networking/dns.md) — `getent`, `dig`, authoritative lookups, reverse DNS, split DNS, resolver checks, and Pi-hole basics.
- [SSH and SFTP](networking/ssh-sftp.md) — `ssh -vvv`, sshd logs/config, host keys, KEX/cipher discovery, SFTP subsystem, legacy compatibility tests, and failure clues.

### Automation

- [Ansible](automation/ansible.md) — inventories, ad-hoc commands, playbooks, facts, variables, debugging, conditionals, handlers, and safe fleet rollout.

### Containers and Kubernetes

- [Docker and Docker Compose](containers/docker-compose.md) — container inspection, logs, exec, Compose operations, mounts, networks, health checks, GPU validation, and cleanup.
- [Kubernetes / kubectl](containers/kubernetes-kubectl.md) — cluster context, resources, deployments, services, logs, exec, ConfigMaps/Secrets, pod states, and troubleshooting.

### Development and Scripting

- [Bash Scripting](development/bash-scripting.md) — safe defaults, arguments, tests, loops, functions, traps, secrets, debugging, and admin-script patterns.
- [Git](development/git.md) — status, branches, commits, restore/revert/reset, stash, reflog, history searching, and a safe daily workflow.

### Security and Certificates

- [OpenSSL and Certificates](security/openssl-certificates.md) — remote TLS testing, chain inspection/verification, key matching, PKCS#12, expiration checks, and common TLS errors.

### Java

- [Java Keystores and Truststores](java/java-keystores.md) — `keytool`, JKS/PKCS12, aliases, cacerts, JAR inspection, TLS debug, and PKIX troubleshooting.

### Virtualization

- [govc / vSphere CLI](virtualization/govc.md) — safe credential prompting, inventory discovery, VM power/info, datastores, uploads, disks, snapshots, and vSphere change workflow.

## Suggested lookup flow

When troubleshooting an unfamiliar failure, a useful order is often:

```text
service/process -> logs -> network/DNS -> permissions -> storage -> package/config -> application-specific layer
```

The sheets above are organized so those layers can be checked independently rather than jumping immediately to the application.
