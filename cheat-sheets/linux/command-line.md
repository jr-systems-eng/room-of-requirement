# Linux Command Line

Fast reference for the commands that come up constantly during Linux administration and troubleshooting.

## Files and directories

```bash
pwd                         # Current directory
ls -lah                     # Detailed listing, including hidden files
ls -ltr                     # Oldest -> newest by modification time
cd /path/to/dir
mkdir -p /path/to/new/dir
cp -a source dest           # Preserve attributes
mv old new
rm -i file                  # Interactive delete
stat file                   # Ownership, perms, timestamps, inode
file filename               # Detect file type
readlink -f path            # Resolve full path/symlinks
```

## Find files

```bash
find /path -name 'file.txt'
find /path -iname '*tomcat*'
find /path -type f -mtime -1              # Modified within 1 day
find /path -type f -size +1G
find /path -type f -user username
find /path -type f -perm /022             # Group/other writable
find /path -type f -exec grep -l 'text' {} +
```

## Search text

```bash
grep 'text' file
grep -i 'text' file                        # Ignore case
grep -n 'text' file                        # Line numbers
grep -w 'word' file                        # Whole word
grep -RIn 'text' /path                     # Recursive
grep -E 'error|failed|denied' file         # Extended regex
grep -A 5 -B 5 'ERROR' file               # Context
```

## View large files

```bash
less file
less +G file                               # Open at end
head -n 50 file
tail -n 50 file
tail -f file
tail -F file                               # Follow across rotation
sed -n '100,150p' file                    # Lines 100-150
```

Useful `less` keys:

```text
/term     search forward
?term     search backward
n / N     next / previous match
g / G     top / bottom
50g       go to line 50
q         quit
```

## Sort, count, and extract

```bash
sort file
sort -u file
uniq -c
wc -l file
cut -d: -f1 /etc/passwd
awk -F: '{print $1, $3}' /etc/passwd
tr ':' '\n'
column -t -s '|'
```

Common pipeline:

```bash
grep -Ei 'error|fail' app.log | sort | uniq -c | sort -nr
```

## Archives

```bash
tar -czf archive.tgz directory/
tar -xzf archive.tgz
tar -tzf archive.tgz                       # List without extracting
zip -r archive.zip directory/
unzip archive.zip
unzip -l archive.zip
```

## Command discovery

```bash
command -v ssh
which ssh
type cd
man ssh
ssh --help
history | grep ssh
```

## Shell shortcuts

```text
Ctrl-R      search command history
Ctrl-A      beginning of line
Ctrl-E      end of line
Ctrl-U      delete to beginning
Ctrl-K      delete to end
Ctrl-W      delete previous word
Ctrl-L      clear screen
!!          previous command
!$          last argument of previous command
```
