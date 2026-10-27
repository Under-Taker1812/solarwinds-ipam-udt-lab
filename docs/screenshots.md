# Screenshots

Captured from the running lab on 2026-10-23, the day most of the IPAM and UDT measurements were taken. Not staged, not from a vendor demo. Internal and company addresses, browser bookmarks and the real switch's MAC column are blacked out; everything else is what the console showed. The `192.168.x`, `203.0.113.x` and `198.51.100.x` addresses are the lab's own (the last two are RFC 5737 documentation ranges).

Each image is also embedded in the page where it is explained.

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
