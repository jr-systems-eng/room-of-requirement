# Linux Storage and Filesystems

Quick-reference for disks, filesystems, mounts, space usage, LVM, and expansion work.

## Discover disks and filesystems

```bash
lsblk
lsblk -f
blkid
findmnt
findmnt /mountpoint
df -hT
du -sh /path
du -xhd1 /path | sort -h
```

## Disk and partition details

```bash
fdisk -l
parted -l
parted /dev/sdb print
```

## Mounts

```bash
mount
mount /dev/sdb1 /mnt/data
umount /mnt/data
findmnt --verify
```

Persistent mounts live in:

```text
/etc/fstab
```

Prefer UUIDs:

```bash
blkid /dev/sdb1
```

Example:

```fstab
UUID=<uuid>  /data  xfs  defaults  0 0
```

Test before rebooting:

```bash
mount -a
findmnt --verify
```

## Filesystem usage vs inode usage

```bash
df -h
df -i
```

If `df -h` has space but writes fail, check `df -i` for inode exhaustion.

## Find large files

```bash
find / -xdev -type f -size +1G -ls 2>/dev/null
find /var -xdev -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head
```

## Open deleted files consuming space

```bash
lsof +L1
```

## LVM discovery

```bash
pvs
vgs
lvs
lsblk
```

## Expand an LVM-backed filesystem

After increasing the virtual/physical disk:

```bash
lsblk
partprobe /dev/sdX
```

If the PV is a partition:

```bash
growpart /dev/sdX N
pvresize /dev/sdXN
```

Then:

```bash
lvextend -r -l +100%FREE /dev/VG/LV
```

`-r` grows the filesystem with the LV.

Or explicitly:

```bash
lvextend -L +20G /dev/VG/LV
xfs_growfs /mountpoint        # XFS
resize2fs /dev/VG/LV          # ext4
```

## XFS

```bash
xfs_info /mountpoint
xfs_growfs /mountpoint
```

XFS can grow online but cannot shrink.

## ext4

```bash
tune2fs -l /dev/device
resize2fs /dev/device
```

## SMART health

```bash
smartctl -a /dev/sdX
smartctl -H /dev/sdX
smartctl -t short /dev/sdX
smartctl -t long /dev/sdX
```

Pay particular attention to:

```text
Reallocated_Sector_Ct
Current_Pending_Sector
Offline_Uncorrectable
UDMA_CRC_Error_Count
Temperature
Power_On_Hours
```

## Quick expansion workflow

```text
1. Confirm device: lsblk -f
2. Expand disk at hypervisor/cloud layer
3. Re-scan / confirm new size
4. Grow partition if present
5. pvresize if using LVM
6. lvextend
7. Grow filesystem
8. Verify with df -hT and lsblk
```
