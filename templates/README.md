# Templates

Known-good starting points for common engineering artifacts. Templates should be portable, contain no real credentials or environment-specific identifiers, and make safe defaults obvious.

## Available templates

- `ansible/playbook.yml` — idempotent playbook skeleton with staged validation.
- `bash/script.sh` — reusable Bash script base.
- `docker/compose.yaml` — Compose service with restart policy and healthcheck placeholder.
- `k8s/deployment.yaml` — Deployment with resource requests/limits and probes.
- `k8s/service.yaml` — ClusterIP Service.
- `logrotate/app.conf` — rotation policy with reload guidance.
- `systemd/service.service` — service unit base.
- `systemd/timer.timer` — persistent scheduled timer.

## Create from a template

```bash
ror new ansible/playbook.yml ./playbook.yml
ror new docker/compose.yaml ./compose.yaml
ror new systemd/service.service ./myapp.service
ror new systemd/timer.timer ./myapp.timer
```

`ror new` refuses to overwrite an existing destination.
