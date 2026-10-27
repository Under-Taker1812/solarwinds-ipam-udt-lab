# Troubleshooting: SolarWinds, IPAM, UDT

## Installer and platform

| Symptom | Check / fix |
|---|---|
| Installer will not proceed | Open the *Installation Report*. Critical errors block until fixed and **Retest**; warnings do not |
| Install fails midway or the server reboots | Run Windows Update to completion and reboot **before** installing: the installer cannot finish while a reboot is pending |
| Trial form says *Please provide a valid business e-mail address* | Free webmail is rejected; use an organisation or school address |
| Web console unreachable from other machines | Port is **8787** in 2026.4. The installer's firewall rule is for the Private profile only; add a Domain-profile rule scoped to the lab ranges |
| Console returns HTTP 500 / *SHUTDOWN is in progress*; SQL restarts by itself; ERRORLOG shows "single-user mode" then "script upgrade mode" | Microsoft Update is patching SQL Server (a `SQLServer…KB` installer process). Wait about 25 minutes until SQL is `Running`, then reboot the server. Do not start/stop SQL services by hand mid-patch |
| License Manager shows no IPAM / UDT menus | Log out and in; otherwise *See all available products → Try for free* (needs Internet) |
| Time stamps or Kerberos errors after changing time zone | Hardware clock mismatch; reset the time from the host, `klist purge`, `w32tm /resync`, `nltest /sc_verify:<domain>` must return `NERR_Success` |
| Data stops updating at the end of the trial month | The evaluation expired; polling stops, old data stays |
| `SW-SRV` reports Memory Critical (>90 %) | `SolarWinds.BusinessLayerHost` + SQL Server + IIS use most of 16 GB; close browsers on the server; raise RAM if the host allows |
| *AppInsight for SQL … Unknown state* | Remove the SQL application monitor from **List Resources** |

## Nodes and discovery

| Symptom | Check / fix |
|---|---|
| Sonar imports some devices but leaves others as "Unknown / status only" | Add them with **Add a Single Node** |
| *Discover Now* says it is "not supported for cron scheduled discovery profiles" | Edit the profile and use **Save & Discover Now** |
| After **OK, Add Node** the page does not move | Check **Manage Nodes** in another tab; do not submit twice |
| Juniper node red with *`/dev/md0` mounted on `/junos` Critical* | The device's read-only image volume always reads full; not a connectivity problem |
| Management server cannot reach the bench ranges | Routing problem on the server (two default routes), not a SolarWinds problem |

## IPAM

| Symptom | Check / fix |
|---|---|
| A server that is up shows *Available* | ICMP echo is blocked; enable *File and Printer Sharing (Echo Request – ICMPv4-In)* |
| `203.0.113.11–.14` are *Used* with a firewall vendor MAC | Neighbour scanning reading a proxy-ARP table; the addresses are a NAT pool, not hosts |
| Subnet wizard returns 23 rows incl. company networks | Untick the default gateway, choose only your lab routers, tick only your ranges |
| A subnet is missing from the wizard | Each router returns only the routes in its own table; choose every router that knows the range |
| Bulk "Edit Subnets" rejects the scan interval | The dialog's default (4 minutes) is below the 10-minute minimum |
| Clicking a subnet in the tree and **Edit** opens *Edit IPv4 address* | Select the *group folder*, tick the subnet row in the list, then **Edit** |
| Reservation: *Required fields are missing* | **Set status** has no MAC/name fields. Use **Edit**, status *Reserved*, fill DHCP client name and MAC |
| Reservation exists only in IPAM | You pressed the blue *Create reservation in IPAM only*; use the text button that writes to the DHCP server |
| DNS wizard says *5 zones found*, server has 8 | Not explained |
| An operator can see groups it has no rights to | Role *Custom* restricts write, not visibility. Use *Hide* per group (untested) |

## UDT

| Symptom | Check / fix |
|---|---|
| No UDT data after 15 minutes | Poll the switch yourself: `snmpwalk -v2c -c <community> -On <switch> 1.3.6.1.2.1.17.4.3.1.2` must return MACs |
| Manage Ports shows no ports of the switch | *Show: Nodes → UDT Unmonitored Nodes →* tick the node → **Monitor Node with UDT**, then *UDT Monitored Nodes → Poll now* |
| All 62 ports got imported | Select all → **Unmonitor** (page size 100), then re-**Monitor** only the ones you need |
| A host that is connected is missing from the switch port | Its frames never cross the switch (shares a virtual switch with its peer) or it has been silent longer than the MAC age-out (~5 min). Generate traffic through the switch, then **Poll now** |
| Endpoint page shows `20 (Router)` rather than the port name | Unresolved; the port page shows the real port |
| Hostname column empty | No PTR record for that IP |
| MAC known, IP missing | The ARP table of the router for that subnet was not collected |
| Cannot shut a port from UDT | The node needs read/write SNMP credentials |
| Domain log-ins not shown | Account must be in Event Log Readers on the DC and have WMI access to CIMV2, directory and RSOP; the DC node must have *Poll to monitor Active Directory users* ticked |
| Changed the polling interval but nothing changed | Use *Re-apply default polling interval to existing … polling jobs* |
