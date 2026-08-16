# jq Snippets

## Pretty-print JSON

```bash
jq . file.json
curl -s https://example/api | jq .
```

## Select a field

```bash
jq -r '.name' file.json
jq -r '.items[].name' file.json
```

## Select multiple fields

```bash
jq -r '.items[] | [.name, .status, .id] | @tsv' file.json
```

## Filter objects

```bash
jq '.items[] | select(.status == "failed")' file.json
jq '.items[] | select(.name | test("tomcat"; "i"))' file.json
```

## Sort

```bash
jq '.items | sort_by(.name)' file.json
jq '.items | sort_by(.size) | reverse' file.json
```

## Count

```bash
jq '.items | length' file.json
```

## Default when missing/null

```bash
jq -r '.name // "unknown"' file.json
```

## Build a simpler object

```bash
jq '.items[] | {name, status, address: .network.ip}' file.json
```

## Pass shell value safely

```bash
name='server01'
jq --arg name "$name" '.items[] | select(.name == $name)' file.json
```

## Slurp newline-separated JSON objects into an array

```bash
jq -s '.' objects.jsonl
```
