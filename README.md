# Room of Requirement

> **Always equipped for the seeker's needs.**

A portable engineering toolbox for unfamiliar systems: quick references, diagnostics, reusable scripts, templates, dotfiles, and bootstrap helpers that can travel with you from machine to machine.

## I need to...

| Need | Go to |
|---|---|
| Remember a command or concept | [`cheat-sheets/`](cheat-sheets/README.md) |
| Copy/paste a reusable fragment | [`snippets/`](snippets/) |
| Run a complete utility | [`scripts/`](scripts/) |
| Create something from a known-good starting point | [`templates/`](templates/) |
| Configure my shell/tools | [`dotfiles/`](dotfiles/) |
| Follow or understand a procedure | [`docs/`](docs/) |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/) |
| Keep machine-specific state | [`local/`](local/README.md) |

## The `ror` command

`bin/ror` is the front door to the repository.

```bash
ror doctor
ror info
ror find ssh
ror cheat subnetting
ror run diagnostics/system-info.sh
ror run diagnostics/systemd-service.sh sshd
ror new systemd/service.service ./myapp.service
ror update
```

### Bootstrap on Linux/macOS/WSL

```bash
git clone <this-repository>
cd room-of-requirement
bash bootstrap/install.sh
ror doctor
```

### Bootstrap on Windows

Run from PowerShell after cloning:

```powershell
.\bootstrap\install.ps1
```

The current Windows wrapper uses Bash (for example Git Bash or WSL) to run the shared `ror` implementation.

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** diagnostics and discovery are read-only by default.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific state belong under `local/`, never Git.
- **Discoverable:** `ror find` should help locate useful resources quickly.

See [Philosophy](docs/philosophy.md) and [Architecture](docs/architecture.md) for the repository contracts and design model.

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Architecture](docs/architecture.md)
- [Philosophy](docs/philosophy.md)
- [Local-state policy](local/README.md)
