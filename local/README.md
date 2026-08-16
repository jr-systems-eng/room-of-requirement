# Local State

Everything under `local/` is machine-specific and must stay out of Git.

Recommended layout:

```text
local/
├── config/
├── overrides/
├── secrets/
├── cache/
└── state/
```

Use this area for host-specific configuration, generated state, local overrides, and sensitive material that should never be committed.

Portable examples belong under `config/examples/`; active machine-local copies belong here.
