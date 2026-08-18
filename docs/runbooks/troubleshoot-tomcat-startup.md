# Troubleshoot Tomcat Startup

## Scope

Use this runbook when Tomcat will not start, starts and immediately exits, repeatedly restarts, or appears active but the application is not listening or serving correctly.

The goal is to separate service-manager problems, JVM problems, Tomcat configuration problems, application deployment failures, and downstream dependency failures.

## Safety notes

- Inspect logs and effective service configuration before restarting repeatedly.
- Do not delete `work/`, `temp/`, deployed applications, or logs as a first response.
- Do not change Java truststores, heap sizes, ports, permissions, or SELinux policy until evidence points there.
- Preserve the first complete exception/cause chain; later log lines may only show the secondary failure.

## 1. Capture the service and process state

```bash
ror diagnose tomcat tomcat
ror diagnose systemd tomcat
```

If the unit has a different name, substitute it.

Check:

```bash
systemctl status tomcat --no-pager -l
systemctl show tomcat -p LoadState -p ActiveState -p SubState -p MainPID -p ExecMainStatus
systemctl cat tomcat
```

Interpretation:

- `LoadState=not-found`: identify the actual unit or installation method.
- `ActiveState=failed`: inspect `ExecMainStatus` and journal output.
- service active but no Java/Tomcat PID: verify the unit type/PID handling.
- Java PID exists but expected port is absent: focus on Tomcat/application initialization.

## 2. Find the earliest meaningful error

```bash
journalctl -u tomcat -b --no-pager
```

For file-based logs:

```bash
tail -n 200 /var/log/tomcat/catalina.out 2>/dev/null
tail -n 200 /opt/tomcat/logs/catalina.out 2>/dev/null
```

Search for high-signal patterns:

```bash
grep -iE 'SEVERE|Exception|Caused by:|OutOfMemoryError|Address already in use|BindException|PKIX|permission denied|connection refused' /var/log/tomcat/catalina.out 2>/dev/null | tail -n 100
```

When Java prints a long exception chain, work from the first relevant exception and deepest useful `Caused by:` rather than the final shutdown message.

## 3. Confirm the Java runtime actually used

Find the process command line when running:

```bash
pgrep -af 'org\.apache\.catalina|tomcat'
```

Inspect the configured service command:

```bash
systemctl show tomcat -p ExecStart --no-pager
```

Check Java:

```bash
java -version
readlink -f /usr/bin/java
```

If the service explicitly points to another JDK/JRE, inspect that runtime instead of assuming `/usr/bin/java` is authoritative.

## 4. Check for port conflicts

Identify configured/listening ports:

```bash
ss -lntp
```

Common Tomcat ports include 8080, 8443, 8005, and 8009, but the installation may use others.

For a suspected port:

```bash
ss -lntp | grep ':8080 '
```

If logs show `Address already in use` or `BindException`, identify the owning PID before changing Tomcat ports.

## 5. Check filesystem and permissions

```bash
df -hT
df -hi
```

Inspect likely Tomcat paths:

```bash
ls -ld /var/lib/tomcat /var/log/tomcat /etc/tomcat /opt/tomcat 2>/dev/null
```

If the unit declares a service user:

```bash
systemctl show tomcat -p User -p Group --no-pager
```

Validate that account can access the required application/config/log paths. Do not solve a permissions error with broad `chmod 777` changes.

## 6. Check memory/JVM failures

Search for:

```bash
grep -RiE 'OutOfMemoryError|unable to create new native thread|Killed process' /var/log/tomcat /opt/tomcat/logs 2>/dev/null | tail -n 50
journalctl -k -b --no-pager | grep -iE 'oom|out of memory|killed process'
```

If memory pressure is present, follow the memory-pressure runbook before simply increasing `-Xmx`.

## 7. Check TLS/PKIX failures

If startup fails while connecting to LDAP, databases, APIs, or other TLS services and logs contain `PKIX` or certificate-chain errors:

```bash
ror need java
ror need certificate
```

Confirm the actual JVM truststore used by the process before importing certificates.

## 8. Check application deployment failures

Inspect deployed applications and timestamps:

```bash
find /var/lib/tomcat /opt/tomcat -maxdepth 3 -type f \( -name '*.war' -o -name '*.xml' \) -ls 2>/dev/null
```

Correlate the failure with recent deployment/config changes. If one application causes the failure, prefer rolling back that application/config change instead of changing the base Tomcat service.

## 9. Validate configuration changes safely

After a targeted fix:

```bash
sudo systemctl restart tomcat
systemctl status tomcat --no-pager -l
journalctl -u tomcat -n 100 --no-pager
```

Then verify the listener:

```bash
ss -lntp | grep -E ':8080 |:8443 '
```

And validate the application endpoint locally where possible:

```bash
curl -v http://127.0.0.1:8080/
```

Use the real configured port/protocol.

## Validation checklist

- systemd reports the expected active state;
- a Tomcat/Java process remains running;
- the expected listener exists;
- startup logs contain no unresolved fatal exception;
- the local application endpoint responds as expected;
- dependent services used during startup are reachable;
- the original symptom is gone.

## Rollback

Rollback should match the change that introduced or corrected the failure: restore the prior WAR/configuration, JVM options, certificate/truststore backup, service override, or permissions. Re-validate after rollback rather than assuming a successful service start means the application is healthy.
