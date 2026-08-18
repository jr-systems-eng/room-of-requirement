# Investigate High System Load

## Scope

Use this runbook when Linux load average is unexpectedly high, the host feels slow, jobs queue, or monitoring reports sustained CPU/load pressure.

Linux load average includes tasks running on CPU and tasks waiting in uninterruptible sleep, commonly storage or other kernel waits. High load is therefore not automatically high CPU.

## Safety notes

- Measure before killing processes or restarting services.
- Capture the state while the problem is occurring; transient load is hard to reconstruct later.
- Do not use `kill -9`, clear caches, drop page cache, or reboot as first-line diagnostics.
- Correlate load with CPU, memory, I/O, and process state before choosing a remediation.

## 1. Establish context

```bash
ror doctor
ror diagnose system
```

Then capture:

```bash
uptime
nproc
cat /proc/loadavg
```

Compare load average to the number of CPUs, but treat that only as context—not a hard threshold.

## 2. Check CPU utilization and run queue

```bash
top -b -n1 | head -n 30
```

When available:

```bash
vmstat 1 5
mpstat -P ALL 1 5
```

Look for:

- high user/system CPU;
- a large run queue (`r` in `vmstat`);
- one saturated CPU versus all CPUs;
- high steal time in virtualized/cloud environments;
- high I/O wait as supporting context.

## 3. Identify busy processes/threads

```bash
ps -eo pid,ppid,user,stat,%cpu,%mem,etime,comm,args --sort=-%cpu | head -n 25
```

For a multi-threaded process:

```bash
top -H -p __PID__
```

Confirm whether the activity is expected workload, a runaway process, a maintenance job, compression, backup, Java GC, package work, or another known task.

## 4. Check for blocked tasks and I/O pressure

```bash
ps -eo state,pid,ppid,wchan:32,comm,args | awk '$1 ~ /^D/'
```

If `iostat` is available:

```bash
iostat -xz 1 5
```

Also inspect storage:

```bash
ror diagnose storage
```

A high number of `D` state processes with relatively modest CPU usage points toward blocked I/O or another kernel wait rather than pure CPU saturation.

## 5. Check memory and swap pressure

```bash
free -h
vmstat 1 5
```

Look at `si`/`so` swap activity rather than treating any non-zero swap usage as a problem by itself.

If memory pressure is suspected, follow:

```bash
ror need performance
```

and the memory-pressure runbook.

## 6. Check recent system events

```bash
journalctl -p warning..alert -n 100 --no-pager
journalctl -k -n 100 --no-pager
```

Look for:

- OOM activity;
- storage errors/timeouts;
- filesystem problems;
- service crash/restart loops;
- kernel warnings;
- virtualization/resource contention indicators.

## 7. Correlate with scheduled work

Check timers and cron where relevant:

```bash
systemctl list-timers --all
```

Review application schedulers, backup windows, batch jobs, patching, log rotation, and other known periodic tasks.

## Decision path

- CPU is saturated and one/few processes dominate: investigate those processes/workloads first.
- CPU is saturated across many expected processes: evaluate capacity, concurrency, scheduling, and workload changes.
- CPU is not saturated but many tasks are in `D` state: investigate storage/network filesystem/device waits.
- swap-in/out is sustained and memory is tight: investigate memory pressure.
- steal time is high: investigate hypervisor/cloud contention or CPU allocation.
- load spike aligns with a scheduled job: validate whether the job should be throttled, rescheduled, or optimized.

## Remediation principles

Choose the smallest evidence-backed action:

- stop or throttle a confirmed runaway job;
- adjust application concurrency after understanding workload impact;
- resolve storage/network filesystem latency;
- correct memory pressure rather than masking it with restarts;
- reschedule overlapping maintenance jobs;
- add capacity only after identifying the constrained resource.

## Validation

After remediation, capture the same measurements again:

```bash
uptime
vmstat 1 5
ps -eo pid,user,stat,%cpu,%mem,comm,args --sort=-%cpu | head -n 20
```

Confirm application/service health in addition to improved host metrics.
