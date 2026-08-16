# Java Keystores and Truststores

Quick-reference for `keytool`, JKS/PKCS12 inspection, certificate import/export, aliases, and Java TLS troubleshooting.

## Locate Java

```bash
java -version
readlink -f "$(command -v java)"
```

Common cacerts path patterns:

```text
$JAVA_HOME/lib/security/cacerts
$JAVA_HOME/jre/lib/security/cacerts
```

Find it:

```bash
find /usr/lib/jvm -path '*/lib/security/cacerts' -o -path '*/jre/lib/security/cacerts'
```

## List a keystore

```bash
keytool -list -v -keystore file.jks
keytool -list -keystore file.jks
```

Specific alias:

```bash
keytool -list -v -keystore file.jks -alias ALIAS
```

Default Java `cacerts` password is commonly `changeit` unless changed locally.

## List cacerts

```bash
keytool -list -cacerts
keytool -list -v -cacerts
```

## Import a trusted certificate

```bash
keytool -importcert \
  -alias my-ca \
  -file certificate.pem \
  -keystore truststore.jks
```

Java cacerts:

```bash
keytool -importcert -trustcacerts \
  -alias my-ca \
  -file certificate.pem \
  -cacerts
```

## Delete an alias

```bash
keytool -delete -alias ALIAS -keystore file.jks
```

## Export a certificate

```bash
keytool -exportcert \
  -alias ALIAS \
  -keystore file.jks \
  -rfc \
  -file exported.pem
```

## Import a PKCS#12 keypair into JKS

```bash
keytool -importkeystore \
  -srckeystore bundle.p12 \
  -srcstoretype PKCS12 \
  -destkeystore destination.jks \
  -deststoretype JKS
```

## Convert JKS -> PKCS12

```bash
keytool -importkeystore \
  -srckeystore source.jks \
  -destkeystore destination.p12 \
  -deststoretype PKCS12
```

## Check aliases only

```bash
keytool -list -keystore file.jks | grep -v '^Keystore'
```

## Certificate fingerprint

From keystore:

```bash
keytool -list -v -keystore file.jks -alias ALIAS | grep -A2 -i fingerprint
```

From PEM:

```bash
openssl x509 -in cert.pem -noout -fingerprint -sha256
```

## Inspect a JAR

```bash
jar tf application.jar | less
unzip -l application.jar
unzip -p application.jar META-INF/MANIFEST.MF
```

Search embedded strings/classes:

```bash
unzip -p application.jar | strings | grep -i 'text'
```

## Find JAR dependencies / manifests

```bash
unzip -p application.jar META-INF/MANIFEST.MF | grep -i Class-Path
```

## Java TLS debug

For an application you control, JVM debug flags can expose trust and handshake behavior:

```bash
-Djavax.net.debug=ssl,handshake,trustmanager
```

Use temporarily: output can be extremely verbose and may expose sensitive connection metadata.

## PKIX failure workflow

If Java reports:

```text
PKIX path building failed
unable to find valid certification path to requested target
```

Check:

```text
1. openssl s_client -connect HOST:PORT -servername HOST -showcerts
2. Is the server presenting the full intermediate chain?
3. Which JVM is the application actually using?
4. Which truststore is it actually using?
5. Does the required CA/intermediate exist under the expected alias?
6. Compare SHA-256 fingerprints.
7. Restart the JVM/app if it only reads the truststore at startup.
```

## Safe keystore replacement pattern

```text
1. Back up the keystore.
2. List and record existing aliases.
3. Export the existing alias if rollback matters.
4. Verify new certificate fingerprint/chain.
5. Delete the old alias only when replacement strategy is confirmed.
6. Import under the expected alias.
7. List alias again and verify fingerprint/dates.
8. Restart/retest the application if required.
```
