# Git Snippets

## Inspect before changing anything

```bash
git status -sb
git diff
git diff --staged
git log --oneline --decorate -10
```

## Branch workflow

```bash
git switch -c feature/my-change
git add path/to/file
git commit -m "Describe change"
git push -u origin "$(git branch --show-current)"
```

## Sync safely

```bash
git fetch --all --prune
git pull --ff-only
```

## See what changed between refs

```bash
git diff --stat main...HEAD
git diff main...HEAD
git log --oneline main..HEAD
```

## Restore without rewriting history

```bash
# Discard unstaged change to one file
git restore path/to/file

# Unstage while keeping the working-tree change
git restore --staged path/to/file

# Revert a committed change with a new commit
git revert <commit>
```

## Find history for a file

```bash
git log --follow -- path/to/file
git blame path/to/file
```

## Search repository/history

```bash
git grep -n 'search-term'
git log -S'search-term' --oneline --all
git log -G'regex-pattern' --oneline --all
```

## Stash selected work

```bash
git stash push -m 'temporary work' -- path/to/file
git stash list
git stash show -p stash@{0}
git stash pop
```

## Remote / branch facts

```bash
git remote -v
git branch -vv
git rev-parse --show-toplevel
git rev-parse --short HEAD
git branch --show-current
```

## Useful safety habit

Before a pull, rebase, reset, checkout/switch, or bulk stage:

```bash
git status -sb
git diff
git diff --staged
```
