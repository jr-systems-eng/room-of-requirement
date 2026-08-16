# Bootstrap

Safe setup helpers for making Room of Requirement usable on a new machine.

## Unix-like systems

From the repository root:

```bash
bash bootstrap/install.sh
```

This currently:

- creates `~/.local/bin` if needed;
- creates a small executable `ror` wrapper under `~/.local/bin` that invokes the repository's shared Bash implementation;
- leaves tracked repository file modes and content unchanged, so bootstrap does not dirty the Git working tree;
- does not overwrite shell profiles or other user configuration.

If `~/.local/bin` is not in `PATH`, add it explicitly to your shell profile.

## Windows

From PowerShell:

```powershell
.\bootstrap\install.ps1
```

The current Windows implementation creates a PowerShell wrapper under `~/.local/bin` and uses an available Bash environment such as Git Bash or WSL for the shared `ror` implementation.

## Future platform bootstrap

Platform-specific dependency installation belongs under this directory, but should remain explicit and safe. Bootstrap must never silently replace existing user configuration.
