# Runbooks

Safe, repeatable troubleshooting and administration procedures. Runbooks are for situations where the order of operations and interpretation matter—not just remembering a command.

## Administration

- [Configure an NFS share](configure-nfs-share.md)
- [Extend an LVM filesystem](extend-lvm-filesystem.md)

## Troubleshooting

- [systemd service](troubleshoot-systemd-service.md)
- [SSH / SFTP connection](troubleshoot-ssh-connection.md)
- [TLS certificate / chain](troubleshoot-tls-certificate.md)
- [DNS resolution](troubleshoot-dns-resolution.md)
- [Network connectivity](investigate-network-connectivity.md)
- [Java PKIX / truststore](troubleshoot-java-pkix.md)
- [Tomcat startup](troubleshoot-tomcat-startup.md)
- [Full filesystem](troubleshoot-full-filesystem.md)
- [High system load](investigate-high-load.md)
- [Memory pressure / OOM](investigate-memory-pressure.md)

## Runbook contract

New runbooks should generally contain:

1. Symptoms / scope.
2. Safety notes.
3. Read-only first checks.
4. A decision path based on evidence.
5. Remediation options.
6. Validation.
7. Rollback considerations when changes are involved.

Administration runbooks may be more procedural, but should still explain what each stage proves and how to validate the result.

See [Resource Authoring Guide](../resource-authoring.md) for the full repository maintenance checklist.

Use `ror find --type runbook <term>` or `ror need <topic>` to locate a procedure.
