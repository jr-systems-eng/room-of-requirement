# Runbooks

Safe, repeatable troubleshooting and administration procedures. Runbooks are for situations where the order of operations and interpretation matter—not just remembering a command.

## Administration

- [Configure an NFS share](configure-nfs-share.md)

## Troubleshooting

- [systemd service](troubleshoot-systemd-service.md)
- [SSH / SFTP connection](troubleshoot-ssh-connection.md)
- [TLS certificate / chain](troubleshoot-tls-certificate.md)
- [Java PKIX / truststore](troubleshoot-java-pkix.md)
- [Full filesystem](troubleshoot-full-filesystem.md)
- [Network connectivity](investigate-network-connectivity.md)

## Runbook contract

New runbooks should generally contain:

1. Symptoms / scope.
2. Safety notes.
3. Read-only first checks.
4. A decision path based on evidence.
5. Remediation options.
6. Validation.
7. Rollback considerations when changes are involved.

Use `ror find --type runbook <term>` to locate a procedure.
