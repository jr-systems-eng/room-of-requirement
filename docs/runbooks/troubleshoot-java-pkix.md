# Troubleshoot Java PKIX / Truststore Failures

## Symptoms

- `PKIX path building failed`
- `unable to find valid certification path`
- Java application rejects an endpoint that works in a browser or with OpenSSL.

## First principle

Find the **actual JVM and truststore used by the failing process**. Do not assume the system `cacerts` file is the one in use.

## Collect process evidence

```bash
ror diagnose java <pid>
```

Look at the JVM command line for:

```text
-Djavax.net.ssl.trustStore=...
-Djavax.net.ssl.trustStorePassword=...
-Djavax.net.ssl.keyStore=...
```

Do not paste passwords or environment blocks into tickets/chat.

## Confirm the endpoint chain

```bash
ror diagnose tls host.example.com:443
```

If the server is missing intermediates, fix the server chain first when possible.

## Find candidate truststores

```bash
readlink -f /proc/<pid>/exe
java -XshowSettings:properties -version 2>&1 | grep -E 'java.home|java.version'
find "$JAVA_HOME" -name cacerts -type f 2>/dev/null
```

Common locations include:

```text
$JAVA_HOME/lib/security/cacerts
$JAVA_HOME/jre/lib/security/cacerts
```

## Inspect truststore

```bash
keytool -list -keystore /path/to/cacerts
keytool -list -v -keystore /path/to/cacerts -alias <alias>
```

For a certificate file:

```bash
keytool -printcert -file certificate.pem
openssl x509 -in certificate.pem -noout -subject -issuer -dates -fingerprint -sha256
```

## Compare fingerprints

Use SHA-256 fingerprints to prove whether the required CA/intermediate is already present rather than relying only on aliases.

## Import only after verification

Back up the truststore first:

```bash
cp -a /path/to/cacerts /path/to/cacerts.backup-$(date +%Y%m%d-%H%M%S)
```

Then import the verified CA/intermediate:

```bash
keytool -importcert -trustcacerts \
  -alias <descriptive-alias> \
  -file certificate.pem \
  -keystore /path/to/cacerts
```

Prefer adding the appropriate CA/intermediate over blindly importing an endpoint leaf certificate unless there is a deliberate leaf-pinning requirement.

## Validation

1. Re-list the alias/fingerprint.
2. Restart the application only if required for that JVM to reload trust configuration.
3. Re-test the same application path that failed.
4. Preserve the backup until validation is complete.
