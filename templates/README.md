# Templates

Known-good starting points for common engineering artifacts. Templates should be portable, contain no real credentials or environment-specific identifiers, and make safe defaults obvious.

Templates use `__TOKEN__` placeholders. `ror new` copies one file at a time and refuses to overwrite an existing destination.

## Ansible

- `ansible/playbook.yml` — general idempotent playbook skeleton.
- `ansible/inventory.ini` — portable INI inventory starting point.
- `ansible/rolling-change.yml` — serial/rolling change pattern with validation.
- `ansible/audit-playbook.yml` — read-only evidence collection pattern.

## Bash / system services

- `bash/script.sh` — reusable Bash script base.
- `systemd/service.service` — service unit base.
- `systemd/timer.timer` — persistent scheduled timer.
- `logrotate/app.conf` — rotation policy with reload guidance.

## Containers

- `docker/Dockerfile` — non-root-oriented image build/runtime skeleton.
- `docker/compose.yaml` — Compose service with restart policy and healthcheck placeholder.

## Kubernetes

- `k8s/deployment.yaml` — Deployment with resource requests/limits and probes.
- `k8s/service.yaml` — ClusterIP Service.
- `k8s/namespace.yaml` — Namespace starting point.
- `k8s/configmap.yaml` — non-secret application configuration.
- `k8s/ingress.yaml` — `networking.k8s.io/v1` Ingress starting point.
- `k8s/persistent-volume-claim.yaml` — persistent storage claim.

## GitHub

- `github/workflow-shellcheck.yml` — Bash syntax and ShellCheck workflow.
- `github/workflow-ansible-lint.yml` — ansible-lint workflow.
- `github/pull_request_template.md` — validation/risk/rollback review checklist.

## Terraform

- `terraform/module.tf` — single-file portable module skeleton suitable for copying to `main.tf` and expanding.

## Create from a template

```bash
ror new ansible/rolling-change.yml ./rolling-change.yml
ror new docker/Dockerfile ./Dockerfile
ror new k8s/ingress.yaml ./ingress.yaml
ror new terraform/module.tf ./main.tf
ror new github/workflow-shellcheck.yml ./.github/workflows/shellcheck.yml
```

Review and replace every `__TOKEN__` before use.

See [Resource Authoring Guide](../docs/resource-authoring.md) for template safety and maintenance conventions.
