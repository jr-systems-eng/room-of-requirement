# Changelog

Notable changes to Room of Requirement are recorded here. The project uses the changelog to track capability-level changes rather than every individual file edit.

## v0.6.0 - 2026-08-16

### Added

- Phase 5 smarter troubleshooting and curated "Room" behavior.
- `ror need [topic|list]` as a deterministic relationship layer over repository resources.
- Curated topic maps for:
  - SSH/SFTP
  - TLS/certificates
  - DNS
  - networking
  - systemd/services
  - storage/filesystems/LVM
  - Java/JVM/PKIX/keystores
  - Tomcat
  - Kubernetes
  - Ansible
  - containers/Docker Compose
  - Git
- Topic aliases such as `certificate` -> `tls`, `sftp` -> `ssh`, `pkix` -> `java`, and `k8s` -> `kubernetes`.
- Curated quick actions and related references, diagnostics, runbooks, snippets, templates, and managed configuration where applicable.
- Conservative `SUMMARY` sections for systemd, SSH, TLS, DNS, storage, Java, and Tomcat diagnostics.
- Selected high-signal log-pattern detection for SSH KEX/authentication issues and Tomcat/Java conditions including PKIX, `OutOfMemoryError`, bind conflicts, and connection failures.
- CI smoke coverage for `ror need`, topic aliases, resource relationships, and portable diagnostic summary output.

### Changed

- `ror need` falls back to normal repository search when no curated topic exists.
- systemd diagnostics now summarize unit load/active state and main-process exit status.
- SSH diagnostics now validate sshd configuration, detect the effective SSH port, summarize service/listener state, and surface selected negotiation/authentication log patterns.
- TLS diagnostics now summarize certificate receipt, chain verification, expiry windows, hostname matching when supported by OpenSSL, and handshake command status.
- DNS diagnostics now summarize resolver configuration, system-resolver success, and common DNS response states.
- Storage diagnostics now summarize filesystem/inode pressure and deleted-but-open file handles.
- Java diagnostics now summarize runtime/process availability, requested PID state, Java process identity, and `jcmd` availability.
- Tomcat diagnostics now summarize service/PID state and selected high-signal recent log patterns.
- README, architecture documentation, and diagnostic documentation now define the relationship and interpretation models.

### Safety

- Diagnostic summaries are explicitly advisory: warnings identify evidence worth investigating and do not claim a proven root cause.
- Raw diagnostic evidence remains visible above each summary so interpretations stay inspectable.
- Tomcat diagnostics no longer request the systemd `Environment` property because unit environments can contain credentials or tokens.
- `ror need` is deterministic and reviewable in `lib/resources.sh`; it does not use fuzzy diagnosis or hidden inference.

## v0.5.1 - 2026-08-16

### Fixed

- `ror pkg list` now prints each package profile on its own line instead of concatenating all profiles into one long line.
- `ror pkg suggest` now terminates the profile purpose line cleanly before printing package details.
- Smoke tests now assert the expected line structure of the package profile list to prevent this formatting regression.

## v0.5.0 - 2026-08-16

### Added

- Phase 4 portable workstation/bootstrap layer.
- Expanded package profiles:
  - `minimal`
  - `troubleshooting`
  - `networking`
  - `linux-admin`
  - `development`
  - `ansible`
  - `containers`
  - `kubernetes`
  - `cloud`
- Package-profile descriptions and separation between package-manager-installable dependencies and external/vendor-specific tools that ROR reports but does not automatically install.
- Safe managed-dotfile lifecycle:
  - `ror dotfiles status`
  - `ror dotfiles diff [group|all]`
  - `ror dotfiles install <group|all>`
  - `ror dotfiles backups`
  - `ror dotfiles restore [latest|backup-id]`
- Managed Bash/Readline, Git, tmux, and PowerShell fragments under `~/.config/ror/`.
- Timestamped dotfile rollback snapshots under the user state directory before any dotfile install.
- Machine-specific Bash and PowerShell override paths under `~/.config/ror/local/`.
- Dotfile lifecycle documentation and portable workstation setup guide.
- Explicit Unix bootstrap options for package profiles and repeatable dotfile groups.
- Explicit Windows bootstrap parameters for package profiles and dotfile groups.
- Isolated dotfile install/restore smoke tests that use a disposable HOME on Linux and Windows CI runners.

### Changed

- Dotfile management now uses small marked include/source blocks instead of replacing whole host configuration files.
- Git managed configuration no longer contains placeholder identity; user name/email and credentials remain host-owned.
- Bash/tmux/Readline defaults were populated with conservative portable settings instead of placeholders.
- `ror doctor` now includes managed-dotfile state in its environment summary.
- `ror info` now reports dotfile config/state locations.
- Plain bootstrap remains non-destructive: it installs the ROR wrapper and runs the read-only doctor, while package/dotfile changes require explicit options.
- README and architecture documentation now describe package profiles, reversible dotfile management, and the intended new-machine workflow.
- CI smoke coverage now validates Phase 4 package-profile discovery and dotfile install/restore behavior.

### Safety

- Every file touched by `ror dotfiles install` is backed up once per installation transaction.
- `ror dotfiles restore` restores pre-existing files exactly and removes managed files that did not exist before the matching install.
- Git identity, credentials, SSH private keys/config, Bash login-profile replacement, and Windows-specific line-ending policy remain outside automatic dotfile management.
- Kubernetes/cloud/vendor CLIs such as `kubectl`, `helm`, `gcloud`, `govc`, and Docker are not silently installed through guessed distro-specific methods.

## v0.4.0 - 2026-08-16

### Added

- Phase 3 trust and portability layer.
- `ror collect baseline` / `ror diagnose baseline` general-purpose host intake collector combining:
  - system, network, storage, and resolver state
  - SELinux/AppArmor visibility
  - firewall visibility
  - time synchronization state
  - failed systemd units
  - recent warning-or-higher journal entries
  - installed kernel-package context
  - reboot-required visibility
  - proxy-variable presence without exposing proxy values
- Expanded `ror doctor` host-health signals for root-filesystem pressure, Linux memory pressure, failed systemd units, time synchronization, MAC/firewall visibility, proxy presence, and reboot state.
- `tests/` validation area with:
  - CLI smoke tests
  - deterministic local Markdown-link validation
  - test/validation documentation
- GitHub Actions validation workflow covering:
  - Bash syntax
  - error-level ShellCheck findings
  - YAML validation
  - JSON validation
  - local Markdown links
  - PowerShell parsing
  - Linux and Windows ROR smoke tests
  - full-history Gitleaks secret scanning
- YAML lint configuration for repository-wide CI validation.

### Changed

- README now presents `ror doctor` and `ror collect baseline` as the recommended first-look workflow for unfamiliar machines.
- Architecture documentation now defines the repository trust model, test contract, doctor model, and baseline collection safety rules.
- Diagnostic index now documents the baseline collector and its secret-avoidance behavior.
- Baseline storage collection skips the potentially expensive top-level `du /` scan; the focused storage diagnostic retains the deeper directory-size scan.
- Package installation path was hardened for both root shells and non-root sessions using `sudo` where required.

## v0.3.0 - 2026-08-16

### Added

- Phase 2 troubleshooting interface:
  - `ror diagnose` / `ror diag` for named diagnostic targets.
  - `ror collect` for timestamped, shareable diagnostic output files.
  - Diagnostic targets for SSH, TLS, DNS, storage/LVM, Java processes, and Tomcat in addition to system, network, and systemd collectors.
- Diagnostic safety contract and diagnostic toolkit index.
- Categorized discovery with `ror find --type ...` plus `ror search` alias.
- `ror path` for resolving repository resource locations.
- `ror cheatsheet` alias.
- OS-aware package helper (`lib/packages.sh`) with initial `troubleshooting`, `networking`, and `development` bundles.
- `ror pkg list`, `ror pkg suggest`, and explicit `ror pkg install` workflows.
- `ror doctor --install-suggestions`.
- `ror dotfiles status` inventory command.
- Troubleshooting runbooks for:
  - systemd services
  - SSH/SFTP connections
  - TLS certificates/chains
  - Java PKIX/truststores
  - full filesystems
  - network connectivity
- Reusable snippet content for Bash, Git, PowerShell, jq, networking, text processing, and common administration one-liners.
- Templates for Ansible playbooks, Docker Compose, Kubernetes Deployment/Service, logrotate, and systemd timers.
- README indexes for diagnostics, runbooks, snippets, and templates.

### Changed

- Root README now documents discovery, diagnostics/collection, templates, package bundles, and current diagnostic targets.
- Architecture documentation now defines collection behavior, package abstraction, aliases, safety constraints, and resource decision rules.
- `ror find` now groups results by resource type instead of returning an undifferentiated path list.
- Diagnostic collection deliberately excludes likely-secret process environment blocks.
- Package installation now works both from privileged root sessions and from non-root sessions using `sudo` when available.
- Generated `ror-collect-*.txt` diagnostic handoff files are ignored by Git so collecting from the repository directory does not dirty the worktree.

## v0.2.0 - 2026-08-16

### Added

- `cheat-sheets/` library and index, including subnetting plus Linux, networking, Ansible, containers/Kubernetes, Git/Bash, certificates/Java, and vSphere references.
- Functional `ror` CLI foundation with `doctor`, `info`, `find`, `cheat`, `run`, `new`, and safe fast-forward-only `update` commands.
- Top-level shared `lib/` helpers for common functions, OS detection, networking, and logging.
- Initial read-only diagnostics for system state, network state, and systemd services.
- Initial Bash and systemd service templates.
- Unix-like bootstrap installer and Windows PowerShell wrapper.
- Repository architecture and expanded philosophy documentation.
- Explicit `local/` policy for machine-specific state.

### Changed

- Moved shared implementation out of `bin/lib/` into top-level `lib/`.
- Removed the ambiguous `config/active/` local-state location in favor of `local/`.
- Hardened `.gitignore` for machine-local state and common credential/key/keystore file types.
- Root README changed from a minimal project description into the repository's navigation lobby.

## v0.1.0

### Added

- Initial repository scaffold.
