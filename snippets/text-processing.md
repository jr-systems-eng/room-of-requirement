# Text Processing Snippets

## grep

```bash
grep -n 'text' file
grep -i 'text' file
grep -w 'word' file
grep -RIn 'text' /path
grep -E 'error|failed|denied' file
grep -B3 -A8 'ERROR' file
```

## awk

```bash
# First field
awk '{print $1}' file

# Colon-delimited fields
awk -F: '{print $1, $3}' /etc/passwd

# Numeric filter
awk '$5 > 90 {print}' file

# Header + matching rows
awk 'NR==1 || /FAILED/' report.txt
```

## sed

```bash
# Print line range
sed -n '100,150p' file

# Replace first match per line
sed 's/old/new/' file

# Replace all matches
sed 's/old/new/g' file

# Delete blank/comment lines
sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' file
```

## sort / uniq

```bash
sort file
sort -u file
sort -n numbers.txt
sort -h sizes.txt
sort | uniq -c | sort -nr
```

## cut

```bash
cut -d: -f1 /etc/passwd
cut -d',' -f1,3 file.csv
```

## tr

```bash
tr ':' '\n' < file
tr '[:lower:]' '[:upper:]'
tr -d '\r' < windows.txt > unix.txt
```

## column

```bash
column -t -s '|' report.txt
```

## strings from binaries/JAR streams

```bash
strings binary | grep -i 'search'
unzip -p app.jar | strings | grep -iE 'kex|cipher|config'
```
