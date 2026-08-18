# Configure an NFS Share

## Scope

Use this runbook to configure a Linux host as an NFS server and mount that export from another Linux host as an NFS client.

This procedure targets modern RHEL-family systems such as RHEL, Rocky Linux, and Oracle Linux 8/9/10 using NFSv4 and `firewalld`.

Example values used below:

| Role | Value |
|---|---|
| NFS server | `10.10.20.15` |
| NFS client | `10.10.20.25` |
| Server export | `/data/shared` |
| Client mountpoint | `/mnt/shared` |

Replace these values with the real addresses and paths before running the commands.

## How NFS behaves

The NFS server owns the original filesystem data. The client mounts the server export into its own directory tree.

For example:

```text
NFS server                      NFS client
/data/shared/file.txt  <---->   /mnt/shared/file.txt
```

The client path is not a separate copy. Reading, writing, renaming, or deleting the mounted file operates on the server-side file, subject to export and filesystem permissions.

## Safety notes

- Prefer NFSv4 on modern Linux systems.
- Restrict exports to specific client IPs or trusted subnets.
- Keep `root_squash` unless there is a reviewed requirement for client root to act as server root.
- Do not use `chmod 777` as a permissions workaround.
- NFS commonly relies on numeric UID/GID identity. Matching usernames with different UIDs/GIDs can still cause permission failures.
- Test `/etc/fstab` changes before rebooting.

# Server procedure

## 1. Install NFS utilities

```bash
sudo dnf install -y nfs-utils
```

## 2. Create the directory to export

```bash
sudo mkdir -p /data/shared
```

Optionally create a simple test file:

```bash
echo "Hello from the NFS server" | sudo tee /data/shared/test.txt
```

Verify the directory and test file:

```bash
ls -ld /data/shared
ls -l /data/shared
cat /data/shared/test.txt
```

## 3. Configure the export

Edit `/etc/exports`:

```bash
sudo vi /etc/exports
```

To permit one client:

```text
/data/shared 10.10.20.25(rw,sync,root_squash)
```

To permit a trusted subnet instead:

```text
/data/shared 10.10.20.0/24(rw,sync,root_squash)
```

Common options:

- `rw` - allow reads and writes.
- `sync` - acknowledge writes after they are committed.
- `root_squash` - map client UID 0 to an unprivileged identity on the server.

## 4. Enable and start the NFS server

```bash
sudo systemctl enable --now nfs-server
```

Check service state:

```bash
sudo systemctl status nfs-server --no-pager -l
```

## 5. Load and inspect the exports

```bash
sudo exportfs -rav
sudo exportfs -v
```

Confirm the expected path and client restriction appear in the output.

## 6. Open NFS in firewalld

For a normal NFSv4 setup:

```bash
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --reload
```

Verify:

```bash
sudo firewall-cmd --list-services
```

## 7. Confirm NFS is listening

```bash
sudo ss -lntp | grep ':2049'
```

Additional RPC visibility is available with:

```bash
rpcinfo -p localhost
```

# Client procedure

## 1. Install NFS utilities

```bash
sudo dnf install -y nfs-utils
```

## 2. Create the local mountpoint

```bash
sudo mkdir -p /mnt/shared
```

The mountpoint is only the local location where the remote export will appear.

## 3. Check server reachability

Basic network test:

```bash
ping -c 3 10.10.20.15
```

Test NFS TCP port 2049:

```bash
nc -vz 10.10.20.15 2049
```

A successful TCP connection confirms the client can reach the NFS listener. It does not by itself prove the export or permissions are correct.

## 4. Mount the export manually

Test NFSv4 explicitly first:

```bash
sudo mount -t nfs -o vers=4 \
  10.10.20.15:/data/shared \
  /mnt/shared
```

## 5. Verify the negotiated mount

```bash
findmnt /mnt/shared
nfsstat -m
```

`nfsstat -m` is especially useful because it shows the NFS version and options that were actually negotiated.

## 6. Verify file access

```bash
ls -la /mnt/shared
cat /mnt/shared/test.txt
```

Expected test-file content:

```text
Hello from the NFS server
```

## 7. Demonstrate a local copy

Copy a remote file into a local filesystem:

```bash
cp /mnt/shared/test.txt /tmp/nfs-test.txt
```

Verify:

```bash
ls -l /tmp/nfs-test.txt
cat /tmp/nfs-test.txt
```

`/tmp/nfs-test.txt` is now an independent local copy. The original `/mnt/shared/test.txt` remains remote.

## 8. Test client writes

First inspect the server-side directory permissions:

```bash
ls -ld /data/shared
```

If the client user has permission to write, create a file from the client:

```bash
echo "Created from the client" > /mnt/shared/client-test.txt
```

Then verify on the server:

```bash
cat /data/shared/client-test.txt
```

Expected content:

```text
Created from the client
```

This confirms that the client path and server path refer to the same remote filesystem data.

# Make the client mount persistent

## 1. Back up `/etc/fstab`

```bash
sudo cp -a /etc/fstab /etc/fstab.$(date +%Y%m%d-%H%M%S).bak
```

## 2. Add the NFS mount

A straightforward persistent mount:

```fstab
10.10.20.15:/data/shared /mnt/shared nfs defaults,_netdev 0 0
```

For a non-critical mount where boot should continue if the server is unavailable, a systemd automount is often preferable:

```fstab
10.10.20.15:/data/shared /mnt/shared nfs defaults,_netdev,nofail,x-systemd.automount 0 0
```

Relevant options:

- `_netdev` - identifies the filesystem as network-dependent.
- `nofail` - allows boot to continue if the mount cannot be established.
- `x-systemd.automount` - creates an automount unit and establishes the NFS mount when the path is accessed.

## 3. Validate `/etc/fstab` before rebooting

If the share is currently mounted manually:

```bash
sudo umount /mnt/shared
```

Reload systemd configuration and test:

```bash
sudo systemctl daemon-reload
sudo mount -a
```

If using `x-systemd.automount`, access the path to trigger the mount:

```bash
ls /mnt/shared
```

Then verify:

```bash
findmnt /mnt/shared
nfsstat -m
```

Do not reboot until the expected mount behavior has been confirmed.

# UID/GID and permission validation

NFS commonly evaluates filesystem access using numeric UID and GID values rather than username text alone.

Check the relevant account on both systems:

```bash
id <username>
getent passwd <username>
getent group <groupname>
```

For example, these are aligned:

```text
Server: appuser UID 1001 GID 1001
Client: appuser UID 1001 GID 1001
```

These are not aligned even though the username matches:

```text
Server: appuser UID 1001 GID 1001
Client: appuser UID 2001 GID 2001
```

When permissions behave unexpectedly, compare numeric ownership:

```bash
ls -ln /data/shared
ls -ln /mnt/shared
```

Prefer correcting identity/ownership design over weakening filesystem permissions.

# Troubleshooting

## Client cannot reach NFS port

Client:

```bash
ip route get 10.10.20.15
nc -vz 10.10.20.15 2049
```

Server:

```bash
sudo ss -lntp | grep ':2049'
sudo firewall-cmd --list-all
sudo systemctl status nfs-server --no-pager -l
```

## Export is missing or incorrect

Server:

```bash
sudo exportfs -v
sudo exportfs -rav
```

Re-check `/etc/exports` syntax and client IP/subnet restrictions.

## Mount fails

Client:

```bash
sudo mount -v -t nfs -o vers=4 \
  10.10.20.15:/data/shared \
  /mnt/shared

journalctl -k --no-pager | grep -i nfs
```

Server:

```bash
journalctl -u nfs-server --no-pager -n 100
```

## Mount works but access is denied

Check numeric identities and permissions on both hosts:

```bash
id <username>
ls -lnd /data/shared
ls -ln /data/shared
ls -lnd /mnt/shared
ls -ln /mnt/shared
```

Also verify the export is read/write when writes are expected:

```bash
sudo exportfs -v
```

Do not immediately change to `no_root_squash` or world-writable permissions as a workaround.

## `showmount -e` does not show the export

`showmount -e <server>` is commonly useful with NFSv3-style export discovery, but it is not a reliable validation method for every pure NFSv4 configuration.

Prefer validating the server with:

```bash
sudo exportfs -v
```

and validating from the client with a direct NFSv4 mount attempt.

# Validation checklist

A working configuration should satisfy all of the following:

- `nfs-server` is active on the server.
- `exportfs -v` shows the intended export and allowed client/subnet.
- TCP port 2049 is reachable from the client.
- The manual NFSv4 mount succeeds.
- `findmnt` shows the expected server export at the expected client mountpoint.
- `nfsstat -m` shows the expected NFS version/options.
- The client can read an existing server-side test file.
- If writes are required, the client can create a file and the same file appears on the server.
- UID/GID ownership is appropriate for the users or applications accessing the share.
- The `/etc/fstab` entry has been tested before rebooting.

# Rollback

On the client, unmount the share:

```bash
sudo umount /mnt/shared
```

Remove or comment the corresponding `/etc/fstab` entry and reload systemd if needed:

```bash
sudo systemctl daemon-reload
```

On the server, remove or comment the export from `/etc/exports`, then reload exports:

```bash
sudo exportfs -rav
```

If the server no longer provides any NFS exports, disable the service if appropriate:

```bash
sudo systemctl disable --now nfs-server
```

Remove the firewalld NFS service only if no other export requires it:

```bash
sudo firewall-cmd --permanent --remove-service=nfs
sudo firewall-cmd --reload
```
