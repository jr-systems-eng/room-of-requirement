# Investigate Memory Pressure

## Scope

Use this runbook when a Linux host is low on available memory, swapping heavily, experiencing OOM kills, or an application appears constrained by memory.

Low `free` memory alone is not necessarily a problem because Linux uses RAM for cache. Focus on `MemAvailable`, swap activity, reclaim behavior, OOM evidence, and workload impact.

## Safety notes

- Do not clear caches or drop page cache as a routine fix.
- Do not increase application heap limits until host/container limits and other memory consumers are understood.
- Do not disable swap simply because swap is in use.
- Capture OOM/kernel evidence before restarting the affected process if possible.

## 1. Capture system context

```bash
ror doctor
ror diagnose system
```

Then inspect:

```bash
free -h
grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree|Dirty|Writeback|Slab|SReclaimable|SUnreclaim' /proc/meminfo
```

## 2. Check active memory and swap behavior

```bash
vmstat 1 10
```

Important fields include:

- `si` — swap in;
- `so` — swap out;
- `r` — runnable tasks;
- `b` — blocked tasks.

Historical swap usage with `si/so` near zero may be harmless. Sustained swap-in/out during application slowdown is more meaningful.

## 3. Identify large consumers

```bash
ps -eo pid,ppid,user,%mem,rss,vsz,etime,comm,args --sort=-rss | head -n 30
```

For cgroup/systemd services:

```bash
systemctl status __SERVICE__ --no-pager -l
systemctl show __SERVICE__ -p MemoryCurrent -p MemoryMax -p MemoryHigh 2>/dev/null
```

For containers, inspect the container runtime's memory limits/usage instead of assuming host totals apply directly.

## 4. Check for OOM evidence

```bash
journalctl -k -b --no-pager | grep -iE 'out of memory|oom-kill|killed process'
```

Also:

```bash
dmesg -T 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process'
```

Record the killed PID/process, cgroup, allocation context, and timestamps.

## 5. Check application-specific memory behavior

### Java

```bash
ror diagnose java __PID__
```

If logs show `OutOfMemoryError`, determine whether the issue is Java heap, metaspace, direct/native memory, threads, or host/container memory before changing `-Xmx`.

### Tomcat

```bash
ror diagnose tomcat __SERVICE__
```

Correlate application OOM errors with host/cgroup memory state.

## 6. Check filesystem/cache-related consumers

Large page cache is usually reclaimable. Slab can also matter:

```bash
slabtop -o 2>/dev/null | head -n 30
```

If `SUnreclaim` is unusually large and growing, investigate the kernel/subsystem using it rather than clearing caches blindly.

## 7. Check process count and thread pressure

```bash
ps -e --no-headers | wc -l
ps -eLf --no-headers | wc -l
```

For a suspected process:

```bash
ps -Lf -p __PID__ | wc -l
cat /proc/__PID__/limits | grep -i processes
```

Errors such as `unable to create new native thread` can be related to memory, process/thread limits, or both.

## Decision path

- `MemAvailable` is healthy and swap activity is negligible: memory may not be the primary bottleneck.
- one process dominates RSS and is growing unexpectedly: investigate that workload/process.
- OOM killer evidence names a process/cgroup: inspect its limits and competing consumers around that timestamp.
- sustained `si/so` with poor performance: reduce memory pressure or increase appropriate capacity after identifying consumers.
- Java heap is intentionally capped while host memory remains available: application/JVM sizing may be the constraint.
- container/cgroup limit is reached while host memory is available: adjust the workload limit only after validating expected consumption.

## Remediation principles

Possible evidence-backed actions include:

- fix a memory leak or runaway workload;
- reduce concurrency/batch size;
- right-size JVM/container/service limits;
- stop an unnecessary confirmed consumer gracefully;
- add memory/capacity when normal workload legitimately exceeds available resources;
- reschedule overlapping memory-intensive jobs.

Avoid using restarts as the only fix for a recurring leak without capturing evidence first.

## Validation

Repeat:

```bash
free -h
vmstat 1 10
ps -eo pid,user,%mem,rss,comm,args --sort=-rss | head -n 20
```

Confirm the affected application remains healthy and that OOM/swap symptoms do not immediately recur.
