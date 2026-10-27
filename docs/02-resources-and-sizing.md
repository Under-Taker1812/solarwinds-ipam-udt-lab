# Resources and Sizing

Three questions this page answers: does the laptop have enough RAM, is there room on Proxmox, and how far does the free trial go.

## 1. Where does SolarWinds fit?

| Constraint | Number |
|---|---|
| SolarWinds server minimum (Small tier, up to 500 elements, up to 3 modules) | 4 vCPU · 16 GB RAM · 100 GB SSD |
| All five VMs at documented minimums | about 22.5 GB RAM |
| Laptop | 23.6 GB RAM total, roughly 12 GB left once Windows and the usual desktop apps are running |
| Proxmox node used (`proxmox-5`) | 31.3 GB RAM, 25.1 GB free when measured (2026-10-02); the other four nodes had 3–6 GB free |

**Decision:** SW-SRV, DC01 and GW-SRV go on `proxmox-5`; GW-BENCH and LAB-LNX stay on the laptop. Even a 32 GB laptop would not run all five VMs plus Windows (22.5 + 12 ≈ 34.5 GB).

Hyper-V is not available on Windows 11 Home, but VMware Workstation 17 runs beside the Windows hypervisor in "Host VBS" mode (slower, no nested VT-x). This lab does not need nested virtualisation, so it is fine.

## 2. VM sizing

### Proxmox (`proxmox-5`, local-lvm storage)

| VMID | VM | vCPU | RAM | Disk | Basis |
|---|---|---|---|---|---|
| 450 | SW-SRV | 4 | 16 GB | 100 GB | "Small" tier minimum. Planned 8 vCPU, created with 4 |
| 451 | DC01 | 2 | 2 GB | 40 GB | Windows Server 2022 Desktop Experience minimum |
| 452 | GW-SRV | 2 | 3 GB | 32 GB | Cloned from an Ubuntu cloud-init template |
| | **Total** | 8 | 21 GB | 172 GB | |

Measured on the node with all VMs running (`free -m`, 2026-10-15): 32,003 MB total, **4,009 MB available**, 546 MB swap used. Rule used: keep at least 15 % (≈4.7 GB) available for the cluster's own scheduling headroom, so no additional VMs were added and DC01 stayed at the 2 GB minimum.

> ⚠️ **lab-only:** SW-SRV ran at 92 % RAM in the end (SolarWinds + SQL Express + IIS). Raising it to 20 GB was considered but needs a VM restart and host headroom that was not available.

### Laptop (VMware Workstation 17.6)

| VM | vCPU | RAM | Disk | Notes |
|---|---|---|---|---|
| GW-BENCH | 2 | 2 GB | 10 GB | Raised from the 1.5 GB installer minimum |
| LAB-LNX | 2 | 3 GB | 25 GB | Runs five client network namespaces, nmap, tshark |

Ubuntu Server 24.04 needs ≥1.5 GB RAM and 5 GB disk to install from ISO; after installation these two VMs only run Tailscale, `snmpd`, `dhcp-helper` and small shell scripts.

## 3. License and free trial

| Item | What the documentation says |
|---|---|
| Trial length | 30 days, full-featured, starting when the product is installed without a commercial key |
| After expiry | Polling stops; the console shows stale data only |
| IPAM and UDT together | Both installed under one evaluation license (observed: "Premier Enterprise Scale", unlimited nodes, expiry 2026-11-20) |
| SQL Server Express | Allowed for trials, not for production |
| Windows Server 2022 | 180-day evaluation ISO |
| VMware Workstation Pro | Free for personal use after registration; commercial use needs a license |

Because the 30-day clock starts at install, SolarWinds was installed **last**, after the VMs, the real devices and all connectivity tests had passed ([schedule in the project-status page](10-project-status.md)).

Sources: [Evaluate SolarWinds Platform products](https://documentation.solarwinds.com/en/success_center/orionplatform/content/core-centralized-licensing-evaluation.htm) · [multi-module sizing](https://documentation.solarwinds.com/en/success_center/orionplatform/content/core-multi-module-system-guidelines.htm) · [UDT 2026.1 requirements](https://documentation.solarwinds.com/en/success_center/udt/content/system_requirements/udt_2026-1_system_requirements.htm) · [Windows Server hardware requirements](https://learn.microsoft.com/en-us/windows-server/get-started/hardware-requirements) · [Ubuntu Server requirements](https://ubuntu.com/server/docs/reference/installation/system-requirements/) · [Broadcom, Host VBS limitations](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/17-0/using-vmware-workstation-pro/running-workstation-on-a-hyper-v-enabled-host/limitations-of-host-vbs-mode.html)

## 4. Software list

| Software | Where | Notes |
|---|---|---|
| Windows Server 2022 (evaluation) | SW-SRV, DC01 | VirtIO drivers during setup |
| Ubuntu Server 24.04 | GW-SRV, GW-BENCH, LAB-LNX | |
| Tailscale | GW-SRV, GW-BENCH, laptop | Subnet routers need route approval in the admin console |
| SolarWinds Observability Self-Hosted 2026.4 | SW-SRV | Online or offline installer; needs a SolarWinds ID |
| Wireshark | SW-SRV | Packet capture for protocol checks |
| PuTTY / Tera Term | Laptop | Console to SRX220 and Catalyst |
