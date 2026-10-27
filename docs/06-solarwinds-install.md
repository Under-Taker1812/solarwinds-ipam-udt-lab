# SolarWinds Install and Trial Activation

Do this **last**: the 30-day trial clock starts when SolarWinds is installed, so every other part of the lab (Proxmox VMs, laptop VMs, real devices) must already pass its tests. Take a snapshot set (`BASE-PRE`) just before, and another (`AFTER-INSTALL`) right after.

Conventions: `[PVE]` Proxmox shell, `[SW-SRV]` PowerShell on SW-SRV, `[Web]` the SolarWinds web console.

## 1. Create SW-SRV (VMID 450)

Same recipe as DC01 ([Proxmox side, section 4](03-proxmox-side.md)): VirtIO SCSI single, write-back, discard, IO thread, VirtIO NIC on `vmbr21`, CPU `host`, two CD drives.

```bash
# [PVE]
qm create 450 --name SW-SRV --memory 16384 --cores 4 --cpu host --ostype win10 \
  --agent enabled=1 --scsihw virtio-scsi-single \
  --scsi0 local-lvm:100,cache=writeback,discard=on,iothread=1 \
  --net0 virtio,bridge=vmbr21,firewall=0 \
  --ide2 local:iso/SERVER_EVAL_x64FRE_en-us.iso,media=cdrom \
  --ide0 local:iso/virtio-win.iso,media=cdrom \
  --boot 'order=ide2;scsi0'
qm start 450
```

Install Windows Server 2022 the same way as DC01 (three VirtIO drivers, then the guest-agent and `virtio-win-gt` installers). **Verify:** Device Manager is clean, `qm agent 450 ping` answers.

### Evaluation → Standard edition (optional)

Convert **before** joining the domain, with your own license key (never write the key to a file or chat):

```powershell
DISM /online /Get-CurrentEdition            # ServerStandardEval
DISM /online /Get-TargetEditions            # must list ServerStandard
DISM /online /Set-Edition:ServerStandard /ProductKey:<your key> /AcceptEula
```

This only converts the edition; it does not activate it. Snapshot the VM (powered off) first.

## 2. Name, address, domain

```powershell
Rename-Computer -NewName SW-SRV -Restart

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.20 -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.10

# since August 2024 -Server must be the fully-qualified DC name
Add-Computer -DomainName lab.local -Server DC01.lab.local -Credential LAB\Administrator -Restart
```

**Verify:** `(Get-CimInstance Win32_ComputerSystem).Domain` → `lab.local`; `Resolve-DnsName sw-srv.lab.local` → `192.168.10.20`.

## 3. Updates, time zone, tools

SolarWinds' installer refuses to complete while Windows is waiting for a reboot, so run Windows Update to "You're up to date" first.

| Step | Detail |
|---|---|
| Temporary Internet | Add a second NIC on the uplink bridge (no VLAN tag if the bridge is already VLAN-bound; see [Proxmox side](03-proxmox-side.md)). Remove it when no longer needed; add it back for the license step |
| **Routing trap** | With that second NIC, the new default route (metric 25) beats the route through GW-SRV (metric 271), and SW-SRV can no longer reach `192.168.20.0/24` or `203.0.113.0/24`. Fix with persistent static routes: `New-NetRoute -DestinationPrefix 192.168.20.0/24 -InterfaceAlias Ethernet -NextHop 192.168.10.1 -RouteMetric 10`, same for `203.0.113.0/24`. Removing the NIC later is harmless |
| Same time zone everywhere | SolarWinds requires all components to share the database server's time zone. `Set-TimeZone -Id "SE Asia Standard Time"` on Windows; `timedatectl set-timezone Asia/Ho_Chi_Minh` on Linux. Compare `(Get-Date).ToUniversalTime()` with `date -u` on the node |
| Installer download | The trial form accepts business/organisation e-mail only (a free webmail address is rejected). Choose the Windows offline installer ("SolarWinds Observability Self-Hosted") |
| Wireshark | Install on SW-SRV for protocol captures |

> **Clock trap.** After changing the time zone, Windows may show a time many hours off. The cause is a mismatch between the VM's hardware clock (local time, set by Proxmox) and the default Pacific time zone Windows was still using, which leaves the UTC clock wrong. Set the clock from the node (`date +%s` → `Set-Date ([DateTimeOffset]::FromUnixTimeSeconds(<n>).LocalDateTime)`), then `klist purge`, `w32tm /resync`, and `nltest /sc_verify:lab.local` must return `NERR_Success`. Kerberos breaks when clocks are minutes apart.

## 4. Install the platform

Note the start time: it is day 0 of the trial.

1. Run the offline installer as Administrator → **Start** → **Standard Platform**.
2. Accept the EULA. The "SaaS supplement / Platform Connect" box is optional; leave it unticked. Version 2026.4 adds an *Admin Contact Email* page, any placeholder works.
3. **Installation Options:** *Install SQL Server Express* (allowed for evaluation only, size-limited). Do not pick *Use SQL Server*.
4. **Installation Report:** warnings do not block, critical errors do. Fix, **Retest**, then **Install**.
5. **Configuration Wizard:** accept defaults for Express; website *All Unassigned*; answer **Yes** when asked to disable the Windows SNMP Trap service in favour of SolarWinds' trap service.
6. Open the web console. In 2026.4 the port is **8787**, not 80. Create the `admin` account on first login.

Result in this lab: 22 SolarWinds services (20 running, two optional ones stopped), SQL Server Express, IIS site `SolarWinds NetPerfMon` on `*:8787`.

> **Firewall trap.** The installer creates the `SolarWinds NetPerfMon` inbound rule for the *Private* profile only. A domain-joined server uses the *Domain* profile, so the console is reachable from SW-SRV itself but not from anywhere else. Add a rule for the Domain profile, TCP 8787, scoped to `192.168.10.0/24`, `192.168.20.0/24` and the Tailscale range `100.64.0.0/10`.

## 5. Check the trial license (test I-00)

2026.4 has **one** evaluation license for the whole suite, there is no per-module trial to switch on.

**[Web] Settings → All Settings → License Manager → My Products.**

| Observed | Value |
|---|---|
| Product | SolarWinds Observability Self-Hosted Premier Enterprise Scale Evaluation |
| License size | Unlimited |
| Expires | 2026-11-20 (30 days after the 2026-10-21 install) |
| Menus added | **My Dashboards → IP Addresses** (IPAM Summary, Manage Subnets & IP Addresses, DHCP & DNS Management, Request IP Address) and **Device Tracker** (Summary, Device Inventory, User Inventory) |

If IPAM or UDT menus are missing: log out and in again; otherwise License Manager → *See all available products* → tick IPAM and UDT → *Try for free* (needs Internet again).

Take the `AFTER-INSTALL` snapshots on all three sides now, IPAM and UDT configuration may need to be redone without reinstalling.

Next: [IPAM configuration](07-ipam-configuration.md).
