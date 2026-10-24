# Room of Requirement — Operational Recipes

This guide answers **"I have a specific problem; what do I type, what should I see, and what do I do next?"** The authoritative syntax is in [Command Reference](command-reference.md) and the beginner explanation is in [User Guide](user-guide.md).

## Recipe 1 — First look on a server or new jumpbox

**Use when:** you do not know the health or available tools on the current host.

```bash
ror version
ror doctor
ror collect baseline
ror need list
```

**Expected:** version/branch information, a host/tool/dotfile inventory, then a timestamped `ror-collect-baseline-...txt` file with system/network/storage/DNS/security/service context. Start at warnings, compare against the raw evidence, and select one specific diagnostic. Missing optional tools do not necessarily indicate a broken host.

**Next:** `ror diagnose performance` for CPU/OOM, `ror diagnose storage` for disk/inode issues, `ror diagnose network` for routing/listener problems. Before sharing the report, inspect it for private hostnames, addresses, usernames and log entries.

## Recipe 2 — Service does not start (systemd / Tomcat)

**Use when:** a Linux systemd service is failed, crashing or unexpectedly inactive.

```bash
ror need systemd
ror diagnose systemd tomcat
ror diagnose tomcat tomcat
ror collect systemd tomcat
ror workflow service-recovery --service tomcat
```

**Expected:** load/active/sub state, status, unit/journal evidence, Tomcat process/context and a **plan without restart**. Inspect recent exceptions, config validity, failed dependencies and service-specific runbooks before restarting.

**Only after approval and review:**

```bash
ror workflow service-recovery --service tomcat --apply
ror diagnose systemd tomcat
```

**Validation:** verify service is active and application-level health is restored. A green systemd state alone is not proof the application is healthy. **Rollback:** restarting a process cannot be reversed; no files were backed up or changed by this workflow. If there are repeated failures, continue with [Tomcat startup](runbooks/troubleshoot-tomcat-startup.md) or [systemd troubleshooting](runbooks/troubleshoot-systemd-service.md), not repeated automatic restarts.

## Recipe 3 — Network, DNS, SSH or a blocked port

**Use when:** host resolution or a particular network service fails.

```bash
ror need network
ror diagnose network
ror diagnose dns example.com
ror diagnose ssh
ror run system/port-process.sh 22
```

**Expected:** interface/routes, configured resolver/lookup evidence, SSH daemon/listener/config/journal patterns, then a narrow local port-to-process view. The listener utility observes only local processes and does not prove remote firewall reachability.

**Next:** inspect [Network troubleshooting](runbooks/investigate-network-connectivity.md), [DNS troubleshooting](runbooks/troubleshoot-dns-resolution.md), or [SSH troubleshooting](runbooks/troubleshoot-ssh-connection.md). For a service other than `sshd`, supply its actual unit to `ror diagnose ssh UNIT`. Diagnose from the affected host where possible, since firewall, routing and DNS context differ by vantage point.

## Recipe 4 — Disk full, high load or OOM

```bash
ror need storage
ror diagnose storage
ror need performance
ror diagnose performance
ROR_COLLECT_OUTPUT=./performance-before.txt ror collect performance
```

**Expected:** file systems/inodes, LVM/mounts, deleted-open handles and potentially expensive root-level directory sizes from the storage collector; CPU count/load, memory/swap, blocked tasks, I/O and sampled OOM evidence from performance. Unlike `ror diagnose storage`, the general `baseline` skips the potentially slow root-level disk usage scan.

**Next:** follow [Full filesystem](runbooks/troubleshoot-full-filesystem.md), [High load](runbooks/investigate-high-load.md), [Memory pressure](runbooks/investigate-memory-pressure.md), or [LVM extension](runbooks/extend-lvm-filesystem.md). ROR **does not automate LVM growth**: review filesystem type, snapshots/backups and change authorization before editing partitions/LVs/filesystems.

## Recipe 5 — Review an NFS client mount before applying it

```bash
ror need nfs
ror diagnose nfs nfs.example.com
ror workflow nfs-client --server nfs.example.com --export /data --mountpoint /mnt/data --persist
```

**Expected:** existing NFS client/server evidence, name resolution/TCP 2049 checks, mountpoint safety, `/etc/fstab` conflict detection, and a printed plan. A TCP connection to port 2049 does **not** prove that an export or UID/GID permissions work. The workflow rejects nonempty unmounted mountpoints and conflicting mounts.

If you have verified the exact export and want the mount plus persistent entry, run the **same command** with `--apply`. If you want only a temporary mount, omit `--persist` from both plan and apply.

```bash
ror workflow nfs-client --server nfs.example.com --export /data --mountpoint /mnt/data --persist --apply
ror diagnose nfs nfs.example.com
```

**Validation:** check `findmnt` and application access as the intended user. **Rollback:** follow the unmount and actual `/etc/fstab.ror-...bak` restore instructions printed by the workflow; do not use a guessed backup filename. See [NFS runbook](runbooks/configure-nfs-share.md).

## Recipe 6 — TLS expiry, certificate preparation or Java PKIX

```bash
ror need certificate
ror diagnose tls example.com:443
ror run networking/cert-expiry.sh example.com:443 30
ror need java
```

**Expected:** handshake and leaf/chain/name details, an independent warning-window exit code, then pointers to Java keystores/PKIX references. Note that the expiry utility returns **2** for an expiring/expired certificate; do not interpret every nonzero as "script crashed".

For a planned file change:

```bash
ror workflow certificate-deploy-prep \
  --cert fullchain.pem --key privkey.pem --chain intermediate.pem \
  --target /etc/pki/tls/certs/app.pem --days 30
```

**Expected:** certificate metadata, public-key match or a warning for inaccessible/encrypted key, optional chain verification, intended target metadata and a backup naming suggestion. **There is no deployment option**; copy/reload/truststore steps remain outside this workflow. See [TLS runbook](runbooks/troubleshoot-tls-certificate.md) and [Java PKIX runbook](runbooks/troubleshoot-java-pkix.md). Keep private keys out of evidence bundles and repo commits.

## Recipe 7 — Read-only application runtime overview (Docker / Kubernetes)

```bash
ror need containers
ror diagnose docker
ror need kubernetes
ror diagnose kubernetes default
ror run kubernetes/workload-summary.sh default
```

**Expected:** Docker daemon/context/container/Compose/disk status and Kubernetes context/readiness/nodes/pods/workloads plus selected namespace metrics. These operations query the current runtime context; check that it is the intended environment before executing. They intentionally avoid dumping container environments, Kubernetes Secret objects and raw kubeconfig, but pod names/events can still reveal sensitive operational context.

**Next:** read [Docker/Compose references](../cheat-sheets/containers/docker-compose.md) or [Kubernetes reference](../cheat-sheets/containers/kubernetes-kubectl.md). The utility cannot fix a workload or deploy changes.

## Recipe 8 — Inspect an Ansible inventory before running playbooks

```bash
ror need ansible
ror workflow ansible-inventory --inventory ./hosts.ini
ror workflow ansible-inventory --inventory ./hosts.ini --host web01
ror new ansible/audit-playbook.yml ./audit-playbook.yml
```

**Expected:** validation result, a group/host graph and (if requested) the selected host's resolved variables. This contacts **no managed hosts**. Host variables can contain confidential information: avoid pasting them into tickets or PRs. `ror new` copies only one template and does not connect to hosts either. Review all placeholders and variables before executing a resulting playbook with Ansible yourself.

## Recipe 9 — Prepare a workstation and keep rollback

```bash
ror doctor --install-suggestions
ror pkg list
ror workflow workstation --profile troubleshooting --dotfiles bash,git,tmux
ror dotfiles backups
```

**Expected:** read-only package list, proposed changes and diffs. The recommended first action is **not** `--apply`; first review selected packages, external vendor tools, managed Bash/Git/tmux integrations and host-level customizations.

If approved, use the same `ror workflow workstation ... --apply` invocation. Alternatively install one group at a time using `ror dotfiles install bash`, then check `ror dotfiles status`. Save printed backup IDs. To reverse dotfile changes use `ror dotfiles restore ID`. Package installation has no automatic rollback. See [Portable Workstation Setup](setup/portable-workstation.md).

## Recipe 10 — Add or audit Cursor agent instructions

**When creating instructions in one project** (run from that project's root, with ROR on `PATH`):

```bash
git status --short --branch
ror new agents/project-AGENTS.md ./AGENTS.md
# Edit AGENTS.md, replace each __TOKEN__, review project-specific constraints.
git diff -- AGENTS.md
```

If `AGENTS.md` exists, **edit it**; the copy command will refuse an overwrite. Changes do not reach Cloud Agents until committed/merged to the revision the agent checks out.

**When reviewing a group of sibling repositories:**

```bash
ror run git/audit-agent-standards.sh \
  --root /path/to/projects \
  --exclude vendor-fork,work-repo \
  --strict
```

**Expected:** `REPOSITORY`, `BRANCH` and `AGENTS_STATUS` per immediate child worktree. `TRACKED` is the desired local file state; `MISSING`, `LOCAL_ONLY`, `MODIFIED` or `+PLACEHOLDERS` need review. The audit does not add, stage, push or fix anything. A strict zero exit does not imply correct instructions, fresh Git revisions or green tests.

Use `ror new agents/work-order.md ./work-order.md` to bound an agent task and `ror new agents/handoff.md ./handoff.md` to document completion. For repository rollover, fresh checkouts, Cursor's multi-root behavior, approval boundaries and PRs follow the [canonical agent workflow](setup/agent-standards-workflow.md).

## Recipe 11 — Find/create a reusable asset correctly

```bash
ror need github
ror find --type template workflow
ror new github/workflow-shellcheck.yml ./.github/workflows/shellcheck.yml
ror find --type runbook dns
```

**Expected:** discovery of references/templates, one newly copied file **only if the destination did not already exist**, and a runbook filename. Before adopting a template, fill placeholder tokens, verify least-privilege defaults, review code in the destination project and run its relevant tests.

For contributing new ROR capabilities, choose an existing category, add index/metadata references and test them using [Resource Authoring Guide](resource-authoring.md). Do not keep secrets or local machine data in the public repository.

## Recipe 12 — Test or update ROR itself

```bash
ror version
ror self-test
ror update --check
git status --short --branch
ror update
```

**Expected:** version and Git revision, local non-network self-test, remote revision comparison, explicit clean worktree, and only then a fast-forward-only pull. `ror update --check` reports differing commit IDs without calculating ancestry; review branch and changes yourself if they differ.

For contributors:

```bash
bash tests/smoke/ror-smoke.sh
bash tests/smoke/workflow-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_room_metadata.py
python3 tests/validate_workflow_metadata.py
python3 tests/validate_markdown_links.py
```

Use [Tests](../tests/README.md) for platform/CI context. Script syntax tests and code review remain important; the smoke suite does not prove experimental `--apply` paths safe on real hosts.

## Common misunderstandings

| Observation | What it means / what to do |
| --- | --- |
| `ror: command not found` | Wrapper not on `PATH`; use `bash bin/ror ...` from clone or fix `~/.local/bin` |
| `ror new` says destination exists | Intentional no-overwrite safety; inspect the existing file |
| Workflow prints failures but exits zero in plan mode | Preflight can report blockers without applying; **do not** proceed with `--apply` until resolved |
| `ror need X` returns generic files | No curated Room for that exact topic/alias; it falls back to literal search |
| Diagnostic reports `WARN` | Investigate the evidence; not a proven root cause |
| `ror update` refuses | Dirty worktree or fast-forward impossible; inspect Git state rather than resetting |
| Ansible workflow needs `ansible-inventory` | Activate/install Ansible locally; it never connects to remote hosts |
| Cert preparation does not deploy | Correct: it is a preparation-only workflow |
| Agent audit returns strict nonzero | One or more included clones lack clean tracked `AGENTS.md` or contain placeholders |

**Navigation:** [User Guide](user-guide.md) · [Command Reference](command-reference.md) · [Architecture](architecture.md) · [Resource Authoring](resource-authoring.md).