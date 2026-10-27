# Screenshots

Captured from the running lab between 2026-10-05 and 2026-10-23: the infrastructure terminals during the build, the SolarWinds consoles on 2026-10-23, the day most of the IPAM and UDT measurements were taken. Not staged, not from a vendor demo. Internal and company addresses, browser bookmarks and the real switch's MAC column are blacked out; everything else is what the console showed. The `192.168.x`, `203.0.113.x` and `198.51.100.x` addresses are the lab's own (the last two are RFC 5737 documentation ranges).

Each image is also embedded in the page where it is explained.

## Infrastructure

**Proxmox side**
![vmbr21 appended to the network config and applied](screenshots/proxmox-vmbr21-created.png)
![GW-SRV: eth0 on the lab bridge, eth1 with a DHCP address blacked out](screenshots/gw-srv-addresses.png)
![DNS Manager on DC01: A records of the static machines, nslookup answers](screenshots/dc01-dns-records.png)
![Creating the svc-solarwinds account](screenshots/dc01-new-service-account.png)

**Laptop side**
![USB adapter bindings: IPv4 off, VMware Bridge Protocol on](screenshots/usb-adapter-bindings.png)
![Virtual Network Editor: VMnet10 bridged to the USB adapter](screenshots/vmware-virtual-network-editor.png)
![GW-BENCH addresses on its three NICs](screenshots/gw-bench-addresses.png)
![c5 gets its address through the DHCP relay and reaches the gateway, DC01 and the fake Internet](screenshots/c5-dhcp-relay-check.png)
![lab-web service active and a request logged](screenshots/lab-web-service.png)
![The six client namespaces](screenshots/lab-clients-namespaces.png)

**Real devices**
![F1 interfaces](screenshots/f1-interfaces.png)
![F1 security zones](screenshots/f1-security-zones.png)
![F1 routes: default via 203.0.113.1, NAT pool addresses as discard routes](screenshots/f1-routes.png)
![S1 interface status: only gi1 and gi2 up](screenshots/s1-interface-status.png)
![F1 NAT session table: c1 to .10, c3 to a pool address](screenshots/f1-nat-sessions.png)

**SolarWinds menus after the trial license**
![IP Addresses menu](screenshots/solarwinds-menu-ip-addresses.png)
![Device Tracker menu](screenshots/solarwinds-menu-device-tracker.png)

## IPAM

**Node discovery: import preview**
![Network Sonar results: GW-SRV, SW-SRV and GW-BENCH with polling method and resources](screenshots/ipam-discovery-import-preview.png)

**Subnet discovery: choosing the routers to read**
![Subnet discovery wizard listing F1, gw-bench, GW-SRV, S1, SW-SRV; gw-bench and GW-SRV ticked](screenshots/ipam-subnet-discovery-nodes.png)

The default-gateway line and SW-SRV's address (company network) are redacted.

**Groups and a subnet after the first scan**
![IPAM tree with Imported Subnet, NOI-BO and PUBLIC groups](screenshots/ipam-groups-public.png)
![Subnet 192.168.10.0/24: GW-SRV, DC01 and SW-SRV Used](screenshots/ipam-subnet-192-168-10.png)

**DHCP and DNS integration**
![DHCP scope OFFICE-20 on DC01 in IPAM](screenshots/dhcp-scope-office-20.png)
![Add DNS server: inherit credentials, 5 zones found](screenshots/ipam-dns-server-credentials.png)

**Write-back: a reservation created from IPAM on the real DHCP server**
![Reservation form with Send Reservation to DHCP Server ticked](screenshots/ipam-dhcp-reservation-form.png)
![DHCP reservation(s) created successfully](screenshots/ipam-dhcp-reservation-created.png)

**Permissions: the ordinary account's view**
![Operator account sees all groups, with write only on NOI-BO](screenshots/ipam-operator-role-view.png)

**Neighbour scanning**
![Edit Subnets dialog with neighbour scanning enabled and Test successful](screenshots/ipam-neighbor-scanning-setting.png)
![203.0.113.11 to .14 marked Used with a Juniper MAC: the NAT pool answered by proxy ARP](screenshots/ipam-neighbor-scan-proxy-arp.png)

The second image is the false-positive finding discussed in [test results](09-test-results.md).

## UDT

**Selecting ports when adding the switch**
![Add UDT Ports for S1: gi1 and gi2 up, the rest down](screenshots/udt-add-ports-s1.png)

**What UDT imported**
![Manage Ports: 62 ports under vendor Cisco, MAC column redacted](screenshots/udt-s1-port-list.png)
![Device Tracker Summary dashboard](screenshots/udt-summary.png)

**Users and endpoints**
![All User Log Ins: user1 and svc-solarwinds](screenshots/udt-user-logins.png)
![Port details for S1 gi1 with the MAC / IP history of each endpoint](screenshots/udt-port-history-gi1.png)
![Endpoint details for c5: connections on gw-bench and on S1, plus IPAM details](screenshots/udt-endpoint-details.png)

**Polling intervals**
![Device Tracker Polling Interval: 30, 30 and 30 minutes](screenshots/udt-polling-interval.png)

## Not yet captured

The docs mark these spots with `[SCREENSHOT NN: ...]`. The lab was taken down and will not be restarted, so they were never taken; each is a console view that is easy to reproduce if the lab is rebuilt.

| # | Where | What it should show |
|---|---|---|
| 01 | [Proxmox side](03-proxmox-side.md) | VMs 450, 451, 452 running on `proxmox-5` in the Proxmox web UI |
| 02 | [Laptop side](04-laptop-side.md) | `tailscale status` on GW-BENCH |
| 03 | [Real devices](05-real-devices.md) | The bench: devices, USB adapter, the two cables |
| 04 | [Real devices](05-real-devices.md) | `snmpwalk` of S1's MAC table (test G-06) |
| 05 | [SolarWinds install](06-solarwinds-install.md) | The installer's Installation Report |
| 06 | [SolarWinds install](06-solarwinds-install.md) | The web console after the first login |
| 07 | [UDT configuration](08-udt-configuration.md) | The Device Inventory list |

