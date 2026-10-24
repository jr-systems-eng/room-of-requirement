# Room of Requirement — User Guide

> **Start here:** This is the task-oriented guide to using the features currently shipped in Room of Requirement (ROR). For a command-by-command reference see [Command Reference](command-reference.md); for working examples and triage see [Operational Recipes](operational-recipes.md).

## 1. What ROR is — and is not

ROR is a portable, local engineering toolbox. Its knowledge base combines cheat sheets, snippets, runbooks, templates, scripts, read-only diagnostic collectors, guided operational workflows, package profiles, managed dotfiles, and portable workstation bootstrap.

The four operational entry points solve different problems:

| Question | Command | What happens |
| --- | --- | --- |
| What should I use for this topic? | `ror need TOPIC` | Lists curated first steps, related rooms and resources; **nothing is executed** |
| What is happening on this host? | `ror diagnose TARGET` | Runs a read-only evidence collector |
| What sequence should I follow? | `ror workflow NAME ...` | Runs a constrained preflight/plan; only some workflows support explicit `--apply` |
| Can I run a specific utility? | `ror run PATH ...` | Runs that script with the supplied arguments |

You can use an individual script or Markdown resource without installing the CLI, but the `ror` wrapper makes navigation more consistent. ROR does **not** autonomously troubleshoot, operate Cursor agents, deploy certificates, or administer a fleet. A diagnostic warning is evidence to investigate, not a guaranteed diagnosis.

## 2. Install, verify, and locate it

Prerequisites: a clone of this repository, Git, a Bash environment for the shared CLI, and whichever OS tools a particular command requires.

### Linux / macOS / WSL

```bash
git clone https://github.com/jr-systems-eng/room-of-requirement.git
cd room-of-requirement
bash bootstrap/install.sh
ror version
ror doctor
```

The default bootstrap creates a `~/.local/bin/ror` wrapper and runs read-only checks; it does not install packages or apply dotfiles. If `ror` is not found, ensure `~/.local/bin` is in `PATH` or use `bash bin/ror ...` from the repository root.

### Windows / PowerShell

With Git Bash or WSL available, run in PowerShell from the clone:

```powershell
.\bootstrap\install.ps1
```

This creates `~/.local/bin/ror.ps1` and delegates the shared CLI to Bash. In a Git Bash terminal, `bash bin/ror doctor` works directly from the clone.

### First five commands

```bash
ror info                     # version/path/OS/package manager locations
ror doctor                   # platform, tools, health, dotfile state
ror need list                # available topic rooms
ror workflow list            # workflows, risk modes, maturity
ror self-test                # local syntax/metadata/dispatch checks
```

`ror path` prints the repository root, and `ror path docs`, `ror path scripts`, `ror path workflows`, `ror path room`, `ror path workflow-metadata` and `ror path local` resolve useful directories. See [Bootstrap](../bootstrap/README.md) and [Portable Workstation Setup](setup/portable-workstation.md) for platform options.

## 3. Find the right resource

### Curated Room navigation

```bash
ror need ssh
ror need certificate         # aliases to tls
ror need memory              # aliases to performance
ror need docker              # aliases to containers
ror need agents
```

Read **Start here**, inspect the recommended command, then follow **Next actions**, **Resources** and **Related rooms** as necessary. All Room output comes from the checked-in `config/room/*.tsv` mapping; it is not a generated diagnosis. To discover available topics, use `ror need list`. Unknown topics fall back to repository search.

### Literal search and cheat sheets

```bash
ror find --type runbook nfs
ror find --type script port
ror find --type template ansible
ror find --type workflow certificate
ror find ssh                  # all supported resource categories
ror cheat subnetting          # display a matching cheat sheet (or list matches)
```

`ror search` is an alias for `ror find`. Use [Cheat Sheets](../cheat-sheets/README.md) for quick reminders, [Snippets](../snippets/README.md) for short copy/paste commands, and [Runbooks](runbooks/README.md) for manual investigation/remediation decisions. Use `ror new` for starter files, not reading reference material.

## 4. Investigate an unfamiliar system

Start broad, then narrow the evidence:

```bash
ror doctor
ror collect baseline
ror diagnose network
ror diagnose performance
ror diagnose systemd sshd
```

`ror doctor` summarizes OS/architecture, local tooling, filesystem/memory pressure, service/time/firewall context and dotfiles. `ror collect baseline` runs a broad collector and saves its output as a timestamped `ror-collect-baseline-HOST-TIMESTAMP.txt` in the current directory. The baseline intentionally skips the full root-directory usage scan.

`ror diagnose` displays a collector on screen, whereas `ror collect TARGET [args...]` runs the same collector, displays output and records it to a text file. To choose the exact output path, set `ROR_COLLECT_OUTPUT` before invoking `ror collect`:

```bash
ROR_COLLECT_OUTPUT=./host-before-change.txt ror collect systemd sshd
```

Collectors are designed for read-only host/workload inspection and generally preserve raw evidence above a conservative `SUMMARY`. Some checks may make outbound queries to a chosen service or cluster and may require privileges. Redact hostnames, logs, or other sensitive operational details before sharing an evidence bundle.

| Symptom | First command | Next reference |
| --- | --- | --- |
| System slow or OOM | `ror diagnose performance` | [High load](runbooks/investigate-high-load.md), [Memory](runbooks/investigate-memory-pressure.md) |
| Disk/inodes full | `ror diagnose storage` | [Full filesystem](runbooks/troubleshoot-full-filesystem.md) |
| Host cannot resolve names | `ror diagnose dns example.com` | [DNS runbook](runbooks/troubleshoot-dns-resolution.md) |
| Network reachability | `ror diagnose network` | [Network runbook](runbooks/investigate-network-connectivity.md) |
| SSH/SFTP failed | `ror diagnose ssh` | [SSH runbook](runbooks/troubleshoot-ssh-connection.md) |
| TLS trust/expiry | `ror diagnose tls example.com:443` | [TLS runbook](runbooks/troubleshoot-tls-certificate.md) |
| Java PKIX | `ror need java` | [PKIX runbook](runbooks/troubleshoot-java-pkix.md) |
| Tomcat failed | `ror diagnose tomcat tomcat` | [Tomcat runbook](runbooks/troubleshoot-tomcat-startup.md) |
| NFS access | `ror diagnose nfs nfs.example.com` | [NFS runbook](runbooks/configure-nfs-share.md) |
| Container/cluster trouble | `ror diagnose docker` or `ror diagnose kubernetes default` | [Diagnostic Index](../scripts/diagnostics/README.md) |

For every supported diagnostic target, argument and output note see [Command Reference](command-reference.md).

## 5. Use a guided workflow safely

```bash
ror workflow list
ror workflow nfs-client --help
ror workflow service-recovery --help
```

Every workflow has metadata: `read-only` (inspection), `preparation` (change preparation only) or `plan-apply` (inspection and plan by default; mutates only with literal `--apply`). **All current workflows are marked experimental.** Apply modes need a human review, appropriate maintenance window, backup and representative field testing. CI does not exercise apply paths.

### NFSv4 client

```bash
ror workflow nfs-client --server nfs.example.com --export /data --mountpoint /mnt/data --persist
# Review preflight, existing mounts, fstab conflicts, mount options and rollback first.
ror workflow nfs-client --server nfs.example.com --export /data --mountpoint /mnt/data --persist --apply
```

Use the second command only after verifying that the plan is correct and preflight has no blockers. With `--persist`, a new fstab entry is guarded and `/etc/fstab` is backed up. The workflow prints real rollback instructions.

### One systemd unit

```bash
ror workflow service-recovery --service sshd
ror workflow service-recovery --service sshd --apply
```

The first displays status and a restart plan. The second performs a restart and validates unit state/journal. It does not edit configuration. A restart itself cannot be undone; use the service's runbook if it fails.

### New engineering workstation

```bash
ror workflow workstation --profile linux-admin --dotfiles bash,git,tmux
ror workflow workstation --profile linux-admin --dotfiles bash,git,tmux --apply
```

Default is package suggestions + managed-dotfile diffs. Apply installs the package profile and each selected dotfile group; it does not automatically install external/vendor-specific tools. Dotfiles have backup IDs; package installation is not automatically rolled back. Use `--dotfiles none` if you want packages only.

### Validate an Ansible inventory

```bash
ror workflow ansible-inventory --inventory hosts.ini
ror workflow ansible-inventory --inventory hosts.ini --host web01
```

Uses locally available `ansible-inventory` to parse/show a graph and optionally host variables. **No connections to managed hosts** and no apply mode. Host variables may contain sensitive values; review output accordingly.

### Prepare a certificate change

```bash
ror workflow certificate-deploy-prep --cert fullchain.pem --key privkey.pem --chain chain.pem --target /etc/pki/tls/certs/app.pem --days 30
```

Inspects a certificate, key matching, optional chain, dates and intended target metadata. It **never deploys**, has no `--apply` option, and does not prompt for an encrypted key passphrase. The operator still owns key security, backups, permissions and reload decisions.

Refer to [Guided Workflow Index](../workflows/README.md), [Workflow Registry](../config/workflows/README.md) and [Operational Recipes](operational-recipes.md) for fuller walkthroughs. LVM growth remains a [manual runbook](runbooks/extend-lvm-filesystem.md), not an automated workflow.

## 6. Run a focused utility

When a full diagnostic is unnecessary, use `ror run` with a path relative to `scripts/`:

```bash
ror run system/port-process.sh 8443
ror run networking/cert-expiry.sh example.com:443 30
ror run git/repo-health.sh .
ror run kubernetes/workload-summary.sh default
ror run git/audit-agent-standards.sh --root /path/to/repos --strict
```

For the certificate utility, exit code `0` means outside the warning window, `2` means within the window or expired, and `1` generally means a retrieval/dependency failure. A Git agent-audit strict failure means included clones need attention; it does not prove their instructions are correct. See [Scripts](../scripts/README.md).

## 7. Reuse code, operating instructions, and agent standards

```bash
ror new ansible/rolling-change.yml ./rolling-change.yml
ror new docker/compose.yaml ./compose.yaml
ror new systemd/service.service ./app.service
ror new agents/project-AGENTS.md ./AGENTS.md
ror new agents/work-order.md ./work-order.md
ror new agents/handoff.md ./handoff.md
```

`ror new` copies **one** template and refuses to overwrite any existing destination. It does not replace `__TOKEN__` placeholders. Review the copied file, fill placeholders, validate and customize it before use. Available families include Ansible, Bash, Docker/Compose, Kubernetes, GitHub, logrotate, systemd, Terraform and agent templates. See the [Template Index](../templates/README.md).

For agent onboarding, use [Agent Standards — Setup, Operation, and Repository Rollout](setup/agent-standards-workflow.md). A root `AGENTS.md` must be tracked/pushed before a cloud checkout can see it. The local audit checks immediate sibling clones and honors `--exclude` and `--strict`; it never publishes or fixes instructions. The kit provides documents/audit, **not** an autonomous Cursor coordinator.

## 8. Package profiles, dotfiles, and upgrades

```bash
ror pkg list
ror pkg suggest linux-admin   # read-only
ror pkg install linux-admin   # explicit mutation
ror dotfiles status
ror dotfiles diff bash        # read-only
ror dotfiles install bash     # snapshot + install
ror dotfiles backups
ror dotfiles restore latest
```

Profiles: `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes` and `cloud`. Use `ror workflow workstation` if you prefer a combined plan. Managed Bash/Git/tmux/PowerShell fragments are installed under `~/.config/ror/` and linked from existing configurations, preserving user-owned settings. Local/private host settings do not belong in the public repo; see [Dotfiles](../dotfiles/README.md).

```bash
ror version
ror update --check            # compares remote SHA, no fetch/update
ror update                    # clean worktree + fast-forward-only pull
ror self-test                  # local and network-independent
```

A differing remote SHA is a review signal, **not** proof that the remote can fast-forward. Do not use `ror update` from a dirty worktree. For contributors see [Resource Authoring](resource-authoring.md), [Architecture](architecture.md), and [Tests](../tests/README.md).

## 9. Interpretation, limitations, and next steps

- `ror need` is **navigation**, not a diagnostic or executor.
- `ror diagnose` and `ror collect` inspect state; read-only does not mean the output is automatically safe to disclose.
- `ror workflow` modes/statuses are documented in the registry. Experimental apply paths require independent human approval.
- `ror run` is a **direct script execution path**: verify the script's behavior before passing arguments.
- `ror new` creates an unmodified starting file, not a deployable configuration.
- Bootstrap does not automatically install packages, dotfiles or agent instructions.
- Environment-specific secrets, credential files, host-specific data and unreviewed output must stay private.

When uncertain, start with `ror need TOPIC`, run a diagnostic, read the relevant runbook, capture evidence, then consider a reviewed workflow plan. For exact CLI syntax and all feature categories, continue to [Command Reference](command-reference.md).