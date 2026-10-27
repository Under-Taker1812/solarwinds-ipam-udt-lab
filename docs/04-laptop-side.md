# Laptop Side: VMware, GW-BENCH, LAB-LNX, Tailscale

Builds the "remote site" half of the lab: two Ubuntu VMs, three virtual networks, and the tunnel back to the Proxmox side. Do [Proxmox side](03-proxmox-side.md) first (GW-SRV must already run Tailscale).

All files referenced below are in [`configs/`](../configs/).

## 1. Virtual networks (VMware Workstation)

| Network | Type | Attached to | Purpose |
|---|---|---|---|
| **VMnet10** | Bridged to the USB Ethernet adapter | GW-BENCH NIC1, LAB-LNX NIC1 | The only way out to the real devices. VLAN 20 untagged, VLAN 50 tagged inside the client VM |
| **VMnet13** | Host-only; DHCP **off**, host adapter **not** connected | GW-BENCH NIC2, LAB-LNX NIC2 | Fake Internet (`198.51.100.0/24`) |
| **VMnet8** | NAT (default) | GW-BENCH NIC3 (permanent), LAB-LNX NIC3 (temporary, for `apt`) | Real Internet for Tailscale and package installs. Its subnet must not overlap any lab range |

**Prepare the USB adapter on Windows** (PowerShell as administrator; adapter name is `Ethernet 2` here):

```powershell
# no IP stack on the host: the adapter is only a bridge target
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip6
# stop the driver stripping 802.1Q tags (without this, VLAN 50 never reaches the switch)
Set-NetAdapterAdvancedProperty -Name "Ethernet 2" -RegistryKeyword "*PriorityVLANTag" -RegistryValue 0
```

Keep **VMware Bridge Protocol** enabled on the adapter. In the Virtual Network Editor add VMnet10 as Bridged and pick the USB adapter explicitly in **Bridged to**, not *Automatic*, not Wi-Fi.

![USB adapter bindings: IPv4 off, VMware Bridge Protocol on](screenshots/usb-adapter-bindings.png)

![Virtual Network Editor: VMnet10 bridged to the USB adapter](screenshots/vmware-virtual-network-editor.png)

| Trap | Symptom → fix |
|---|---|
| VMware asks "New USB Device Detected" | Choose **Connect to the host** (and remember). Choosing the VM makes Windows lose the adapter, leaving VMnet10 nothing to bridge. If the prompt keeps returning, move the adapter to another USB port or restart `VMUSBArbService` |
| VMnet10 left as Host-only | Cables and devices are right but S1/F1 never answer ping while GW-BENCH does. Set it to **Bridged**, **Bridged to = the USB adapter** |
| Bridging a Wi-Fi adapter | Unsupported for DHCP; use only a wired adapter |
| Host NIC on VMnet13 gets an address | Untick "Connect a host virtual adapter" |

## 2. GW-BENCH

Ubuntu Server 24.04, 2 vCPU, 2 GB, 10 GB. Three NICs in this order: VMnet10, VMnet13, NAT. Names inside Ubuntu are `ens33`, `ens37`, `ens38` (PCI slots 37 and 38, not 34/35), always match NICs by MAC when in doubt.

### 2.1 Addresses

Copy [`configs/gw-bench/60-lab.yaml`](../configs/gw-bench/60-lab.yaml) to `/etc/netplan/60-lab.yaml`, `chmod 600`, then `sudo netplan try` and press Enter before the timer expires.

**Verify:** `ip -br addr` shows two addresses on `ens33` (`192.168.20.1`, `203.0.113.1`), `198.51.100.1` on `ens37`, and a DHCP address on `ens38`.

![GW-BENCH addresses on its three NICs](screenshots/gw-bench-addresses.png)

### 2.2 Forwarding and SNMP

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

sudo apt install -y snmpd
sudo cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak
# agentaddress udp:161 ; comment out the rocommunity lines ; append:
#   rocommunity public default
sudo systemctl restart snmpd
snmpwalk -v2c -c public -On 127.0.0.1 1.3.6.1.2.1.1     # sysName = gw-bench
```

### 2.3 Tailscale subnet router

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up \
  --advertise-routes=192.168.20.0/24,203.0.113.0/24,198.51.100.0/24 \
  --accept-routes --accept-dns=false --snat-subnet-routes=false --hostname=lab-gw-bench
```

Log in with the **same Tailscale account** as GW-SRV, then approve all three routes in the admin console.

[SCREENSHOT 02: `tailscale status` on GW-BENCH listing lab-gw-srv and the laptop as online]

**Verify:**

| Check | Expected |
|---|---|
| `tailscale ping lab-gw-srv` | replies |
| `ip route get 192.168.10.10` | `dev tailscale0 table 52` |
| `ping 192.168.10.10` from GW-BENCH, `ping 192.168.20.1` from DC01 | both answer |
| `ip route show table 52` on GW-SRV | the three bench ranges |

### 2.4 DHCP relay with `dhcp-helper`

DC01 sits on the other side of the tunnel, so VLAN 20 clients need a relay on GW-BENCH.

> **Do not use ISC `dhcrelay` with Tailscale.** `dhcrelay -i ens33` forwards the DISCOVER and DC01 answers back through `tailscale0`, but the relay never writes the reply to `ens33`, the client sees DISCOVERs and no OFFER. Using `-iu tailscale0` exits with `Unsupported device type 65534` because a TUN interface has no Ethernet header.

```bash
sudo systemctl disable --now isc-dhcp-relay.service 2>/dev/null   # both want UDP 67
sudo apt install -y dhcp-helper
sudo cp /etc/default/dhcp-helper /etc/default/dhcp-helper.bak
# set exactly one line, see configs/gw-bench/dhcp-helper:
#   DHCPHELPER_OPTS="-s 192.168.10.10 -i ens33"
sudo systemctl enable --now dhcp-helper.service
sudo ss -ulpn | grep ':67'
```

(A "bad interface eth0" message right after install is normal, the default `-b eth0` has no such NIC.)

**Test with captures** (start both before running `dhclient` in the client VM):

```bash
sudo tcpdump -ni ens33 -e 'udp port 67 or udp port 68'   # client side
sudo tcpdump -ni tailscale0 'udp port 67'                # tunnel side
```

| You see | It means |
|---|---|
| DISCOVER on `ens33`, nothing on `tailscale0` | the relay is not forwarding |
| Request goes up the tunnel, no reply returns | return path is broken (the `dhcrelay` case) |
| Reply on `tailscale0`, no OFFER on `ens33` | relay receives but does not deliver |
| Nothing on `ens33` | VMware's bridge is not passing the macvlan frames |

Finally `Get-DhcpServerv4Lease -ScopeId 192.168.20.0` on DC01 must list the client. On DC01 the *File and Printer Sharing (Echo Request – ICMPv4-In)* firewall rule must be enabled, or the Windows hosts will not answer ping.

![c5 obtains 192.168.20.100 through the relay, then reaches the gateway, DC01 and the fake Internet](screenshots/c5-dhcp-relay-check.png)

## 3. LAB-LNX

Ubuntu Server 24.04, 2 vCPU, 3 GB, 25 GB. Two roles:

- the **fake Internet**: a web server at `198.51.100.100:8080`
- **five clients** (c1–c5, plus c7) built from network namespaces

| NIC | Network | Role |
|---|---|---|
| `ens33` | VMnet10 | no IP of its own; carries the clients through macvlan |
| `ens37` | VMnet13 | `198.51.100.100/24`, default route via GW-BENCH |
| `ens38` | NAT | temporary, removed after tools are installed |

Install tools while the NAT NIC exists: `sudo apt install -y snmp nmap ndiff tshark isc-dhcp-client` (`ndiff` is a separate package on Ubuntu 24.04). Then power off, remove NIC3, and apply [`configs/lab-lnx/60-lab.yaml`](../configs/lab-lnx/60-lab.yaml). From now on reach this VM through the VMware console or an SSH jump via GW-BENCH.

**Verify:** `ip route` has `default via 198.51.100.1 dev ens37`; `ping 198.51.100.1` works; `ping 1.1.1.1` does **not** (by design).

### 3.1 The fake Internet web server

```bash
sudo mkdir -p /srv/lab-web && echo 'internet gia' | sudo tee /srv/lab-web/index.html
# install configs/lab-lnx/lab-web.service to /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now lab-web
curl http://198.51.100.100:8080/        # -> internet gia
journalctl -u lab-web -n 5 --no-pager   # shows the source address of each request
```

The access log is the **ground truth** for NAT tests: it records the address the SRX220 actually presented, which is then compared with what SolarWinds claims to see.

![lab-web service active and a request logged with its source address](screenshots/lab-web-service.png)

### 3.2 The clients

Each "machine" is a network namespace (own IP stack, routes, ARP table) with a macvlan interface on the real NIC.

| Client | Namespace / NIC | Parent | Address | Default route |
|---|---|---|---|---|
| c5 | `c5` / `mv5` | `ens33` (VLAN 20) | DHCP | from DHCP |
| c7 | `c7` / `mv7` | `ens33` (VLAN 20) | `203.0.113.50/24` | none |
| c1 | `c1` / `mv1` | `ens33.50` (VLAN 50) | `192.168.50.11/24` | `192.168.50.1` |
| c2 | `c2` / `mv2` | `ens33.50` | `192.168.50.12/24` | `192.168.50.1` |
| c3 | `c3` / `mv3` | `ens33.50` | `192.168.50.131/24` | `192.168.50.1` |
| c4 | `c4` / `mv4` | `ens33.50` | `192.168.50.132/24` | `192.168.50.1` |

The pattern for one client (c1):

```bash
ip link add link ens33 name ens33.50 type vlan id 50 && ip link set ens33.50 up   # once
ip netns add c1
ip link add mv1 link ens33.50 type macvlan mode bridge
ip link set mv1 netns c1
ip netns exec c1 ip link set mv1 up
ip netns exec c1 ip addr add 192.168.50.11/24 dev mv1
ip netns exec c1 ip route add default via 192.168.50.1
```

`ip` configuration does not survive a reboot. [`lab-clients.sh`](../configs/lab-lnx/lab-clients.sh) rebuilds all six in one go; [`lab-clients.service`](../configs/lab-lnx/lab-clients.service) can run it at boot (written but never installed in this lab). [`lab-dhcp`](../configs/lab-lnx/lab-dhcp) gives each namespace its own `dhclient` PID and lease files, so releasing one client cannot kill another's process.

> Typos that cost time: `mod bridge` instead of `mode bridge` creates an interface named `mv` (remove with `ip link del mv`), and `192.168.5.x` instead of `192.168.50.x`.

**Verify:** `ip -all netns exec ip -br addr` shows the addresses above; `ip netns exec c1 ping -c2 192.168.50.12` works; c5 reports `bound to 192.168.20.1xx`.

![The six namespaces with their addresses, and a ping between two clients](screenshots/lab-clients-namespaces.png)

Next: [Real devices](05-real-devices.md).
