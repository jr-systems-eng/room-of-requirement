# Linux Users, Groups, and Permissions

Quick reference for account state, ownership, sudo access, and permission troubleshooting.

## Identify users and groups

```bash
id
id username
whoami
getent passwd username
getent group groupname
groups username
```

## Account state

```bash
passwd -S username
chage -l username
last username
lastlog -u username
getent shadow username
```

Common checks:

```bash
sudo passwd -S username
sudo faillock --user username
sudo faillock --user username --reset
```

## Create / modify accounts

```bash
useradd -m username
usermod -aG wheel username
usermod -s /bin/bash username
passwd username
userdel username
userdel -r username
```

## Ownership and permissions

```bash
ls -ld path
stat path
chown user:group file
chown -R user:group directory
chmod 644 file
chmod 755 directory
chmod -R u+rwX,go+rX directory
```

Typical permissions:

```text
600  rw-------    private file/key
640  rw-r-----    service config/log
644  rw-r--r--    normal file
700  rwx------    private directory/script
750  rwxr-x---    restricted directory
755  rwxr-xr-x    normal directory/executable
```

## Numeric permission math

```text
4 = read
2 = write
1 = execute

7 = rwx
6 = rw-
5 = r-x
4 = r--
```

## Sudo

```bash
sudo -l
sudo -l -U username
visudo
visudo -f /etc/sudoers.d/example
```

Validate sudoers before relying on it:

```bash
visudo -c
```

## ACLs

```bash
getfacl path
setfacl -m u:username:rwx path
setfacl -m g:groupname:rx path
setfacl -x u:username path
setfacl -b path
```

## SELinux context checks

```bash
ls -lZ path
getenforce
restorecon -Rv /path
```

## Find permission problems

```bash
namei -l /full/path/to/file
find /path -not -user expecteduser
find /path -type f -perm /022
find /path -type d -perm /002
```

`namei -l` is especially useful when a user can access a file but cannot traverse one of its parent directories.
