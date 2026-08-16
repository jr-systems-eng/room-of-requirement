# RPM and DNF

Quick-reference for package discovery, ownership, repositories, upgrades, rollback investigation, and EL-family troubleshooting.

## Package queries

```bash
rpm -qa | sort
rpm -q PACKAGE
rpm -qi PACKAGE
rpm -ql PACKAGE
rpm -qc PACKAGE
rpm -qf /path/to/file
rpm -V PACKAGE
```

Find what package provides a file/command:

```bash
dnf provides '*/javap'
dnf provides /usr/bin/COMMAND
```

## DNF basics

```bash
dnf search TERM
dnf info PACKAGE
dnf list installed
dnf list available
dnf install PACKAGE
dnf remove PACKAGE
dnf upgrade
dnf upgrade PACKAGE
dnf check-update
```

## Repositories

```bash
dnf repolist
dnf repolist --all
dnf repoinfo REPOID
dnf --disablerepo='*' --enablerepo=REPOID list available
```

Temporary repo selection:

```bash
dnf --disablerepo='*' --enablerepo=REPOID install PACKAGE
```

## History and transaction inspection

```bash
dnf history
dnf history info ID
dnf history list PACKAGE
dnf history undo ID
dnf history redo ID
```

Treat `dnf history undo` carefully: rollback may be impossible if old package versions are no longer available or dependencies changed.

## Version locking

```bash
dnf install 'dnf-command(versionlock)'
dnf versionlock add PACKAGE
dnf versionlock list
dnf versionlock delete PACKAGE
```

## RPM files directly

Inspect without installing:

```bash
rpm -qpi package.rpm
rpm -qpl package.rpm
```

Install/upgrade with RPM only when appropriate:

```bash
rpm -Uvh package.rpm
```

Prefer `dnf install ./package.rpm` because it resolves dependencies.

## Package ownership troubleshooting

```bash
command -v COMMAND
rpm -qf "$(command -v COMMAND)"
dnf provides '*/COMMAND'
```

## Clean metadata/cache

```bash
dnf clean all
dnf makecache
```

## Kernel packages on EL

```bash
rpm -qa 'kernel*' | sort
uname -r
grubby --default-kernel
grubby --info=ALL
```

## Quick package troubleshooting flow

```text
1. rpm -q PACKAGE                   installed?
2. dnf info PACKAGE                 candidate/version?
3. dnf repolist                    expected repos enabled?
4. dnf provides PATH               package ownership/discovery
5. dnf history info ID             what changed?
6. rpm -V PACKAGE                  changed/missing packaged files?
```
