# SolarWinds IPAM & UDT Lab

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Status](https://img.shields.io/badge/status-ended_2026--10--27-lightgrey)
![SolarWinds](https://img.shields.io/badge/SolarWinds-IPAM_%2B_UDT-F99D1C)
![Proxmox VE](https://img.shields.io/badge/Proxmox_VE-hosts_SolarWinds-E57000?logo=proxmox&logoColor=white)
![Cisco](https://img.shields.io/badge/Cisco-Catalyst_1200-1BA0D7?logo=cisco&logoColor=white)
![Juniper](https://img.shields.io/badge/Juniper-SRX220-84B135?logo=junipernetworks&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-subnet_routers-242424?logo=tailscale&logoColor=white)
![VMware](https://img.shields.io/badge/VMware-Workstation-607078?logo=vmware&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Windows Server](https://img.shields.io/badge/Windows_Server-2022-0078D4)

A test bench for **SolarWinds IP Address Manager (IPAM)** and **User Device Tracker (UDT)**: a SolarWinds server on Proxmox, an Active Directory, two real network devices (a Juniper SRX220 firewall and a Cisco Catalyst 1200 switch) and a laptop full of simulated clients, joined across the Internet by Tailscale. Built during an infrastructure internship at **MobiFone Corporation** (Tổng Công ty Viễn thông MobiFone) by **Huỳnh Ân**, University of Information Technology (UIT).

The question behind it: *can these two products tell an organisation which IP addresses and devices are in use, who is on them, and what happens to that picture behind NAT?* The internship ended half-way through the 30-day trial, so this repo is the write-up of **what was built, what was measured, and what was never tested**, without pretending the second list is shorter than it is.

> 📖 **Best viewed in [Obsidian](https://obsidian.md).** The docs cross-link and render Mermaid diagrams natively there; GitHub shows everything flat, which works but loses some navigation.

## What's actually here

| | |
|---|---|
| **SolarWinds** | Observability Self-Hosted 2026.4 with IPAM and UDT on Windows Server 2022, SQL Server Express, 30-day evaluation (one license for the suite) |
| **Directory** | One Active Directory domain (`lab.local`): AD DS, DNS, DHCP on a second Windows VM |
| **Real devices** | Juniper SRX220H2 (firewall, source NAT with PAT and pool, proxy ARP, SNMP) and Cisco Catalyst C1200-48T-4G (VLANs 20/50, trunks, SNMP) |
| **Simulated clients** | Six clients as Linux network namespaces + macvlan on one VM, one fake "Internet" web server that logs source addresses |
| **Connectivity** | Two Tailscale subnet routers with SNAT off, so the SolarWinds server keeps its real source address; DHCP relay across the tunnel |
| **Tests** | 13 gate tests on the real devices (all pass), 24 core IPAM/UDT tests (7 pass, 5 partial, 12 not run), 96 extended scenarios (not run) |

## Why this exists

Vendor documentation says what a feature *should* do. This repo keeps what it *did*, on a lab where every packet could be checked from the other end. The [findings](docs/09-test-results.md) are the useful part, for example:

- **UDT shows where traffic flows, not where devices exist.** A silent host, or one that only talks to a peer on the same virtual switch, vanishes from the switch's MAC table within about 5 minutes, and from UDT.
- **IPAM's neighbour scanning trusts proxy ARP.** A firewall's NAT-pool addresses showed up as *Used* hosts with a Juniper MAC.
- **A Windows server looks *Available* until ICMP echo is allowed.**
- **IPAM's "Custom" role enforces write access but not visibility.**
- **A USB Ethernet adapter's driver silently strips VLAN tags**, and ISC `dhcrelay` cannot deliver replies over a Tailscale interface.

The [`troubleshooting/`](docs/troubleshooting) folder lists every real failure by topic.

## Repo layout

```
docs/       — design, build steps, configuration, test results (start at 01-architecture-overview.md)
configs/    — device and VM configs: SRX220, Catalyst, netplan, dhcp-helper, client scripts
```

`docs/` explains *why the system looks like this and what it showed*; `configs/` is the files you would copy to rebuild it. IP addresses are lab addresses and RFC 5737 documentation ranges; company networks, accounts and keys are not in this repo.

## Start here

1. [**Architecture overview**](docs/01-architecture-overview.md) — the whole system in one diagram
2. [**Resources and sizing**](docs/02-resources-and-sizing.md) — what it needs and why SolarWinds sits on Proxmox
3. [**Proxmox side**](docs/03-proxmox-side.md) — bridge, gateway VM, domain controller
4. [**Laptop side**](docs/04-laptop-side.md) — virtual networks, GW-BENCH, client simulation, DHCP relay
5. [**Real devices**](docs/05-real-devices.md) — SRX220 and Catalyst setup, cables, gate tests
6. [**SolarWinds install**](docs/06-solarwinds-install.md) — trial, platform, first traps
7. [**IPAM configuration**](docs/07-ipam-configuration.md)
8. [**UDT configuration**](docs/08-udt-configuration.md)
9. [**Test results and findings**](docs/09-test-results.md) — run vs not run, and what was learned
10. [**Project status and hand-over**](docs/10-project-status.md) — open items and what comes next
11. [**Screenshots**](docs/screenshots.md) — the live console, addresses redacted
12. [**Background**](docs/concepts.md) — ICMP, ARP, SNMP, DHCP relay, how IPAM and UDT get their data
13. [**Troubleshooting**](docs/troubleshooting/) — [network and devices](docs/troubleshooting/networking.md), [SolarWinds](docs/troubleshooting/solarwinds.md)

## Status

**Ended 2026-10-27 because the internship did, not because of a blocker.** Infrastructure and gate tests are complete; the core tests are about half done; the extended catalogue was written but never run. The trial license expires on 2026-11-20. Everything left undone is listed in [project status](docs/10-project-status.md), together with the order in which to do it. The lab itself was taken down the same day and will not be restarted, since the real devices were borrowed; the documentation is the record.

This is a personal lab, not a production reference. Shortcuts taken on purpose are marked **⚠️ lab-only** in the relevant doc: an over-privileged service account, a disabled host firewall, SNMP v2c community strings.

## Repo activity

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/4cd263143a75900a2e121e828fefed0aaf087817.svg "Repobeats analytics image")

## License

[MIT](LICENSE) — documentation and code in this repo are free to use, copy, and adapt, with attribution. Provided as-is, no warranty. SolarWinds, Cisco, Juniper, Proxmox and the other product names belong to their owners; this project is not affiliated with or endorsed by them.
