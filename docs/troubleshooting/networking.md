# Troubleshooting: Networking, Devices, Virtualisation

Every entry here was hit for real while building the lab. Format: symptom → what to check → where it is explained.

## Reaching the lab

| Symptom | Check / fix | Details |
|---|---|---|
| Ping to Proxmox works, but SSH and the web UI time out | `Find-NetRoute -RemoteIPAddress <proxmox-ip>`: if it says *Wi-Fi*, a more specific `/8` route on the Wi-Fi adapter wins over the default route and the company Wi-Fi blocks TCP 22/8006. Add a persistent route for the Proxmox subnet through the wired gateway | [Proxmox side](../03-proxmox-side.md) |
| Wired adapter has a `169.254.x.x` address, or reports a *Duplicate* address | Set a static address; a duplicate DHCP lease was seen once | |
| The management VM has two NICs and traffic to the bench networks stops | Two default routes; the Internet NIC (metric 25) beat the gateway route (271). Add persistent static routes for `192.168.20.0/24` and `203.0.113.0/24` with a low metric | [SolarWinds install](../06-solarwinds-install.md) |

## Tailscale and routing

| Symptom | Check / fix | Details |
|---|---|---|
| The two gateways cannot see each other | `tailscale status` and `tailscale netcheck` on both; the advertised routes must be **approved** in the admin console; `--accept-routes` must be on (off by default on Linux) | [Laptop side](../04-laptop-side.md) |
| After `tailscale up`, GW-SRV loses its own uplink VLAN and the Internet | Another node advertises the uplink subnet. Add the `routing-policy` rule (priority 2500, table 254, `to: <uplink subnet>`) in a separate netplan file | `configs/gw-srv/61-lab.yaml` |
| The monitored devices see the gateway's address instead of the monitoring server's | `--snat-subnet-routes=false` is missing on a subnet router | |
| Subnet route unreachable | `net.ipv4.ip_forward` must be `1` on both gateways | |

## DHCP relay

| Symptom | Check / fix |
|---|---|
| `dhcrelay` forwards DISCOVER, DC01 answers via `tailscale0`, client never gets an OFFER | ISC relay cannot deliver replies when the upstream interface is a TUN device. Use `dhcp-helper -s <dhcp server> -i <client interface>` |
| `dhcrelay -iu tailscale0` exits with `Unsupported device type 65534` | Same cause, TUN has no Ethernet header |
| `dhcp-helper` logs `bad interface eth0` right after install | Harmless; the default `-b eth0` has no such NIC. Replace the options line |
| Both relays installed | Both want UDP 67; disable the ISC one |
| Client gets DHCP options 051, 015, 006 but no default gateway | Scope option 003 (Router) missing: on the wizard's Router page **Add** must be clicked before **Next** |
| The client VM itself takes the lease that was meant for c5 | The parent NIC (`ens33`) has `dhcp4: true`; the macvlan parent must have no address of its own |

## VLAN and the real devices

| Symptom | Check / fix |
|---|---|
| Ping to `192.168.50.1` from c1 fails 100 %, reply visible without a VLAN tag in a capture | USB adapter driver strips tags: `Set-NetAdapterAdvancedProperty -Name <adapter> -RegistryKeyword "*PriorityVLANTag" -RegistryValue 0` |
| Same test still fails after that | S1 `gi1` must allow VLAN 50; F1's `trust` zone needs `host-inbound-traffic system-services ping`; check with `tshark -i ens33 -Y vlan` |
| Cables correct, GW-BENCH answers ping but S1/F1 do not | VMnet10 is *Host-only*; must be **Bridged** to the USB adapter (not *Automatic*) |
| `gi1` flaps between Down and Up every few seconds, adapter disappears in Windows | Move the adapter to another USB port and keep it there. Root cause unproven |
| VMware asks "New USB Device Detected" again and again | Choose *Connect to the host* and remember the choice; `Restart-Service VMUSBArbService`; re-plug in another port |
| Catalyst console is blank | Press Enter twice (auto speed detection), try 9600 then 115200, or re-plug the console cable |
| Catalyst rejects `cisco`/`cisco` | The previous owner's account is still there: hold **Reset** 15–20 s with all network cables unplugged |
| Catalyst commands with `gi1/0/N` fail | Port names are `gi1`…`gi52` |
| SRX220 still shows the old hostname after Reset Config | Hold the button more than 20 s until the status LED goes red then green, then power-cycle. A short press only loads the rescue config |
| SRX220 `commit check` fails | A root password is required; or an old `ge-0/0/0` stanza was not deleted, or a zone name is wrong |
| `native vlan 20` rejected on the Catalyst | Add VLAN 20 to `allowed vlan` first |

## Proxmox

| Symptom | Check / fix |
|---|---|
| VM NIC on a VLAN-sub-interface bridge gets no DHCP | Do not add a VLAN tag on the VM NIC, Proxmox stacks a second tag (QinQ) and the DHCP server drops the frame |
| `can't clone to non-shared storage` | Clone to shared storage first, then `qm disk move … --delete 1` to local-lvm |
| Interrupted `qm disk move` | Leaves an orphan `vm-NNN-disk-0` and a config still pointing at the old storage. Never `Ctrl+C`; wait for the prompt |
| `qm create --ostype w2k22` fails | Use `win10` for Server 2016/2019/2022 on this Proxmox version |
| Windows login wants Ctrl+Alt+Del but noVNC cannot send it | `qm sendkey <vmid> ctrl-alt-delete` |
| After a snapshot rollback DC01 complains about AD | Check the AD DS events and the VM generation ID; roll back all machines in the set together |
| Windows time jumps hours after a time-zone change | Hardware clock vs time-zone mismatch; set the time from the host, then `w32tm /resync` |
| Windows VMs on VMware are slow | Windows' own hypervisor is on; VMware runs in the slower "Host VBS" mode |
| VMware says *Virtualized Intel VT-x/EPT is not supported* | Only happens with nested virtualisation, which this lab does not use |

## Client simulation (LAB-LNX)

| Symptom | Check / fix |
|---|---|
| All clients vanish after a reboot | Network namespaces are not persistent; run `lab-clients.sh` (or install the unit) |
| A typo creates an interface named `mv` | `mod bridge` instead of `mode bridge`; `ip link del mv` and retype |
| `dhclient` cannot write its PID/lease file | AppArmor; check `dmesg \| grep -i apparmor` and use the `dhclient-*` file names |
| macvlan frames do not leave the VMware NIC | Enable promiscuous mode on the virtual NIC, check VMnet10 is bridged to the right adapter |
