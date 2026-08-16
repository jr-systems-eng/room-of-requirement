# Troubleshoot a TLS Certificate / Chain

## Symptoms

- Browser or client reports an untrusted certificate.
- `PKIX path building failed` or similar trust errors.
- Expired/not-yet-valid certificate.
- Hostname mismatch.
- Server presents the wrong certificate or incomplete chain.

## First checks

```bash
ror diagnose tls host.example.com:443
```

Manual equivalent:

```bash
openssl s_client -connect host.example.com:443 -servername host.example.com -showcerts </dev/null
```

## Inspect the leaf certificate

```bash
openssl s_client -connect host.example.com:443 -servername host.example.com </dev/null 2>/dev/null |
  openssl x509 -noout -subject -issuer -serial -dates -fingerprint -sha256
```

SANs:

```bash
openssl s_client -connect host.example.com:443 -servername host.example.com </dev/null 2>/dev/null |
  openssl x509 -noout -ext subjectAltName
```

## Decision path

### Expired / not yet valid

Compare `notBefore` / `notAfter` with the current system clock. Also verify NTP/time synchronization.

### Hostname mismatch

The requested hostname must appear in the certificate SAN list. CN alone should not be relied on for modern clients.

### Incomplete chain

Inspect every certificate sent by the server:

```bash
openssl s_client -connect host:443 -servername host -showcerts </dev/null
```

A typical server should send the leaf plus required intermediate CA certificates, but not usually the root CA.

### Truststore-specific failure

If OpenSSL/browser verification succeeds but a Java application fails, move to the Java PKIX runbook and inspect the actual JVM truststore used by that process.

## Validate local certificate files

```bash
openssl x509 -in cert.pem -noout -subject -issuer -dates -fingerprint -sha256
openssl verify -CAfile ca-bundle.pem cert.pem
openssl pkey -in privkey.pem -pubout -outform pem | sha256sum
openssl x509 -in cert.pem -pubkey -noout | sha256sum
```

The final two hashes should match when the private key belongs to the certificate.

## Validation

Re-run the exact client/application that originally failed. A successful `openssl s_client` handshake proves TLS connectivity, not necessarily application trust configuration.
