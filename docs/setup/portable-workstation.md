# Portable Workstation Setup

Use this workflow when bringing Room of Requirement onto a new workstation, jumpbox, lab host, or other interactive machine.

The guiding rule is **inspect first, mutate second, keep rollback available**.

## 1. Bootstrap ROR

```bash
git clone <repository-url>
cd room-of-requirement
bash bootstrap/install.sh
```

Bootstrap installs the `ror` wrapper and runs the read-only doctor. It does not install packages or modify dotfiles unless explicit bootstrap options are supplied.

## 2. Inspect the host

```bash
ror doctor
ror pkg list
ror dotfiles status
```

For a broader handoff/intake report:

```bash
ror collect baseline
```

## 3. Review a package profile

For a general Linux administration machine:

```bash
ror pkg suggest linux-admin
```

Other profiles include:

```text
minimal
troubleshooting
networking
linux-admin
development
ansible
containers
kubernetes
cloud
```

`suggest` is read-only. It shows package-manager-translated packages that are missing and separately lists external/vendor-specific tools ROR will not install automatically.

When ready:

```bash
ror pkg install linux-admin
```

Package installation is an explicit mutating action.

## 4. Review dotfile changes

```bash
ror dotfiles diff all
```

Or inspect one group:

```bash
ror dotfiles diff bash
ror dotfiles diff git
ror dotfiles diff tmux
```

ROR does not replace whole configuration files. It copies managed fragments under `~/.config/ror/` and adds marked include/source blocks to the existing host files.

## 5. Install managed dotfiles

Install selected groups:

```bash
ror dotfiles install bash
ror dotfiles install git
ror dotfiles install tmux
```

Or all groups supported by the current platform:

```bash
ror dotfiles install all
```

Each install operation creates a rollback snapshot before changing anything and prints the exact backup ID.

## 6. Verify

```bash
ror dotfiles status
ror doctor
```

Expected states for an installed group are:

```text
managed=current
integration=linked
```

## 7. Local customization

Do not edit the ROR-managed fragment for machine-specific settings. Put local customizations in:

```text
~/.config/ror/local/bashrc
~/.config/ror/local/powershell_profile.ps1
```

Examples include work-only aliases, private paths, host-specific environment variables, and settings that should not be committed.

## 8. Roll back

List snapshots:

```bash
ror dotfiles backups
```

Restore the most recent install exactly:

```bash
ror dotfiles restore latest
```

Or restore a specific snapshot:

```bash
ror dotfiles restore <backup-id>
```

Files that existed before the install are restored from backup. Managed files that did not previously exist are removed.

## One-command opt-in bootstrap

Once comfortable with the behavior, a new Unix-like machine can be initialized explicitly with:

```bash
bash bootstrap/install.sh \
  --profile linux-admin \
  --dotfiles bash \
  --dotfiles git \
  --dotfiles tmux
```

On Windows PowerShell with Bash available:

```powershell
.\bootstrap\install.ps1 -PackageProfile linux-admin -Dotfiles bash,git
```

These shortcuts preserve the same package and dotfile safety rules; they only combine explicitly requested steps.
