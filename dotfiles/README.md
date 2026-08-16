# Dotfiles

Portable managed configuration fragments for making an unfamiliar machine comfortable without replacing the host's existing configuration wholesale.

## Safety model

`ror dotfiles install` uses **include/source blocks** rather than replacing entire user files:

- Bash -> managed fragment under `~/.config/ror/bashrc`, sourced from `~/.bashrc`.
- Readline -> managed fragment under `~/.config/ror/inputrc`, included from `~/.inputrc`.
- Git -> managed fragment under `~/.config/ror/gitconfig`, included from `~/.gitconfig`.
- tmux -> managed fragment under `~/.config/ror/tmux.conf`, sourced from `~/.tmux.conf`.
- PowerShell -> managed fragment under `~/.config/ror/powershell_profile.ps1`, dot-sourced from the user's PowerShell profile when PowerShell is available.

Every touched file is backed up before installation. Backups are stored under:

```text
${XDG_STATE_HOME:-~/.local/state}/ror/dotfiles-backups/
```

Use `ROR_STATE_HOME` to override the state location for testing or special environments.

## Commands

```bash
ror dotfiles status
ror dotfiles diff all
ror dotfiles diff bash
ror dotfiles install bash
ror dotfiles install git
ror dotfiles install tmux
ror dotfiles install powershell
ror dotfiles install all
ror dotfiles backups
ror dotfiles restore latest
ror dotfiles restore <backup-id>
```

`install` is explicit and mutating. `status` and `diff` are read-only.

## Local overrides

Machine-specific shell/PowerShell customization belongs outside Git:

```text
~/.config/ror/local/bashrc
~/.config/ror/local/powershell_profile.ps1
```

This is the place for work-only aliases, host-specific environment variables, paths, or other settings that should not travel with the repository.

## What is intentionally not managed

- Git user name/email or credentials.
- SSH private keys or host-specific SSH configuration.
- Bash login profile replacement. `bash/bash_profile` is an optional reference pattern only.
- Windows line-ending policy. `windows/gitconfig` is an optional Windows-specific overlay, not part of the shared Git install.
