# Extend an LVM Filesystem

## Scope

Use this runbook when a Linux filesystem backed by an LVM logical volume needs more space.

This procedure assumes the existing filesystem is healthy and focuses on extending an existing LV and filesystem. It does not cover shrinking filesystems or replacing failed storage.

## Safety notes

- Identify the exact mountpoint, filesystem type, LV, VG, and PV before changing anything.
- Confirm backups/rollback expectations for the workload.
- Do not guess device names from memory.
- XFS cannot be shrunk; this runbook only grows filesystems.
- Verify free extents in the VG before extending the LV.
- If the underlying disk/LUN must be enlarged first, confirm the hypervisor/cloud/storage change before touching LVM.

## 1. Capture current storage state

```bash
ror diagnose storage
```

Then identify the target mount:

```bash
findmnt /__MOUNTPOINT__
df -hT /__MOUNTPOINT__
lsblk -f
```

Inspect LVM:

```bash
sudo pvs
sudo vgs
sudo lvs -a -o +devices
```

Record:

- mountpoint;
- filesystem type (`xfs`, `ext4`, etc.);
- LV path;
- VG name;
- current LV size;
- VG free space.

## 2. Confirm the mapping

Example:

```text
/dev/mapper/vgdata-lvapp -> /dev/vgdata/lvapp -> /app
```

Verify with:

```bash
findmnt -no SOURCE,FSTYPE /__MOUNTPOINT__
sudo lvs -o lv_name,vg_name,lv_size,devices
```

Do not continue until the mountpoint and LV mapping are unambiguous.

## 3. Decide where capacity will come from

### Existing VG free space

If `vgs` already shows enough `VFree`, continue to the LV extension step.

### Enlarged existing PV

If the virtual disk/LUN was increased and the partition/PV now has additional capacity, confirm the OS sees the new device size:

```bash
lsblk
```

If the PV occupies the whole device and the device is already larger, resize the PV:

```bash
sudo pvresize /dev/__PV_DEVICE__
```

If a partition must be enlarged first, use the platform-approved partition-growth procedure and verify the partition boundary before `pvresize`.

### New PV

When adding a new disk/LUN:

```bash
sudo pvcreate /dev/__NEW_DEVICE__
sudo vgextend __VG_NAME__ /dev/__NEW_DEVICE__
```

Use the correct approved device/partition path.

## 4. Re-check VG free space

```bash
sudo pvs
sudo vgs
```

Confirm the expected amount of free space is now available.

## 5. Extend the logical volume

Grow by a fixed amount:

```bash
sudo lvextend -L +__SIZE__ /dev/__VG_NAME__/__LV_NAME__
```

Example placeholder:

```text
+20G
```

Or consume all remaining free extents when that is explicitly intended:

```bash
sudo lvextend -l +100%FREE /dev/__VG_NAME__/__LV_NAME__
```

Do not use `+100%FREE` merely for convenience if the VG should retain space for other LVs.

Verify:

```bash
sudo lvs
```

## 6. Grow the filesystem

Determine filesystem type again:

```bash
findmnt -no FSTYPE /__MOUNTPOINT__
```

### XFS

Grow the mounted filesystem using the mountpoint:

```bash
sudo xfs_growfs /__MOUNTPOINT__
```

### ext4

Grow the filesystem using the block device/LV:

```bash
sudo resize2fs /dev/__VG_NAME__/__LV_NAME__
```

Do not run a filesystem-specific growth command against the wrong filesystem type.

## 7. Validate

```bash
df -hT /__MOUNTPOINT__
findmnt /__MOUNTPOINT__
sudo lvs
sudo vgs
```

Confirm:

- the LV is the intended new size;
- the filesystem reflects the additional space;
- the mount remains active;
- the application can still read/write normally.

## Optional combined LVM/filesystem growth

`lvextend -r` can invoke filesystem resizing automatically on supported configurations:

```bash
sudo lvextend -r -L +__SIZE__ /dev/__VG_NAME__/__LV_NAME__
```

For high-change or unfamiliar systems, the separate LV-then-filesystem steps above are easier to inspect and troubleshoot.

## Troubleshooting

### LV grew but filesystem did not

Re-check filesystem type and run the correct filesystem growth command.

### `vgs` shows no free space

Confirm whether the underlying PV can be enlarged or a new PV should be added. Do not extend an LV until the VG actually has free extents.

### OS does not see the enlarged disk

Re-scan using the platform/storage-specific method or reboot only if required by the environment. Verify `lsblk` before changing LVM.

### Unexpected device mapping

Stop and reconcile `findmnt`, `lsblk`, `pvs`, `vgs`, and `lvs -o +devices`. Do not proceed based on a guessed mapper name.

## Rollback considerations

Growing an LV/filesystem is generally not reversed casually. XFS cannot be shrunk. Treat the pre-change mapping, requested size, storage allocation, and backups as the rollback boundary. If the wrong LV was extended but the filesystem has not yet been grown, stop and evaluate before any further changes rather than attempting an improvised shrink.
