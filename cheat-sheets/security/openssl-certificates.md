# OpenSSL and Certificates

Quick-reference for TLS diagnostics, certificate inspection, chain verification, PEM conversion, and common Java/Tomcat certificate work.

## Inspect a certificate file

```bash
openssl x509 -in cert.pem -noout -text
openssl x509 -in cert.pem -noout -subject -issuer -serial -dates
openssl x509 -in cert.pem -noout -fingerprint -sha256
```

## Test a remote TLS endpoint

```bash
openssl s_client -connect host.example:443 -servername host.example
```

Show the presented chain:

```bash
openssl s_client -connect host.example:443 -servername host.example -showcerts </dev/null
```

Summary:

```bash
openssl s_client -connect host.example:443 -servername host.example </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -fingerprint -sha256
```

Always use `-servername` for name-based HTTPS/SNI testing.

## Verify a chain

```bash
openssl verify -CAfile ca-chain.pem server.pem
```

With separate intermediate bundle:

```bash
openssl verify -CAfile root.pem -untrusted intermediates.pem server.pem
```

## Extract certs from a server

```bash
openssl s_client -connect host:443 -servername host -showcerts </dev/null 2>/dev/null
```

To split/capture certificates, save the PEM blocks beginning with:

```text
-----BEGIN CERTIFICATE-----
```

## Compare certificate and private key

RSA:

```bash
openssl x509 -noout -modulus -in cert.pem | openssl sha256
openssl rsa  -noout -modulus -in key.pem  | openssl sha256
```

Generic public-key comparison (works beyond RSA):

```bash
openssl x509 -in cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl sha256
openssl pkey -in key.pem -pubout -outform der | openssl sha256
```

Hashes should match.

## Inspect a private key

```bash
openssl pkey -in key.pem -check -noout
```

## CSR

Inspect:

```bash
openssl req -in request.csr -noout -text
```

Create:

```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout key.pem -out request.csr
```

## PKCS#12 / PFX

Inspect:

```bash
openssl pkcs12 -in file.p12 -info -noout
```

Create from PEM material:

```bash
openssl pkcs12 -export \
  -inkey privkey.pem \
  -in cert.pem \
  -certfile chain.pem \
  -name alias \
  -out bundle.p12
```

## DER <-> PEM

```bash
openssl x509 -inform DER -in cert.der -out cert.pem
openssl x509 -outform DER -in cert.pem -out cert.der
```

## Certificate expiration

```bash
openssl x509 -in cert.pem -noout -enddate
openssl x509 -in cert.pem -checkend 2592000 -noout
```

`2592000` = 30 days.

Remote expiration:

```bash
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null \
  | openssl x509 -noout -dates
```

## Common verify errors

```text
unable to get local issuer certificate
    Missing/untrusted intermediate or CA.

self-signed certificate in certificate chain
    Trust path contains an untrusted self-signed cert.

certificate has expired
    Leaf or chain certificate is outside validity period.

hostname mismatch
    Certificate SAN does not match requested hostname.

no peer certificate available
    TLS handshake failed before a server certificate was presented.
```

## Fast TLS troubleshooting flow

```text
1. openssl s_client -connect HOST:PORT -servername HOST -showcerts
2. Check subject/SAN, issuer, validity dates
3. Identify every intermediate in presented chain
4. openssl verify using trusted root + intermediates
5. Compare key and cert public keys if server-side install is suspect
6. Check application truststore separately from OS truststore
```
