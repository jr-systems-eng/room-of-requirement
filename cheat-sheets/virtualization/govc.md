# govc / vSphere CLI

Quick-reference for common vSphere/GCVE inspection and VM operations with `govc`.

## Environment variables

Typical variables:

```bash
export GOVC_URL='https://vcenter.example.com'
export GOVC_USERNAME='user@example.com'
export GOVC_INSECURE=1
```

Avoid storing `GOVC_PASSWORD` in shell history or committed files.

Prompt for it safely in an interactive shell:

```bash
read -rsp 'vCenter password: ' GOVC_PASSWORD; echo
export GOVC_PASSWORD
```

Clear afterward:

```bash
unset GOVC_PASSWORD
```

## Connection test

```bash
govc about
govc session.ls
```

## Inventory discovery

```bash
govc ls
govc ls /Datacenter
govc find /
govc find / -type m
govc find / -type h
govc find / -type s
```

Object types commonly used:

```text
m  virtual machine
h  host
s  datastore
n  network
```

## VM information

```bash
govc vm.info VMNAME
govc vm.info -json VMNAME
govc device.info -vm VMNAME
```

## Power operations

```bash
govc vm.power -on VMNAME
govc vm.power -off VMNAME
govc vm.power -reset VMNAME
govc vm.power -suspend VMNAME
```

Guest shutdown (requires VMware Tools):

```bash
govc vm.power -s VMNAME
```

## Datastores

```bash
govc datastore.info
govc datastore.info DATASTORE
govc datastore.ls DATASTORE/
```

Upload a file:

```bash
govc datastore.upload local.iso destination/path.iso
```

## VM disks

List devices:

```bash
govc device.ls -vm VMNAME
govc device.info -vm VMNAME
```

Add a disk:

```bash
govc vm.disk.create -vm VMNAME -name diskname -size 20G
```

Disk operations can be destructive; verify the target VM and existing devices before modifying them.

## Networks

```bash
govc ls /DATACENTER/network
govc find / -type n
govc vm.network.info -vm VMNAME
```

## Snapshots

```bash
govc snapshot.tree -vm VMNAME
govc snapshot.create -vm VMNAME SNAPSHOT_NAME
govc snapshot.remove -vm VMNAME SNAPSHOT_NAME
```

## Guest info

When VMware Tools is available:

```bash
govc vm.info VMNAME
```

Look for guest hostname/IP and Tools state in the output.

## Useful discovery pattern

```bash
govc find / -name '*partial-name*'
```

## Safe workflow before a change

```text
1. govc about
2. govc find / -name 'VMNAME'
3. govc vm.info VMNAME
4. govc device.info -vm VMNAME
5. Perform change
6. govc vm.info / device.info again
7. Verify inside guest OS separately
```

Remember: expanding a virtual disk in vSphere only changes the virtual hardware. The guest may still need partition, PV/LVM, and filesystem expansion.
