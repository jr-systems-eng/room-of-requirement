# Git

Quick-reference for everyday repository work, branch management, history, recovery, and GitHub-oriented workflows.

## Status and history

```bash
git status -sb
git log --oneline --decorate --graph -20
git show COMMIT
git diff
git diff --staged
```

## Clone / remotes

```bash
git clone URL
git remote -v
git remote get-url origin
git fetch --all --prune
```

## Branches

```bash
git branch
git branch -a
git switch BRANCH
git switch -c new-branch
git branch -d old-branch
git branch -D old-branch       # force; use carefully
```

## Stage and commit

```bash
git add file
git add path/
git add -p                    # Interactive hunks
git restore --staged file
git commit -m 'Message'
```

Avoid `git add -A` when unrelated work exists in the tree.

## Pull / push

```bash
git pull --ff-only
git push
git push -u origin BRANCH
```

## Undo local changes

Discard unstaged changes to one file:

```bash
git restore file
```

Restore from a specific commit:

```bash
git restore --source=COMMIT file
```

Unstage without discarding edits:

```bash
git restore --staged file
```

## Amend latest commit

```bash
git commit --amend
```

Only amend commits that have not been shared unless you understand the history rewrite consequences.

## Revert a committed change safely

```bash
git revert COMMIT
```

This creates a new commit and is normally preferred for shared history.

## Reset

```bash
git reset --soft HEAD~1       # Keep changes staged
git reset HEAD~1              # Keep changes unstaged
git reset --hard HEAD~1       # DESTROYS working-tree changes
```

## Stash

```bash
git stash push -m 'description'
git stash list
git stash show -p stash@{0}
git stash pop
git stash apply stash@{0}
```

## Compare branches / commits

```bash
git diff main..feature
git log main..feature --oneline
git diff COMMIT1 COMMIT2 -- path/to/file
```

## Find who changed a line

```bash
git blame file
git log -p -- file
```

## Search history

```bash
git log -S 'text' --oneline
git log -G 'regex' --oneline
```

## Recover "lost" work

```bash
git reflog
```

Then inspect or restore the desired commit:

```bash
git show SHA
git switch -c recovery SHA
```

## Ignore files

```text
.gitignore       repository rules
.git/info/exclude local-only repo exclusions
```

## Useful config

```bash
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'
git config --global pull.ff only
git config --list --show-origin
```

## Safe routine

```text
1. git status -sb
2. git diff
3. git add specific-files
4. git diff --staged
5. git commit
6. git pull --ff-only (if needed)
7. git push
```
