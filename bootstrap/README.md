# Bootstrap

Safe setup helpers for making Room of Requirement usable on a new machine.

Bootstrap is intentionally conservative: **no packages or dotfiles are changed unless explicitly requested**.

## Unix-like systems

From the repository root:

```bash
bash bootstrap/install.sh
```

The default bootstrap:

- creates `~/.local/bin` if needed;
- creates a small executable `ror` wrapper under `~/.local/bin`;
- leaves tracked repository file modes/content unchanged;
- does not install packages;
- does not alter dotfiles;
- runs the read-only `ror doctor` check.

### Opt-in workstation setup

```bash
bash bootstrap/install.sh --profile minimal
bash bootstrap/install.sh --profile linux-admin --dotfiles bash --dotfiles git
bash bootstrap/install.sh --dotfiles all
```

Options:

```text
--profile PROFILE   install one ROR package profile
--dotfiles GROUP    install a managed dotfile group; repeatable
--no-doctor         skip the final read-only doctor check
```

Package and dotfile installation remain explicit mutations even when invoked through bootstrap. Dotfile installation creates a rollback snapshot before touching user files.

If `~/.local/bin` is not in `PATH`, add it explicitly to your shell profile or install the managed Bash dotfile fragment after reviewing it.

## Windows

From PowerShell:

```powershell
.\bootstrap\install.ps1
```

The Windows implementation creates `~/.local/bin/ror.ps1` and uses an available Bash environment such as Git Bash or WSL for the shared ROR CLI.

Optional setup can be requested explicitly:

```powershell
.\bootstrap\install.ps1 -PackageProfile minimal
.\bootstrap\install.ps1 -PackageProfile linux-admin -Dotfiles bash,git
.\bootstrap\install.ps1 -Dotfiles all
```

Use `-NoDoctor` to skip the final read-only check.

## Recommended first-machine workflow

```bash
ror doctor
ror pkg list
ror pkg suggest linux-admin
ror dotfiles status
ror dotfiles diff all
```

Only after reviewing the suggestions/diff:

```bash
ror pkg install linux-admin
ror dotfiles install all
```

Rollback remains available with:

```bash
ror dotfiles backups
ror dotfiles restore latest
```
