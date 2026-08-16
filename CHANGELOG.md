# Changelog

Notable changes to Room of Requirement are recorded here. The project uses the changelog to track capability-level changes rather than every individual file edit.

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
