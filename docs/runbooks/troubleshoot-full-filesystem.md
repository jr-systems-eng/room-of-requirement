# Troubleshoot a Full Filesystem

## Symptoms

- `No space left on device`
- Application cannot write logs/temp/data.
- Filesystem remains full after deleting files.
- Inode exhaustion despite free capacity.

## Safety

Do not immediately delete unfamiliar files. First identify the filesystem, growth source, retention policy, and whether deleted files are still held open.

## First checks

```bash
ror diagnose storage
```

Focused commands:

```bash
df -hT
df -hi
findmnt
lsblk -f
```

## Is it blocks or inodes?

- `df -h` near 100% -> capacity issue.
- `df -i` near 100% -> too many files/inodes.

## Find the growth source

Stay on the affected filesystem with `-x`:

```bash
du -x -h --max-depth=1 /path | sort -h
du -x -ah /path | sort -h | tail -n 50
find /path -xdev -type f -size +1G -printf '%s %p\n' | sort -n
```

For inode pressure:

```bash
find /path -xdev -type f | awk -F/ '{print $1"/"$2"/"$3}' | sort | uniq -c | sort -nr | head
```

Adjust the grouping depth for the path being investigated.

## Deleted files still consuming space

```bash
lsof +L1
```

If a large deleted file is still open, the space is not reclaimed until the owning process closes the file. Prefer a controlled service restart/reload when appropriate rather than killing processes blindly.

## Logs

```bash
journalctl --disk-usage
find /var/log -type f -printf '%s %p\n' 2>/dev/null | sort -n | tail
```

Check logrotate configuration before manual cleanup.

## LVM growth path

```bash
pvs
vgs
lvs
lsblk
findmnt <mountpoint>
```

Confirm there is free VG space before extending. Then identify filesystem type (`xfs`, `ext4`, etc.) and use the correct grow operation. Never shrink XFS.

## Validation

```bash
df -hT <mountpoint>
df -hi <mountpoint>
```

Confirm the application can write again and that the underlying growth cause is addressed, not merely postponed.
