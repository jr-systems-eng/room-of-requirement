# IPv4 Subnetting Cheat Sheet

Quick reference for CIDR prefixes, subnet masks, usable hosts, block sizes, wildcard masks, and common subnetting calculations.

## CIDR Reference

| CIDR | Subnet Mask | Total IPs | Usable Hosts* | Block / Increment | Wildcard Mask |
|---:|---|---:|---:|---:|---|
| /8 | 255.0.0.0 | 16,777,216 | 16,777,214 | 1 in 1st octet | 0.255.255.255 |
| /9 | 255.128.0.0 | 8,388,608 | 8,388,606 | 128 in 2nd | 0.127.255.255 |
| /10 | 255.192.0.0 | 4,194,304 | 4,194,302 | 64 in 2nd | 0.63.255.255 |
| /11 | 255.224.0.0 | 2,097,152 | 2,097,150 | 32 in 2nd | 0.31.255.255 |
| /12 | 255.240.0.0 | 1,048,576 | 1,048,574 | 16 in 2nd | 0.15.255.255 |
| /13 | 255.248.0.0 | 524,288 | 524,286 | 8 in 2nd | 0.7.255.255 |
| /14 | 255.252.0.0 | 262,144 | 262,142 | 4 in 2nd | 0.3.255.255 |
| /15 | 255.254.0.0 | 131,072 | 131,070 | 2 in 2nd | 0.1.255.255 |
| /16 | 255.255.0.0 | 65,536 | 65,534 | 1 in 2nd | 0.0.255.255 |
| /17 | 255.255.128.0 | 32,768 | 32,766 | 128 in 3rd | 0.0.127.255 |
| /18 | 255.255.192.0 | 16,384 | 16,382 | 64 in 3rd | 0.0.63.255 |
| /19 | 255.255.224.0 | 8,192 | 8,190 | 32 in 3rd | 0.0.31.255 |
| /20 | 255.255.240.0 | 4,096 | 4,094 | 16 in 3rd | 0.0.15.255 |
| /21 | 255.255.248.0 | 2,048 | 2,046 | 8 in 3rd | 0.0.7.255 |
| /22 | 255.255.252.0 | 1,024 | 1,022 | 4 in 3rd | 0.0.3.255 |
| /23 | 255.255.254.0 | 512 | 510 | 2 in 3rd | 0.0.1.255 |
| /24 | 255.255.255.0 | 256 | 254 | 1 in 3rd | 0.0.0.255 |
| /25 | 255.255.255.128 | 128 | 126 | 128 in 4th | 0.0.0.127 |
| /26 | 255.255.255.192 | 64 | 62 | 64 in 4th | 0.0.0.63 |
| /27 | 255.255.255.224 | 32 | 30 | 32 in 4th | 0.0.0.31 |
| /28 | 255.255.255.240 | 16 | 14 | 16 in 4th | 0.0.0.15 |
| /29 | 255.255.255.248 | 8 | 6 | 8 in 4th | 0.0.0.7 |
| /30 | 255.255.255.252 | 4 | 2 | 4 in 4th | 0.0.0.3 |
| /31 | 255.255.255.254 | 2 | 2† | 2 in 4th | 0.0.0.1 |
| /32 | 255.255.255.255 | 1 | 1‡ | Single IP | 0.0.0.0 |

\* Traditional usable-host count subtracts the network and broadcast addresses.  
† `/31` is commonly used for point-to-point links, where both addresses are usable.  
‡ `/32` identifies a single host/address rather than a conventional subnet.

## Last-Octet Pattern Worth Memorizing

| CIDR | Final Mask Octet | Addresses | Traditional Hosts | Increment |
|---:|---:|---:|---:|---:|
| /24 | 0 | 256 | 254 | 256 |
| /25 | 128 | 128 | 126 | 128 |
| /26 | 192 | 64 | 62 | 64 |
| /27 | 224 | 32 | 30 | 32 |
| /28 | 240 | 16 | 14 | 16 |
| /29 | 248 | 8 | 6 | 8 |
| /30 | 252 | 4 | 2 | 4 |
| /31 | 254 | 2 | 2 | 2 |
| /32 | 255 | 1 | 1 | 1 |

Mask progression:

```text
128 -> 192 -> 224 -> 240 -> 248 -> 252 -> 254 -> 255
```

Address/block progression:

```text
128 -> 64 -> 32 -> 16 -> 8 -> 4 -> 2 -> 1
```

## Quick Subnet Calculation

Given an address such as:

```text
192.168.68.57/22
```

A `/22` means:

```text
Subnet mask:   255.255.252.0
Block size:    4 in the third octet
Total IPs:     1,024
Usable hosts:  1,022
```

The third-octet network boundaries increment by four:

```text
192.168.0.0
192.168.4.0
192.168.8.0
...
192.168.64.0
192.168.68.0
192.168.72.0
...
```

Therefore:

```text
Address:       192.168.68.57/22
Network:       192.168.68.0/22
First host:    192.168.68.1
Last host:     192.168.71.254
Broadcast:     192.168.71.255
Subnet mask:   255.255.252.0
Total IPs:     1,024
Usable hosts:  1,022
```

All of these are in the same subnet:

```text
192.168.68.53
192.168.68.57
192.168.69.200
192.168.70.10
192.168.71.254
```

These are not:

```text
192.168.67.254
192.168.72.1
```

## Private IPv4 Ranges

| Private Range | CIDR | Address Range |
|---|---:|---|
| 10/8 | `10.0.0.0/8` | 10.0.0.0 - 10.255.255.255 |
| 172.16/12 | `172.16.0.0/12` | 172.16.0.0 - 172.31.255.255 |
| 192.168/16 | `192.168.0.0/16` | 192.168.0.0 - 192.168.255.255 |

## Other Useful IPv4 Ranges

| Range | Purpose |
|---|---|
| `0.0.0.0/0` | All IPv4 networks / default route |
| `127.0.0.0/8` | Loopback |
| `169.254.0.0/16` | IPv4 link-local / APIPA |
| `224.0.0.0/4` | Multicast |
| `255.255.255.255` | Limited broadcast |

## Useful Formulas

### Number of addresses

```text
2^(32 - CIDR prefix)
```

Example for `/27`:

```text
2^(32 - 27)
= 2^5
= 32 addresses
```

Traditional usable hosts:

```text
32 - 2 = 30 hosts
```

### Block size

Find the first subnet-mask octet that is not `255`:

```text
256 - mask octet = block size
```

Example for `/27`:

```text
255.255.255.224
256 - 224 = 32
```

Subnet boundaries are therefore:

```text
192.168.1.0/27
192.168.1.32/27
192.168.1.64/27
192.168.1.96/27
192.168.1.128/27
192.168.1.160/27
192.168.1.192/27
192.168.1.224/27
```

Example for `/22`:

```text
255.255.252.0
256 - 252 = 4
```

The third octet increments by four:

```text
192.168.64.0/22
192.168.68.0/22
192.168.72.0/22
192.168.76.0/22
```

## Linux Commands

```bash
# Show interfaces, addresses, and CIDR prefixes
ip addr

# Show routing table
ip route

# See how Linux will route to a destination
ip route get 192.168.70.50

# Calculate subnet information
ipcalc 192.168.68.57/22
```

`ipcalc` typically reports the network, mask, broadcast, host range, and host count directly.

## Fast Mental Reference

The sequence most useful to memorize is:

```text
/24 = 254 hosts
/25 = 126 hosts
/26 = 62 hosts
/27 = 30 hosts
/28 = 14 hosts
/29 = 6 hosts
/30 = 2 hosts
```
