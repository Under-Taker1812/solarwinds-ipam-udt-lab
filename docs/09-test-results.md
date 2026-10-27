# Test Results and Findings

An honest account of what was tested, what passed, what was found, and what was **not** run. The internship ended before the planned 30-day trial schedule could be completed.

## 1. Scoreboard

| Group | Tests | Passed | Partial | Not run |
|---|---|---|---|---|
| **G**: real-device gate tests (before SolarWinds) | 13 (G-00…G-12) | **13** | 0 | 0 |
| **I**: IPAM core | 14 (I-00…I-13) | 6 (I-00, 01, 02, 03, 04, 06) | 2 (I-05, I-08) | 6 (I-07, 09–13) |
| **U**: UDT core | 10 (U-01…U-10) | 1 (U-01) | 3 (U-02, 03, 07) | 6 (U-04, 05, 06, 08, 09, 10) |
| **Extended catalogue** (LB, NAT, IP, DH, UD, FW, EX, OP, R) | 96 scenarios | 0 | 0 | 96 (see section 4) |

"Partial" means the main claim was verified but part of the planned observation was not made; each case is listed below.

## 2. What was verified

### Gate tests (G): the path works end to end

All 13 passed on 2026-10-19, Tailscale tunnel (direct, 111 ms), DHCP via relay, SNMP walks of S1's MAC table / the gateway's ARP table / F1's system group, NAT through the firewall with the **web server log as ground truth**:

| Client | Translation seen in F1's session table | Source seen by the fake Internet |
|---|---|---|
| c1, c2 (`192.168.50.0/25`) | → `203.0.113.10` (PAT) | `203.0.113.10` |
| c3, c4 (`192.168.50.128/25`) | → pool `203.0.113.11–.14` | an address from the pool |

Details: [real devices](05-real-devices.md).

### IPAM

| Test | Outcome |
|---|---|
| I-00 trial license | One *Premier Enterprise Scale Evaluation*, unlimited, expires 2026-11-20, shared by IPAM and UDT |
| I-01 scan and status | After enabling ICMP on SW-SRV: the Used/Available picture matched the known truth for both `/24`s |
| I-02 subnet discovery wizard | Returned 23 subnets, mixing the lab with the company and laptop networks; `192.168.10.0/24` arrived only from GW-SRV |
| I-03 how status is determined | c7 (`203.0.113.50`) cannot be pinged from SW-SRV but is in the gateway's ARP table → became *Used* after neighbour scanning was enabled |
| I-04 DHCP server | Scope `OFFICE-20` imported; the lease for c5 appeared with MAC, scope name and client name |
| I-05 DNS server | *5 zones found* (DC01 has 8). PTR records were **not** inspected → partial |
| I-06 write-back | Scope and reservation created from IPAM exist on DC01 |
| I-08 permissions | Write role enforced per group; visibility of groups is not restricted; *Hide* not tried → partial |

### UDT

| Test | Outcome |
|---|---|
| U-01 discovery | S1 is a UDT node; endpoints seen with MAC, IP, port; 62 ports imported |
| U-02 endpoint list | Port page of `gi1` listed GW-BENCH and c1–c4 first; c5, c7 and LAB-LNX only after traffic crossed S1. `gi2` (F1) not examined; default polling = 30/30/30 min → partial |
| U-03 find by MAC | Worked after the fix described below; the endpoint page shows the VLAN interface, not the port name → partial |
| U-07 AD users | `user1` and `svc-solarwinds` appear in *All User Log Ins*. The "which machine" link was not examined → partial |

## 3. Findings

Ordered by how likely they are to bite someone else.

### F1: UDT shows where traffic flows, not where devices are

A switch learns a MAC only from frames arriving on a port, and forgets it after ~5 minutes of silence (SNMP `dot1qTpFdbPort` read to prove it). Endpoints that only talk to something on the same virtual switch never appear on the physical switch, and quiet endpoints age out. Fix used: periodic pings across the switch. See [UDT configuration](08-udt-configuration.md).

### F2: Neighbour scanning trusts proxy-ARP

NAT-pool addresses `.11–.14` answered ARP from the firewall, so IPAM marked them *Used* with a Juniper MAC although no host exists. Check the vendor/MAC column before trusting "Used". See [IPAM configuration](07-ipam-configuration.md).

### F3: Windows hosts look *Available* until ICMP echo is allowed

IPAM's default probe is ping. Enable *Echo Request – ICMPv4-In* on servers you want it to see (or rely on SNMP/WMI polling for those).

### F4: Role "Custom" in IPAM enforces write but not visibility

An operator on one group can still see every other group read-only. Do not rely on it to hide ranges from a user.

### F5: Two default routes break the management plane

Adding a second NIC (Internet) to SW-SRV gave it a default route with a lower metric than the route through the gateway; every probe to the bench networks silently stopped. Persistent static routes with a low metric fixed it. General rule: when a monitoring server gets a second NIC, check `route print` before debugging anything else.

### F6: The USB Ethernet driver strips VLAN tags

`Priority & VLAN` on the adapter made the driver discard 802.1Q tags on the receive path: frames left tagged, replies returned untagged, and the VLAN 50 ping failed 100 %. Setting `*PriorityVLANTag` to `0` fixed it. Relevant to any lab that tunnels VLANs through a USB NIC under Windows.

### F7: ISC `dhcrelay` does not work over a Tailscale TUN interface

The relay forwards requests but never delivers the reply to the client's interface; `-iu tailscale0` is rejected (`Unsupported device type 65534`). `dhcp-helper` works.

### F8: Trial-license and platform quirks

- One evaluation license covers the whole suite; there is no separate per-module trial in 2026.4.
- The web console listens on **8787**; the installer's firewall rule is Private-profile only.
- Windows Update patched SQL Server while SolarWinds was running: the web console returned HTTP 500 / *SHUTDOWN is in progress* for about 25 minutes while SQL restarted in single-user then script-upgrade mode. Wait for the patch to finish and restart the server; do not toggle SQL services by hand.
- The Add Node page does not navigate after submit (check **Manage Nodes** before pressing again).
- UDT imported all 62 switch ports even though two were selected; each monitored port counts toward the license.

### F9: Time zones and RTC

The VMs' virtual hardware clock held local (Vietnam) time while Windows was still on its default Pacific time zone. Changing the zone then made the clock jump by many hours (sometimes into the next day), until the time was reset from the Proxmox node. All components must share the database server's time zone, and Kerberos needs clocks within minutes.

## 4. Not run: the extended catalogue

96 further scenarios were written but **none were executed** (the internship ended). The category list below is what exists; the step-by-step scripts are not part of this repository.

| Group | Count | Topic |
|---|---|---|
| **LB** | 8 | Labelling subnets *Public* / *Private* with custom properties; special-use ranges; automatic labelling by RFC 1918 rule |
| **NAT** | 16 | Many-to-one and pool NAT, destination NAT, double NAT, overlapping private ranges, hairpin, session timeout, tracing "who was address X at 10:15", NetFlow per host, one table of host / private IP / public IP |
| **IP** | 14 | Scope exhaustion alerts, abandoned addresses, hosts that block ping, duplicate addresses, bulk import/export, IPv6, DHCP reservation vs IPAM, scan interval vs staleness |
| **DH** | 10 | One DHCP server for several ranges (relay), DHCP on a firewall, Linux DHCP, mixed BIND/Windows DNS, rogue DHCP server, short leases, bad options, DHCP outage |
| **UD** | 16 | Same MAC on two switches, moving seats, many MACs per port, VLAN visibility, LLDP uplink detection, rogue device alert, SNMPv3, restricting who may poll, port shutdown from UDT, MAC spoofing, cable-pull latency, dual-NIC hosts |
| **FW** | 8 | What a firewall must allow for monitoring, SNMP exposure from outside, ping-only, rule order, firewall outage |
| **EX** | 7 | Exposure review: which public IPs expose which ports (scheduled `nmap` + `ndiff`), default communities, SNMPv2c vs v3 on the wire, packet-level look at ping, proxy ARP, traceroute, reading a router's ARP table remotely |
| **OP** | 11 | Link to the central site down, rotating the monitoring account, snapshot restore, node failure, time zones, license counting, server reboot, clock skew, device-config backup, e-mail alerts, load of a faster scan interval |
| **R** | 6 | Real device vs Linux router/NAT behaviours; second vendor |

The five-machine NAT experiment (what do IPAM and UDT see for a host behind NAT?) was **only partly done**: the translation mechanics were verified (G-09, G-10), the proxy-ARP side effect was found (F2), but the observation table for UDT and IPAM on the translated hosts was never completed.

## 5. Comparison with the original questions

| Question | SolarWinds documentation says | This lab observed |
|---|---|---|
| Which IPs are in use? | ICMP + SNMP + neighbour discovery | Works; ICMP needs Windows allowance; neighbour scanning can over-report (F2, F3) |
| Overlapping subnets | Not documented | Not tested (I-07) |
| Per-group permissions | Roles at subnet and group level | Write enforced; visibility not restricted (F4) |
| Which endpoint is on which port? | UDT via SNMP, ARP, DNS | Works if traffic crosses the switch (F1) |
| Public vs private labelling | Custom properties | Not tested (LB group) |
| Machine behind NAT: private and public IP? | Not documented | Only the translation mechanics verified; correlation table not built |

Next: [Project status](10-project-status.md).
